-- Run once in your EXISTING project. Adds send-out tracking; no existing rows are removed.
begin;
create table if not exists public.lab_sendouts (
 id uuid primary key default gen_random_uuid(),
 patient_id uuid not null references public.patients(id),
 test_name text not null, lab_name text not null, lab_test_code text,
 ordering_clinician text not null, specimen_type text not null,
 collection_instructions text, billing_method text not null default 'Confirm with lab',
 status text not null default 'ordered' check(status in ('ordered','collected','sent','received','reviewed','cancelled')),
 collected_at timestamptz, sent_at timestamptz, accession_number text,
 results jsonb not null default '[]'::jsonb check(jsonb_typeof(results)='array'),
 review_note text, reviewed_at timestamptz, reviewed_by uuid references auth.users(id),
 released_to_patient boolean not null default false,
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 created_by uuid not null default auth.uid() references auth.users(id),
 updated_by uuid references auth.users(id),
 check(not released_to_patient or (status='reviewed' and reviewed_at is not null and reviewed_by is not null))
);
create index if not exists lab_sendouts_patient_idx on public.lab_sendouts(patient_id,created_at desc);
alter table public.lab_sendouts enable row level security;
create or replace function public.guard_lab_sendout()
returns trigger language plpgsql set search_path=public as $$
begin
 if tg_op='UPDATE' then
  if new.status<>old.status and not (
   (old.status='ordered' and new.status in ('collected','cancelled')) or
   (old.status='collected' and new.status in ('sent','cancelled')) or
   (old.status='sent' and new.status in ('received','cancelled')) or
   (old.status='received' and new.status='reviewed')
  ) then raise exception 'Invalid order status transition.'; end if;
  if new.patient_id<>old.patient_id or new.created_by<>old.created_by then
   raise exception 'Patient identity and order creator cannot be changed.';
  end if;
  if old.released_to_patient and (new.results is distinct from old.results or new.test_name<>old.test_name) then
   raise exception 'Released results are locked. Create a corrected order and result record.';
  end if;
 end if;
 if new.status='reviewed' or new.released_to_patient then
  if not exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider')) then
   raise exception 'Only an authorized clinician or administrator may review or release results.';
  end if;
  if jsonb_array_length(new.results)=0 then raise exception 'Add results before review.'; end if;
  if tg_op='INSERT' or old.status is distinct from 'reviewed' then
   new.reviewed_at=now(); new.reviewed_by=auth.uid();
  end if;
 end if;
 new.updated_at=now(); new.updated_by=auth.uid();
 return new;
end; $$;
drop trigger if exists guard_lab_sendout on public.lab_sendouts;
create trigger guard_lab_sendout before insert or update on public.lab_sendouts
for each row execute function public.guard_lab_sendout();
drop policy if exists "Staff read sendouts" on public.lab_sendouts;
create policy "Staff read sendouts" on public.lab_sendouts for select to authenticated using(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma','front_desk','billing')));
drop policy if exists "Clinical staff create sendouts" on public.lab_sendouts;
create policy "Clinical staff create sendouts" on public.lab_sendouts for insert to authenticated
with check(created_by=auth.uid() and exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma')));
drop policy if exists "Clinical staff update sendouts" on public.lab_sendouts;
create policy "Clinical staff update sendouts" on public.lab_sendouts for update to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma')))
with check(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma')));
drop policy if exists "Patient read released sendouts" on public.lab_sendouts;
create policy "Patient read released sendouts" on public.lab_sendouts for select to authenticated
using(patient_id=public.current_patient_id() and released_to_patient and status='reviewed');
grant select,insert,update on public.lab_sendouts to authenticated;
commit;
