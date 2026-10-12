-- ONYX Health v4 — patient chart additions
create table if not exists public.insurance_policies (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients(id) on delete cascade,
  payer_name text not null,
  plan_name text,
  member_id text not null,
  group_number text,
  subscriber_name text,
  relationship text default 'Self',
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.insurance_policies enable row level security;
drop policy if exists "Staff access insurance" on public.insurance_policies;
create policy "Staff access insurance" on public.insurance_policies
for all to authenticated using (public.is_staff()) with check (public.is_staff());

drop trigger if exists insurance_set_updated_at on public.insurance_policies;
create trigger insurance_set_updated_at before update on public.insurance_policies
for each row execute function public.set_updated_at();

select 'ONYX v4 patient chart migration installed successfully.' as status;
