-- Appointment-scoped participant links. Does not create video rooms.
begin;
create table if not exists public.telehealth_sessions (
 id uuid primary key default gen_random_uuid(), appointment_id uuid not null unique references public.appointments(id),
 patient_id uuid not null references public.patients(id),
 meeting_url text not null check(meeting_url ~ '^https://'),
 service_name text not null,
 session_status text not null default 'scheduled' check(session_status in ('scheduled','ready','ended')),
 updated_at timestamptz not null default now(), updated_by uuid references auth.users(id)
);
alter table public.telehealth_sessions enable row level security;
create or replace function public.guard_telehealth_session()
returns trigger language plpgsql set search_path=public as $$
begin
 if not exists(select 1 from public.appointments a where a.id=new.appointment_id and a.patient_id=new.patient_id and a.visit_mode='telehealth') then
  raise exception 'Session must match a telehealth appointment and its patient.';
 end if;
 if tg_op='UPDATE' and (new.appointment_id<>old.appointment_id or new.patient_id<>old.patient_id) then
  raise exception 'Session identity cannot be changed.';
 end if;
 new.updated_at=now();new.updated_by=auth.uid();return new;
end; $$;
drop trigger if exists guard_telehealth_session on public.telehealth_sessions;
create trigger guard_telehealth_session before insert or update on public.telehealth_sessions
for each row execute function public.guard_telehealth_session();
drop policy if exists "Staff read telehealth" on public.telehealth_sessions;
create policy "Staff read telehealth" on public.telehealth_sessions for select to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma','front_desk')));
drop policy if exists "Staff create telehealth" on public.telehealth_sessions;
create policy "Staff create telehealth" on public.telehealth_sessions for insert to authenticated
with check(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma','front_desk')));
drop policy if exists "Staff update telehealth" on public.telehealth_sessions;
create policy "Staff update telehealth" on public.telehealth_sessions for update to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma','front_desk')))
with check(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma','front_desk')));
drop policy if exists "Patient read ready telehealth" on public.telehealth_sessions;
create policy "Patient read ready telehealth" on public.telehealth_sessions for select to authenticated
using(patient_id=public.current_patient_id() and session_status='ready' and exists(
 select 1 from public.appointments a where a.id=telehealth_sessions.appointment_id and a.patient_id=public.current_patient_id()
 and a.visit_mode='telehealth' and a.status not in ('cancelled','completed')
));
grant select,insert,update on public.telehealth_sessions to authenticated;
commit;
