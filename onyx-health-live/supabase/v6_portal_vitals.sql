-- Add read access for a patient's vitals ONLY within their own signed encounters.
-- Run once in the existing Supabase project; this does not delete or replace records.
-- Requires the existing v5 patient identity policies/functions.
begin;
alter table public.vitals enable row level security;
drop policy if exists "Patient view own signed visit vitals" on public.vitals;
create policy "Patient view own signed visit vitals" on public.vitals
for select to authenticated using (
  exists (select 1 from public.encounters e
    where e.id = vitals.encounter_id
      and e.patient_id = public.current_patient_id()
      and e.status = 'signed')
);
commit;
