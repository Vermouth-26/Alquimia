# Guía de Puesta en Marcha — Fiesta Alquimia

Esta guía explica paso a paso cómo dejar funcionando la web oficial y el panel de administración de **Fiesta Alquimia**.

---

## 1. Crear el proyecto en Supabase (si aún no está creado)
1. Entrá a [supabase.com](https://supabase.com/) e iniciá sesión.
2. Creá una nueva organización o seleccioná la tuya, y hacé clic en **New Project**.
3. Poné de nombre `Fiesta Alquimia`, generá una contraseña segura para la base de datos y elegí la región más cercana (ej.: `sa-east-1` São Paulo).
4. Esperá 1 o 2 minutos hasta que el proyecto esté listo.

---

## 2. Ejecutar el archivo `schema.sql`
1. En el panel izquierdo de Supabase, hacé clic en el ícono de **SQL Editor** (parece un `>_`).
2. Hacé clic en **New query**.
3. Abrí el archivo [`supabase/schema.sql`](file:///supabase/schema.sql) de esta carpeta, copiá todo su contenido y pegalo en el editor.
4. Hacé clic en el botón verde **Run** (abajo a la derecha).
5. Debería decir `Success. No rows returned`. Esto crea las tablas `events`, `site_settings`, el almacenamiento de imágenes `alquimia-media` y toda la seguridad (RLS).
> *Nota*: Este script es seguro para ejecutarse varias veces seguidas sin borrar nada.

---

## 3. Crear el usuario Administrador y bloquear el registro público
1. En el panel izquierdo de Supabase, entrá a **Authentication** → **Users**.
2. Hacé clic en **Add user** → **Create user**.
3. Ingresá el email y contraseña con el que vas a ingresar al panel desde el celular. Dejá marcada la opción de autoconfirmar email y hacé clic en **Create user**.
4. **Muy importante (Seguridad)**:
   - Andá a **Authentication** → **Sign Up / Providers** (o **Configuration** → **Auth**).
   - Buscá la opción **Allow new users to sign up** (Permitir registro de nuevos usuarios) y **desactivala**.
   - Guardá los cambios. De esta manera, nadie desconocido podrá crearse una cuenta para entrar al panel.

---

## 4. Verificar credenciales en los archivos HTML
Las credenciales de tu proyecto ya fueron configuradas con las provistas:
- `SUPABASE_URL`: `https://riwaytrjxkbpdkkpvxvx.supabase.co`
- `SUPABASE_ANON_KEY`: `eyJhbGciOiJIUzI1...`

Si en el futuro creás un proyecto nuevo o cambian las credenciales:
1. En Supabase andá a **Project Settings** (ícono de engranaje) → **API**.
2. Copiá la **Project URL** y la **Project API key (anon / public)**.
3. Abrí [`index.html`](file:///index.html), [`admin.html`](file:///admin.html) y [`netlify/edge-functions/og.js`](file:///netlify/edge-functions/og.js) y reemplazá los valores en la sección marcada con `// ⚠️ COMPLETAR`.
*(La anon key es pública por diseño: la seguridad total la otorga el sistema de permisos RLS que ejecutaste en el paso 2)*.

---

## 5. Subir a Netlify

### Opción A: Subida rápida (Drag & Drop)
1. Entrá a [netlify.com](https://app.netlify.com/) con tu cuenta.
2. En la pestaña **Sites**, arrastrá la carpeta entera de este proyecto al recuadro de subida.
3. ¡Listo! Netlify te dará un link inmediato (ej. `fiesta-alquimia-xyz.netlify.app`).
> *Nota*: La web y el admin funcionan al 100% de esta forma. Las vistas previas estáticas de redes funcionarán con la imagen por defecto.

### Opción B: Subida mediante Git o Netlify CLI (Recomendado para vista previa dinámica)
Para que WhatsApp e Instagram muestren automáticamente el flyer de la próxima fecha al compartir el enlace, conectá este repositorio a Netlify vía GitHub o usando el comando `netlify deploy --prod`. Esto activará la **Edge Function** incluida en `netlify/edge-functions/og.js`.

---

## 6. Primer uso del Panel Administrador
1. Abrí desde tu navegador o celular el link de tu web agregando `/admin.html` al final (ejemplo: `https://tu-sitio.netlify.app/admin.html`).
2. Iniciá sesión con el email y contraseña creados en el Paso 3.
3. Andá a la pestaña **Ajustes**:
   - Subí el **Logo** oficial de Fiesta Alquimia.
   - Si querés, subí una **Imagen de Fondo** personalizada.
   - Verificá la frase/lema y el link de Instagram.
   - Hacé clic en **Guardar Ajustes**.
4. Volvé a la pestaña **Próximas** y tocá el botón **+ Nueva Joda**:
   - Cargá la primera fecha, subí el flyer desde tu galería, poné el destino (ej. `GENERAL PINTO`) y el link de entradas.
   - Guardá y mirá cómo impacta de inmediato en la web pública.

---

## 7. Qué hacer cuando cambian de dominio o URL
Si compran un dominio propio (por ejemplo `fiestaalquimia.com.ar`):
1. Configuralo en Netlify en **Domain Management** siguiendo las instrucciones de DNS de tu proveedor de dominio.
2. En Supabase, andá a **Authentication** → **URL Configuration**:
   - Cambiá el **Site URL** a `https://fiestaalquimia.com.ar`.
   - Agregá `https://fiestaalquimia.com.ar/**` a **Redirect URLs**.
3. En `index.html`, actualizá la etiqueta estática `<meta property="og:url">` con el nuevo dominio.
