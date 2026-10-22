-- ==============================================================================
-- FIESTA ALQUIMIA — Supabase Schema & Security Setup
-- Idempotente: se puede correr varias veces sin romper datos existentes.
-- ==============================================================================

-- 1. EXTENSIONES
create extension if not exists "pgcrypto";

-- 2. TABLA: site_settings (configuración general, fila única id=1)
create table if not exists public.site_settings (
    id integer primary key default 1 check (id = 1),
    site_title text not null default 'Fiesta Alquimia',
    tagline text not null default 'Vivamos el momento, disfrutemos cada encuentro ;)',
    instagram_url text not null default 'https://www.instagram.com/fiestaalquimia/',
    logo_url text null,
    background_url text null,
    og_image_url text null,
    updated_at timestamptz not null default now()
);

-- Asegurar fila por defecto
insert into public.site_settings (id, site_title, tagline, instagram_url)
values (1, 'Fiesta Alquimia', 'Vivamos el momento, disfrutemos cada encuentro ;)', 'https://www.instagram.com/fiestaalquimia/')
on conflict (id) do nothing;

-- 3. TABLA: events (jodas)
create table if not exists public.events (
    id uuid primary key default gen_random_uuid(),
    title text not null,
    group_name text null,
    event_date timestamptz not null,
    destination text null check (char_length(destination) <= 16),
    venue text null,
    lineup text null,
    description text null check (char_length(description) <= 280),
    flyer_url text null,
    ticket_url text null,
    ticket_button_label text not null default 'Conseguir entradas',
    status text not null default 'preparando' check (status in ('preparando', 'tanda_1', 'tanda_2', 'ultima_tanda', 'agotado')),
    drive_url text null,
    published boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Índice por fecha del evento para ordenar rápido
create index if not exists idx_events_event_date on public.events (event_date);
create index if not exists idx_events_published on public.events (published);

-- 4. FUNCIÓN Y TRIGGERS PARA UPDATED_AT
create or replace function public.handle_updated_at()
returns trigger
language plpgsql
security definer
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists set_updated_at_site_settings on public.site_settings;
create trigger set_updated_at_site_settings
    before update on public.site_settings
    for each row
    execute function public.handle_updated_at();

drop trigger if exists set_updated_at_events on public.events;
create trigger set_updated_at_events
    before update on public.events
    for each row
    execute function public.handle_updated_at();

-- 5. ROW LEVEL SECURITY (RLS)
alter table public.site_settings enable row level security;
alter table public.events enable row level security;

-- Policies para site_settings
drop policy if exists "Lectura pública de site_settings" on public.site_settings;
create policy "Lectura pública de site_settings"
    on public.site_settings
    for select
    using (true);

drop policy if exists "Admins pueden actualizar site_settings" on public.site_settings;
create policy "Admins pueden actualizar site_settings"
    on public.site_settings
    for update
    to authenticated
    using (true)
    with check (true);

-- Policies para events
drop policy if exists "Lectura pública de eventos publicados" on public.events;
create policy "Lectura pública de eventos publicados"
    on public.events
    for select
    to anon, authenticated
    using (published = true);

drop policy if exists "Admins pueden ver todos los eventos" on public.events;
create policy "Admins pueden ver todos los eventos"
    on public.events
    for select
    to authenticated
    using (true);

drop policy if exists "Admins pueden crear eventos" on public.events;
create policy "Admins pueden crear eventos"
    on public.events
    for insert
    to authenticated
    with check (true);

drop policy if exists "Admins pueden editar eventos" on public.events;
create policy "Admins pueden editar eventos"
    on public.events
    for update
    to authenticated
    using (true)
    with check (true);

drop policy if exists "Admins pueden borrar eventos" on public.events;
create policy "Admins pueden borrar eventos"
    on public.events
    for delete
    to authenticated
    using (true);

-- 6. STORAGE BUCKET: alquimia-media
-- Crear el bucket si no existe
insert into storage.buckets (id, name, public)
values ('alquimia-media', 'alquimia-media', true)
on conflict (id) do update set public = true;

-- Policies para storage.objects
drop policy if exists "Lectura pública de alquimia-media" on storage.objects;
create policy "Lectura pública de alquimia-media"
    on storage.objects
    for select
    using (bucket_id = 'alquimia-media');

drop policy if exists "Admins pueden subir archivos a alquimia-media" on storage.objects;
create policy "Admins pueden subir archivos a alquimia-media"
    on storage.objects
    for insert
    to authenticated
    with check (bucket_id = 'alquimia-media');

drop policy if exists "Admins pueden modificar archivos de alquimia-media" on storage.objects;
create policy "Admins pueden modificar archivos de alquimia-media"
    on storage.objects
    for update
    to authenticated
    using (bucket_id = 'alquimia-media')
    with check (bucket_id = 'alquimia-media');

drop policy if exists "Admins pueden borrar archivos de alquimia-media" on storage.objects;
create policy "Admins pueden borrar archivos de alquimia-media"
    on storage.objects
    for delete
    to authenticated
    using (bucket_id = 'alquimia-media');

-- ==============================================================================
-- 7. DATOS DE PRUEBA (OPCIONALES — descomentar para poblar)
-- ==============================================================================
/*
insert into public.events (
    title,
    group_name,
    event_date,
    destination,
    venue,
    lineup,
    description,
    ticket_url,
    ticket_button_label,
    status,
    published
) values
(
    'Alquimia Pinto',
    'GIRA DE VERANO',
    now() + interval '5 days',
    'GENERAL PINTO',
    'Club Social Pinto',
    'DJ Residente\nDJ Invitado B2B',
    'La primera parada de la gira. Traé a tu grupo.',
    'https://instagram.com/fiestaalquimia',
    'Conseguir entradas',
    'tanda_1',
    true
),
(
    'Alquimia Germania',
    'GIRA DE VERANO',
    now() + interval '12 days',
    'GERMANIA',
    'Predio Los Pinos',
    'DJ Alquimia Crew',
    'Segunda fecha consecutiva. Capacidad limitada.',
    'https://instagram.com/fiestaalquimia',
    'Conseguir entradas',
    'preparando',
    true
),
(
    'Alquimia Edición Pasada',
    null,
    now() - interval '20 days',
    'GENERAL PINTO',
    'Club Atlético',
    'DJ Set',
    'La fiesta que rompió todo.',
    null,
    'Conseguir entradas',
    'agotado',
    true
);
*/
