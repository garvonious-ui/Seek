# Donations — compliance decision (iOS + Android)

**Status:** donations are currently **hidden on both platforms** (dormant code only). This doc lays out the paths to safely re-enable them and what each unlocks. Written 2026-06-15.

> ⚠️ **Hard constraint:** do **not** re-enable any donation surface in a build that is in App/Play review. Adding a payment surface forces a pull + resubmit and resets the review queue. Whatever we choose ships as a **post-approval update** (same plan as wiring Google Sign-In after the Android launch).

---

## Why donations are hidden today

- **iOS Build 7 was rejected** (Guideline 3.1.1): a for-profit app cannot link out to Stripe for "support the developer" donations — Apple wanted In-App Purchase or removal. We removed all surfaces (Session 16).
- The same logic applies on Google Play (see below). Seek is operated by **LCIII Ventures LLC — a for-profit entity**, and that is the root of the problem on *both* stores.

## The core rule (the same on both stores)

Both stores exempt **only tax-exempt (registered-nonprofit / 501(c)(3)) donations** from their billing requirement.

- **Google Play Payments policy, Section 3** — exempt transactions include *"peer-to-peer payments, online auctions, and **tax exempt donations**."* A for-profit "support us" donation is **not** tax-exempt → not exempt → expected to use Play Billing (which barely supports donations).
- **Apple Guideline 3.2.1 / 3.1.1** — registered nonprofits may collect donations outside IAP; for-profit "tip jar" donations must use IAP.

**Conclusion:** as a for-profit, the simple Stripe-link donation carries the same rejection risk on Android as it did on iOS. The *escape hatches* differ — that's where the platforms diverge.

---

## Option A — Register as a 501(c)(3) nonprofit

Convert the operating entity (or stand up a nonprofit) so donations become genuinely **tax-exempt**.

| | Detail |
|---|---|
| **Works on** | Both stores, **all regions** |
| **Rejection risk** | **None** — tax-exempt donations are flatly allowed by Apple *and* Google |
| **Store cut** | $0 — donations don't run through IAP/Play Billing at all; Stripe fee only (~2.9% + 30¢) |
| **What's needed** | Nonprofit formation + IRS 501(c)(3) determination; Apple wants nonprofit verified (Apple's nonprofit program); Google wants nonprofit status documented |
| **Effort** | One-time legal/tax filing; weeks-to-months for IRS determination |
| **Reach** | Global, both stores, no per-store program enrollment |
| **Reuses our existing Stripe + webhook + `donations` table** | Yes, unchanged |

**Fit:** aligns with the stated ethos ("built for the people of God, not for profit"). Session 16 already flagged this as the intended reversible path. **This is a tax/legal decision — confirm with an accountant/attorney before filing.**

## Option B — Stay for-profit, use external-payment-link programs

Link users out to the existing Stripe page under each store's antitrust-driven external-links program.

### Google Play (US)
| | Detail |
|---|---|
| **Works on** | Android, **US users only** (the Epic v. Google injunction is US-scoped; EU = separate DMA path; rest of world = still the old rule, no link-out) |
| **Rejection risk** | Low if done by the book; some reviewer subjectivity remains |
| **Google fee** | **$0** on external link-outs during the current injunction terms (Oct 29 2025 →) |
| **What's needed** | Enroll in the **External Content Links Program**; follow disclosure rules; donation must unlock **nothing** (any benefit → reclassified as a digital purchase requiring Play Billing) |
| **Deadline** | Program compliance framework effective **Jan 28, 2026** |

### Apple (US)
| | Detail |
|---|---|
| **Works on** | iOS, **US users only** (External Purchase Link Entitlement, post Epic v. Apple) |
| **Apple commission** | Apple charges a **commission on external-link purchases** (historically ~27%, ~12% small-business) — punitive for donations |
| **What's needed** | Apply for the External Purchase Link Entitlement; mandatory scare-screen disclosure before the link |

**Fit:** keeps for-profit status but is **US-only on each store**, requires per-store enrollment + disclosures, and Apple's commission makes its external-link path nearly pointless for donations. More moving parts, narrower reach, ongoing compliance burden.

---

## Side-by-side

| | A — 501(c)(3) nonprofit | B — External-link programs |
|---|---|---|
| Reach | Global, both stores | **US only**, per store |
| Apple | Allowed, no cut | Allowed, **~27% Apple cut** + scare screen |
| Google | Allowed, no cut | Allowed (US), no Google fee, must enroll |
| Rejection risk | None | Low–moderate (subjective) |
| Per-transaction cost | Stripe fee only | Stripe fee (Google US); Stripe + Apple cut (iOS) |
| Setup | Legal/tax filing (one-time) | Per-store program enrollment + disclosures (ongoing) |
| Ethos fit | Strong | Neutral |

## What we already have (reusable under either option)

- **Stripe Payment Links** — 6 fixed amounts ($10/$25/$50/$100/$250/$500) + a $1 adjustable link, live under LCIII Ventures LLC
- **`stripe-webhook` Edge Function** — HMAC-verified, idempotent, writes to the `donations` table; optional Resend thank-you email
- **`donations` table** — RLS-locked, service-role only
- **iOS `DonationView.swift`** — dormant, editorial layout, `openURL` to Stripe
- **Android** — *no* donation UI built yet; would need a Compose `DonationScreen` mirroring iOS

## Recommendation

**Pursue Option A (501(c)(3)).** It's the only path that is risk-free, works on both stores in every region, takes no per-store store cut, and matches the app's stated mission. Option B is a US-only, higher-maintenance workaround that Apple's commission makes lopsided.

## Next steps (in order)

1. **Let the current builds finish review untouched** (iOS 1.1.0 build 11; Android 1.0.0 code 3).
2. **Decide A vs. B** — if A, talk to an accountant/attorney about nonprofit formation + 501(c)(3).
3. Once status is settled, **re-enable the dormant donation surfaces** in a post-approval update:
   - iOS: un-hide `DonationView` (Profile entry point) — code is intact.
   - Android: build the Compose `DonationScreen` to match.
4. Update Privacy / Terms / Support pages to re-add the donation + Stripe disclosure (they were scrubbed in Session 16).
