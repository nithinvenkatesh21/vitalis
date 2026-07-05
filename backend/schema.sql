-- -------------------------------------------------------------
-- VITALIS DATABASE SCHEMA (Milestone 1)
-- -------------------------------------------------------------

-- Enable UUID extension if not enabled
create extension if not exists "uuid-ossp";

-- 1. Create Public Users Table
-- This is linked to the Supabase auth.users table and automatically synchronized
create table public.users (
  id uuid references auth.users on delete cascade primary key,
  display_name text not null,
  demographics jsonb,
  goals_json jsonb,
  family_group_id uuid,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on users
alter table public.users enable row level security;

-- RLS Policies for users
create policy "Allow users to read their own profile" on public.users
  for select using (auth.uid() = id);

create policy "Allow users to update their own profile" on public.users
  for update using (auth.uid() = id);

create policy "Allow users to insert their own profile" on public.users
  for insert with check (auth.uid() = id);


-- 2. Create Mood Entries Table
create table public.mood_entries (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  timestamp timestamp with time zone default timezone('utc'::text, now()) not null,
  valence double precision not null,
  tags_json jsonb default '[]'::jsonb not null,
  free_text text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on mood_entries
alter table public.mood_entries enable row level security;

-- RLS Policies for mood_entries
create policy "Allow users to read their own mood entries" on public.mood_entries
  for select using (auth.uid() = user_id);

create policy "Allow users to insert their own mood entries" on public.mood_entries
  for insert with check (auth.uid() = user_id);

create policy "Allow users to update their own mood entries" on public.mood_entries
  for update using (auth.uid() = user_id);

create policy "Allow users to delete their own mood entries" on public.mood_entries
  for delete using (auth.uid() = user_id);


-- 3. Create Timeline Events Table (Universal spine)
create table public.timeline_events (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  timestamp timestamp with time zone default timezone('utc'::text, now()) not null,
  type text not null,
  payload_json jsonb not null,
  linked_entity_ids uuid[],
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on timeline_events
alter table public.timeline_events enable row level security;

-- RLS Policies for timeline_events
create policy "Allow users to read their own timeline events" on public.timeline_events
  for select using (auth.uid() = user_id);

create policy "Allow users to insert their own timeline events" on public.timeline_events
  for insert with check (auth.uid() = user_id);


-- -------------------------------------------------------------
-- Triggers and Functions
-- -------------------------------------------------------------

-- Trigger function to synchronize public.users with auth.users on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.users (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data->>'display_name',
      new.email,
      'User'
    )
  );
  return new;
end;
$$ language plpgsql security definer;

-- Bind the trigger to auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();


-- -------------------------------------------------------------
-- Atomic Operations (Postgres RPC Functions)
-- -------------------------------------------------------------

-- Atomic RPC function to write MoodEntry and corresponding TimelineEvent together
create or replace function public.log_mood_with_timeline(
  p_valence double precision,
  p_tags_json jsonb,
  p_free_text text,
  p_timestamp timestamp with time zone,
  p_event_type text,
  p_event_payload jsonb
) returns jsonb as $$
declare
  v_user_id uuid;
  v_mood_id uuid;
  v_event_id uuid;
  v_result jsonb;
begin
  -- Get current authenticated user ID
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- 1. Insert mood entry
  insert into public.mood_entries (user_id, timestamp, valence, tags_json, free_text)
  values (v_user_id, p_timestamp, p_valence, p_tags_json, p_free_text)
  returning id into v_mood_id;

  -- 2. Insert corresponding timeline event linked to the mood entry
  insert into public.timeline_events (user_id, timestamp, type, payload_json, linked_entity_ids)
  values (v_user_id, p_timestamp, p_event_type, p_event_payload, array[v_mood_id])
  returning id into v_event_id;

  -- 3. Return JSON containing the generated IDs
  v_result := jsonb_build_object(
    'mood_id', v_mood_id,
    'event_id', v_event_id
  );
  return v_result;
end;
$$ language plpgsql security definer set search_path = public;
