-- ONYX v3 safety migration: prevent ordinary changes to signed encounter clinical content.
create or replace function public.protect_signed_encounter()
returns trigger language plpgsql as $$
begin
  if old.status = 'signed' then
    raise exception 'Signed encounters are immutable. Create a controlled amendment instead.';
  end if;
  return new;
end;
$$;
drop trigger if exists protect_signed_encounter_trigger on public.encounters;
create trigger protect_signed_encounter_trigger
before update or delete on public.encounters
for each row execute function public.protect_signed_encounter();
