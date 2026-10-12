-- ONYX Health v5 — patient portal identity + patient-scoped RLS
alter table public.patients add column if not exists user_id uuid unique references auth.users(id) on delete set null;
create index if not exists patients_user_id_idx on public.patients(user_id);

create or replace function public.current_patient_id()
returns uuid language sql stable security definer set search_path=public as $$
 select id from public.patients where user_id=auth.uid() limit 1;
$$;

-- Patient may read only their own patient row.
drop policy if exists "Patient view own chart identity" on public.patients;
create policy "Patient view own chart identity" on public.patients for select to authenticated
using (user_id=auth.uid());

drop policy if exists "Patient view own appointments" on public.appointments;
create policy "Patient view own appointments" on public.appointments for select to authenticated
using (patient_id=public.current_patient_id());

drop policy if exists "Patient view own signed encounters" on public.encounters;
create policy "Patient view own signed encounters" on public.encounters for select to authenticated
using (patient_id=public.current_patient_id() and status='signed');

drop policy if exists "Patient view own medications" on public.medications;
create policy "Patient view own medications" on public.medications for select to authenticated
using (patient_id=public.current_patient_id());

drop policy if exists "Patient request own refills" on public.medication_requests;
create policy "Patient request own refills" on public.medication_requests for insert to authenticated
with check (patient_id=public.current_patient_id());

drop policy if exists "Patient view own refill requests" on public.medication_requests;
create policy "Patient view own refill requests" on public.medication_requests for select to authenticated
using (patient_id=public.current_patient_id());

drop policy if exists "Patient view own lab orders" on public.lab_orders;
create policy "Patient view own lab orders" on public.lab_orders for select to authenticated
using (patient_id=public.current_patient_id());

drop policy if exists "Patient view own lab results" on public.lab_results;
create policy "Patient view own lab results" on public.lab_results for select to authenticated
using (exists(select 1 from public.lab_orders o where o.id=lab_results.lab_order_id and o.patient_id=public.current_patient_id()));

drop policy if exists "Patient view own charges" on public.charges;
create policy "Patient view own charges" on public.charges for select to authenticated
using (patient_id=public.current_patient_id());

drop policy if exists "Patient view own messages" on public.messages;
create policy "Patient view own messages" on public.messages for select to authenticated
using (patient_id=public.current_patient_id());

drop policy if exists "Patient send own messages" on public.messages;
create policy "Patient send own messages" on public.messages for insert to authenticated
with check (patient_id=public.current_patient_id() and sender_user_id=auth.uid());

select 'ONYX v5 patient portal migration installed successfully.' as status;
