-- -------------------------------------------------------------
-- VITALIS DATABASE SCHEMA EXTENSIONS (Milestone 2)
-- -------------------------------------------------------------

-- 1. Create Meals Table
create table public.meals (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  timestamp timestamp with time zone default timezone('utc'::text, now()) not null,
  method text not null, -- 'MANUAL' | 'BARCODE' | 'PHOTO' | 'VOICE'
  macros_json jsonb default '{"calories":0,"carbs":0,"fat":0,"protein":0}'::jsonb not null,
  micros_json jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on meals
alter table public.meals enable row level security;

-- RLS Policies for meals
create policy "Allow users to read their own meals" on public.meals
  for select using (auth.uid() = user_id);

create policy "Allow users to insert their own meals" on public.meals
  for insert with check (auth.uid() = user_id);

create policy "Allow users to update their own meals" on public.meals
  for update using (auth.uid() = user_id);

create policy "Allow users to delete their own meals" on public.meals
  for delete using (auth.uid() = user_id);


-- 2. Create Food Items Table
create table public.food_items (
  id uuid default gen_random_uuid() primary key,
  meal_id uuid references public.meals on delete cascade not null,
  name text not null,
  brand text,
  macros_json jsonb default '{"calories":0,"carbs":0,"fat":0,"protein":0}'::jsonb not null,
  micros_json jsonb default '{}'::jsonb not null,
  confidence_score double precision default 1.0 not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on food_items (Indirect security via meals join is possible, but direct RLS is more robust)
alter table public.food_items enable row level security;

-- RLS Policies for food_items
create policy "Allow users to read food items of their meals" on public.food_items
  for select using (
    exists (
      select 1 from public.meals
      where public.meals.id = public.food_items.meal_id
      and public.meals.user_id = auth.uid()
    )
  );

create policy "Allow users to insert food items to their meals" on public.food_items
  for insert with check (
    exists (
      select 1 from public.meals
      where public.meals.id = public.food_items.meal_id
      and public.meals.user_id = auth.uid()
    )
  );


-- 3. Create Readiness Scores Table
create table public.readiness_scores (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.users on delete cascade not null,
  date date not null,
  composite_score double precision not null,
  components_json jsonb not null, -- e.g., {"hrv": 0.5, "sleep": 0.5}
  explanation_json jsonb default '[]'::jsonb not null, -- array of strings
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_user_date unique (user_id, date)
);

-- Enable RLS on readiness_scores
alter table public.readiness_scores enable row level security;

-- RLS Policies for readiness_scores
create policy "Allow users to read their own readiness scores" on public.readiness_scores
  for select using (auth.uid() = user_id);

create policy "Allow users to insert their own readiness scores" on public.readiness_scores
  for insert with check (auth.uid() = user_id);

create policy "Allow users to update their own readiness scores" on public.readiness_scores
  for update using (auth.uid() = user_id);


-- -------------------------------------------------------------
-- Atomic Operations (Postgres RPC Functions)
-- -------------------------------------------------------------

-- Atomic RPC function to write a Meal, all its FoodItems, and the TimelineEvent together
create or replace function public.log_meal_with_items(
  p_timestamp timestamp with time zone,
  p_method text,
  p_estimated_macros jsonb,
  p_estimated_micros jsonb,
  p_items_json jsonb, -- array of food items: [{"name": "...", "brand": "...", "macros": {...}, "micros": {...}, "confidenceScore": 1.0}]
  p_event_payload jsonb
) returns jsonb as $$
declare
  v_user_id uuid;
  v_meal_id uuid;
  v_item jsonb;
  v_event_id uuid;
  v_result jsonb;
begin
  -- Get current authenticated user ID
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- 1. Insert meal
  insert into public.meals (user_id, timestamp, method, macros_json, micros_json)
  values (v_user_id, p_timestamp, p_method, p_estimated_macros, p_estimated_micros)
  returning id into v_meal_id;

  -- 2. Insert food items associated with the meal
  for v_item in select * from jsonb_array_elements(p_items_json) loop
    insert into public.food_items (meal_id, name, brand, macros_json, micros_json, confidence_score)
    values (
      v_meal_id,
      v_item->>'name',
      v_item->>'brand',
      coalesce(v_item->'macros', '{"calories":0,"carbs":0,"fat":0,"protein":0}'::jsonb),
      coalesce(v_item->'micros', '{}'::jsonb),
      coalesce((v_item->>'confidenceScore')::double precision, 1.0)
    );
  end loop;

  -- 3. Insert corresponding timeline event linked to the meal
  insert into public.timeline_events (user_id, timestamp, type, payload_json, linked_entity_ids)
  values (v_user_id, p_timestamp, 'nutrition_log', p_event_payload, array[v_meal_id])
  returning id into v_event_id;

  -- 4. Return JSON containing the generated IDs
  v_result := jsonb_build_object(
    'meal_id', v_meal_id,
    'event_id', v_event_id
  );
  return v_result;
end;
$$ language plpgsql security definer set search_path = public;


-- Atomic RPC function to write/update ReadinessScore and corresponding TimelineEvent together
create or replace function public.log_readiness_with_timeline(
  p_date date,
  p_composite_score double precision,
  p_components_json jsonb,
  p_explanation_json jsonb,
  p_event_payload jsonb
) returns jsonb as $$
declare
  v_user_id uuid;
  v_readiness_id uuid;
  v_event_id uuid;
  v_result jsonb;
begin
  -- Get current authenticated user ID
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  -- 1. Insert or update readiness score (upsert per day)
  insert into public.readiness_scores (user_id, date, composite_score, components_json, explanation_json)
  values (v_user_id, p_date, p_composite_score, p_components_json, p_explanation_json)
  on conflict (user_id, date) do update set
    composite_score = excluded.composite_score,
    components_json = excluded.components_json,
    explanation_json = excluded.explanation_json
  returning id into v_readiness_id;

  -- 2. Insert corresponding timeline event linked to the readiness score
  insert into public.timeline_events (user_id, timestamp, type, payload_json, linked_entity_ids)
  values (v_user_id, now(), 'readiness_score', p_event_payload, array[v_readiness_id])
  returning id into v_event_id;

  -- 3. Return JSON containing the generated IDs
  v_result := jsonb_build_object(
    'readiness_id', v_readiness_id,
    'event_id', v_event_id
  );
  return v_result;
end;
$$ language plpgsql security definer set search_path = public;

