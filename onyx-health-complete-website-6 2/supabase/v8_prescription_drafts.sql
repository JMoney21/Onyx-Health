-- Local prescription preparation only. Does not transmit to pharmacies.
begin;
create table if not exists public.prescription_drafts (
 id uuid primary key default gen_random_uuid(), patient_id uuid not null references public.patients(id),
 medication_name text not null, strength text not null, dosage_form text, dose text not null,
 route text not null, frequency text not null, directions text not null,
 quantity text not null, refills integer not null default 0 check(refills>=0),
 pharmacy_name text not null, pharmacy_address text not null, pharmacy_phone text,
 status text not null default 'draft' check(status in ('draft','reviewed','external_submission_recorded','cancelled')),
 reviewed_by uuid references auth.users(id), reviewed_at timestamptz,
 external_reference text, external_recorded_at timestamptz,
 created_by uuid not null default auth.uid() references auth.users(id),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 check(status not in ('reviewed','external_submission_recorded') or reviewed_by is not null),
 check(status<>'external_submission_recorded' or (external_reference is not null and length(trim(external_reference))>0))
);
alter table public.prescription_drafts enable row level security;
create index if not exists prescription_drafts_patient_idx on public.prescription_drafts(patient_id,created_at desc);
create or replace function public.guard_prescription_draft()
returns trigger language plpgsql set search_path=public as $$
begin
 if tg_op='UPDATE' then
  if new.patient_id<>old.patient_id or new.created_by<>old.created_by then raise exception 'Prescription identity cannot be changed.'; end if;
  if old.status='external_submission_recorded' then raise exception 'Recorded submissions are locked. Create a new draft for changes.'; end if;
  if new.status<>old.status and not (
   (old.status='draft' and new.status in ('reviewed','cancelled')) or
   (old.status='reviewed' and new.status in ('draft','external_submission_recorded','cancelled'))
  ) then raise exception 'Invalid prescription status change.'; end if;
  if old.status='reviewed' and new.status<>'draft' and (
   new.medication_name<>old.medication_name or new.strength<>old.strength or new.dose<>old.dose or
   new.route<>old.route or new.frequency<>old.frequency or new.directions<>old.directions or
   new.quantity<>old.quantity or new.refills<>old.refills or new.pharmacy_name<>old.pharmacy_name or
   new.pharmacy_address<>old.pharmacy_address or new.dosage_form is distinct from old.dosage_form or
   new.pharmacy_phone is distinct from old.pharmacy_phone
  ) then raise exception 'Return to draft before editing a reviewed prescription.'; end if;
 end if;
 if new.status in ('reviewed','external_submission_recorded') then
  if not exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider')) then
   raise exception 'An authorized prescriber account is required for review or submission records.';
  end if;
  if new.status='reviewed' then new.reviewed_by=auth.uid();new.reviewed_at=now(); end if;
  if new.status='external_submission_recorded' then new.external_recorded_at=now(); end if;
 elsif new.status='draft' then new.reviewed_by=null;new.reviewed_at=null;
 end if;
 new.updated_at=now();return new;
end; $$;
drop trigger if exists guard_prescription_draft on public.prescription_drafts;
create trigger guard_prescription_draft before insert or update on public.prescription_drafts
for each row execute function public.guard_prescription_draft();
drop policy if exists "Clinical staff read prescription drafts" on public.prescription_drafts;
create policy "Clinical staff read prescription drafts" on public.prescription_drafts for select to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma')));
drop policy if exists "Clinical staff create prescription drafts" on public.prescription_drafts;
create policy "Clinical staff create prescription drafts" on public.prescription_drafts for insert to authenticated
with check(created_by=auth.uid() and status='draft' and exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma')));
drop policy if exists "Clinical staff update prescription drafts" on public.prescription_drafts;
create policy "Clinical staff update prescription drafts" on public.prescription_drafts for update to authenticated
using(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma')))
with check(exists(select 1 from public.profiles where id=auth.uid() and role in ('owner','admin','provider','nurse_ma')));
grant select,insert,update on public.prescription_drafts to authenticated;
commit;
