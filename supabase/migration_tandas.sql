-- ==============================================================================
-- FIESTA ALQUIMIA — Migración: nuevas tandas
-- Agrega los estados tanda_3, tanda_4 y tanda_especial.
-- Ejecutar UNA sola vez en Supabase > SQL Editor > New query > Run.
-- Es seguro volver a ejecutarlo.
-- ==============================================================================

-- Elimina cualquier restricción de check existente sobre la columna status
do $$
declare
    r record;
begin
    for r in
        select conname
        from pg_constraint
        where conrelid = 'public.events'::regclass
          and contype = 'c'
          and pg_get_constraintdef(oid) ilike '%status%'
    loop
        execute format('alter table public.events drop constraint %I', r.conname);
    end loop;
end $$;

-- Vuelve a crear la restricción con todas las tandas disponibles
alter table public.events add constraint events_status_check
    check (status in (
        'preparando',
        'tanda_1',
        'tanda_2',
        'tanda_3',
        'tanda_4',
        'tanda_especial',
        'ultima_tanda',
        'agotado'
    ));
