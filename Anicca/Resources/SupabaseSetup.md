# Anicca — Supabase + RevenueCat Setup

## Supabase

1. Create a new Supabase project at https://app.supabase.com.
2. Copy your project URL and `anon` (public) key into `Secrets.xcconfig` at the project root.
3. Open the Supabase **SQL editor** and run the SQL below in order. It creates the schema and enables Row Level Security.

### Schema SQL

```sql
-- profiles table (extends auth.users)
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  display_name text,
  plan_tier text not null default 'free',
  check_in_streak integer not null default 0,
  last_check_in_date timestamptz,
  total_check_ins integer not null default 0,
  reminder_enabled boolean not null default false,
  reminder_time timestamptz,
  yggdrasil_user_id text,          -- reserved for future deep integration
  created_at timestamptz default now()
);

-- check_ins table
create table check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null,
  note text,
  created_at timestamptz default now()
);

-- emotion_entries table
create table emotion_entries (
  id uuid primary key default gen_random_uuid(),
  check_in_id uuid references check_ins(id) on delete cascade not null,
  user_id uuid references profiles(id) on delete cascade not null,
  emotion_name text not null,
  energy_center text not null,
  intensity integer not null check (intensity >= 1 and intensity <= 5),
  created_at timestamptz default now()
);

-- ai_insights table (caches AI responses per user per week)
create table ai_insights (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade not null,
  week_start date not null,
  insight_text text not null,
  dominant_center text,
  suggested_practices text[],
  created_at timestamptz default now(),
  unique(user_id, week_start)
);

-- Enable RLS on all tables
alter table profiles enable row level security;
alter table check_ins enable row level security;
alter table emotion_entries enable row level security;
alter table ai_insights enable row level security;

-- RLS Policies (users can only access their own data)
create policy "Users can manage own profile" on profiles for all using (auth.uid() = id);
create policy "Users can manage own check-ins" on check_ins for all using (auth.uid() = user_id);
create policy "Users can manage own entries" on emotion_entries for all using (auth.uid() = user_id);
create policy "Users can manage own insights" on ai_insights for all using (auth.uid() = user_id);
```

### Auth providers

1. **Email**: enable in Supabase Auth → Providers → Email. Configure your password reset redirect URL.
2. **Apple**: enable Apple provider. Add your bundle ID (`com.screensagestudios.anicca`) to the Apple provider configuration.
3. **Google**: enable Google provider. Add your OAuth 2.0 Client ID. Put the iOS client ID in `Secrets.xcconfig` as `GOOGLE_CLIENT_ID` and the reversed client ID as `GOOGLE_URL_SCHEME`.

## RevenueCat

1. Create a RevenueCat account at https://app.revenuecat.com and add a new app for your bundle ID `com.screensagestudios.anicca`.
2. Set your **public iOS API key** in `Secrets.xcconfig` as `REVENUECAT_API_KEY`.

### Entitlements

Create two entitlements in the dashboard:

| Entitlement ID | Notes |
|---|---|
| `pro` | Unlocks Pro features |
| `bundle` | Unlocks Pro + Bundle features (Yggdrasil deep integration) |

### Products (App Store Connect)

Create the four auto-renewing subscriptions in App Store Connect, then attach each to RevenueCat:

| Product ID | Price | Entitlement |
|---|---|---|
| `anicca_pro_monthly` | $4.99 / month | `pro` |
| `anicca_pro_annual` | $39.99 / year | `pro` |
| `anicca_bundle_monthly` | $8.99 / month | `bundle` |
| `anicca_bundle_annual` | $69.99 / year | `bundle` |

### Offering

Create a RevenueCat offering called `default` and attach all four packages. The Paywall uses these IDs directly — keep them stable.

## Gemini

1. Get a Gemini API key from https://aistudio.google.com.
2. Set it in `Secrets.xcconfig` as `GEMINI_API_KEY`.
