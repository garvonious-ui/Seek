# Password reset — server done, client outstanding

## The bug

`resetPasswordForEmail()` returns **200 for any email**, by design — GoTrue will
not leak whether an account exists. `AuthManager.resetPassword` treated that 200
as success:

```swift
try await SupabaseService.shared.resetPassword(email: email)
await MainActor.run { resetPasswordSent = true }   // always fires
```

…and `SignInView` then showed *"Reset Email Sent — Check your email for a
password reset link."*

**95 of 157 users have no password** (Apple/Google). For every one of them, no
email is ever sent — but the app says one was. They tap, wait, tap again,
forever. In the app's entire history exactly **one** recovery email has ever
actually been sent.

And for the 62 who *do* have passwords, the flow still can't finish:
`ContentView.onOpenURL` only handles `seek://dailyverse`. There is no
`type=recovery` handling and no set-a-new-password screen. **Password reset has
never worked in Seek.**

---

## Shipped (server, live now)

### `auth-preflight` Edge Function

`POST /functions/v1/auth-preflight` with `{ "email": "..." }`. `verify_jwt` is
off — it is called before the user is authenticated.

| response | meaning | verified live |
|---|---|---|
| `{"status":"oauth_only","provider":"apple","providers":["apple"],"message":"…"}` | account exists, no password | yes |
| `{"status":"no_account","message":"…"}` | no such account | yes |
| `{"status":"sent","message":"…"}` | password account, reset actually sent | not exercised (would email a real user) |
| `{"status":"rate_limited"}` (429) | throttled | yes |
| `{"status":"invalid_email"}` (400) | malformed | yes |
| `{"status":"send_failed"}` (502) / `{"status":"server_error"}` (500) | | — |

Every branch carries a user-presentable `message`, so the client can render it
directly without duplicating the copy.

### Supporting SQL

- `public.auth_preflight_lookup(text)` — SECURITY DEFINER, reads `auth.users`,
  returns `{exists, has_password, providers, email_confirmed}`. Email match is
  case- and whitespace-insensitive (verified).
- `public.auth_preflight_allow(key, limit)` — rolling 15-minute counter.
- `public.auth_preflight_throttle` — RLS on, zero policies.

**EXECUTE is revoked from `anon` and `authenticated` on both functions** —
service-role only, so they are reachable solely through the Edge Function and
never became a public enumeration endpoint. Verified via
`has_function_privilege`.

### Throttling — two tiers, and why

- **Per email: 5 / 15 min.** The meaningful limit; a human resetting their own
  password never needs more.
- **Per IP: 60 / 15 min.** Deliberately loose. Seek is a mobile app, so many
  users share a carrier-grade NAT egress IP; a tight IP limit locks out real
  people. This was not theoretical — the first version used IP-only at 10/15min
  and a single test client presented **three** rotating egress IPs, sailing past
  it while a shared-NAT user would have been blocked.

Emails are SHA-256'd before use as a throttle key, so the table never becomes a
second store of user email addresses.

### Security note, stated plainly

This **is** a user-enumeration endpoint. That is the point: the alternative is
lying to 60% of users. For a devotional app whose sensitive fact is "this person
uses Seek," it's the right trade. Don't copy the pattern where account existence
is itself a secret.

### Adjacent hardening

The security advisor flagged `public.handle_new_user()` as SECURITY DEFINER with
a mutable `search_path` and EXECUTE granted to anon/authenticated. Pinned the
search_path and revoked EXECUTE; body unchanged. Safe because Postgres checks
EXECUTE against the table owner when firing a trigger, not the session role.

---

## Outstanding (client — needs a build)

### 1. Call the pre-flight instead of `resetPasswordForEmail`

`SupabaseService`:

```swift
struct PreflightResult: Decodable {
    let status: String        // oauth_only | no_account | sent | rate_limited | …
    let provider: String?
    let message: String?
}

func preflightReset(email: String) async throws -> PreflightResult {
    try await client.functions.invoke("auth-preflight", options: .init(body: ["email": email]))
}
```

`AuthManager.resetPassword` should branch on `status` and expose it to the view —
`.sent` shows the existing alert, `.oauthOnly` shows the message plus a button
that triggers the matching social sign-in, `.noAccount` offers to switch to sign
up. Render `message` from the response rather than re-writing the copy locally.

### 2. Build the completion flow (this is the part that has never existed)

- Add `seek://password-reset` to the Supabase **Redirect URLs** allowlist
  (Auth → URL Configuration). The function already sends this as `redirectTo`,
  overridable via the `PASSWORD_RESET_REDIRECT` env var.
- Extend `ContentView.onOpenURL` — it currently matches only
  `host == "dailyverse"`. Add the recovery branch, and keep the existing
  early-out so Supabase OAuth callbacks stay untouched.
- On a recovery URL: `client.auth.session(from: url)` to exchange the token,
  then present a new-password screen calling
  `client.auth.update(user: UserAttributes(password: newPassword))`.

### 3. Tell your mom to tap "Continue with Apple"

`cesario.teresa@me.com`, Apple-only, `last_sign_in_at` still 2026-04-09 — locked
out since the day she signed up. The pre-flight now says this out loud, but only
once the client ships.
