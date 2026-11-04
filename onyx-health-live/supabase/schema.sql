-- ONYX Health v2 foundation. Development/testing only until production HIPAA controls and agreements are in place.
create extension if not exists pgcrypto;

create type public.app_role as enum ('owner','admin','provider','nurse_ma','front_desk','billing','patient');
create table public.profiles (id uuid primary key references auth.users(id) on delete cascade, full_name text, role public.app_role not null default 'patient', created_at timestamptz not null default now());
create table public.patients (id uuid primary key default gen_random_uuid(), mrn text unique default ('ONX-' || upper(substr(replace(gen_random_uuid()::text,'-',''),1,8))), first_name text not null, last_name text not null, dob date, phone text, email text, created_at timestamptz not null default now(), created_by uuid references auth.users(id));
create table public.appointments (id uuid primary key default gen_random_uuid(), patient_id uuid not null references public.patients(id) on delete cascade, provider_id uuid references public.profiles(id), start_at timestamptz not null, duration_minutes int not null default 30 check(duration_minutes between 5 and 480), visit_type text not null default 'Primary Care', location text default 'ONYX Health', status text not null default 'scheduled', reason text, created_at timestamptz not null default now(), created_by uuid references auth.users(id));
create table public.audit_events (id bigint generated always as identity primary key, actor_id uuid references auth.users(id), action text not null, entity_type text not null, entity_id text, created_at timestamptz not null default now());

alter table public.profiles enable row level security; alter table public.patients enable row level security; alter table public.appointments enable row level security; alter table public.audit_events enable row level security;
create or replace function public.staff_role() returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma','front_desk','billing')); $$;
create policy "own profile" on public.profiles for select to authenticated using(id=auth.uid() or public.staff_role());
create policy "staff read patients" on public.patients for select to authenticated using(public.staff_role());
create policy "staff create patients" on public.patients for insert to authenticated with check(public.staff_role());
create policy "staff update patients" on public.patients for update to authenticated using(public.staff_role()) with check(public.staff_role());
create policy "staff read appointments" on public.appointments for select to authenticated using(public.staff_role());
create policy "staff create appointments" on public.appointments for insert to authenticated with check(public.staff_role());
create policy "staff update appointments" on public.appointments for update to authenticated using(public.staff_role()) with check(public.staff_role());
create policy "admins read audit" on public.audit_events for select to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin')));

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,full_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',new.email)); return new; end; $$;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();
