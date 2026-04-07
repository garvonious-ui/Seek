-- Seek Database Schema

-- User profiles (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  email TEXT,
  profile_image_url TEXT,
  is_premium BOOLEAN DEFAULT FALSE,
  premium_expires_at TIMESTAMPTZ,
  onboarding_topics TEXT[],
  streak_count INT DEFAULT 0,
  longest_streak INT DEFAULT 0,
  last_active_date DATE,
  total_verses_explored INT DEFAULT 0,
  total_cards_created INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification settings per user
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_verse_enabled BOOLEAN DEFAULT TRUE,
  daily_verse_time TIME DEFAULT '07:00',
  streak_nudge_enabled BOOLEAN DEFAULT TRUE,
  streak_nudge_time TIME DEFAULT '19:00',
  timezone TEXT DEFAULT 'America/New_York',
  apns_device_token TEXT
);

-- Pool of 365 daily verses
CREATE TABLE daily_verses (
  id SERIAL PRIMARY KEY,
  reference TEXT NOT NULL,
  text TEXT NOT NULL,
  theme TEXT,
  last_used_date DATE
);

-- Rate limit tracking
CREATE TABLE usage_logs (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  log_date DATE NOT NULL DEFAULT CURRENT_DATE,
  chat_count INT DEFAULT 0,
  last_chat_at TIMESTAMPTZ,
  UNIQUE(user_id, log_date)
);

-- Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_verses ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users read own notification settings" ON notification_settings FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own notification settings" ON notification_settings FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users insert own notification settings" ON notification_settings FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users read own usage" ON usage_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Daily verses public read" ON daily_verses FOR SELECT USING (true);

-- Auto-create profile and notification_settings on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, email, display_name)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'full_name', ''));

  INSERT INTO notification_settings (id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();
