# TAREA: Web de Fiesta Alquimia (index + admin) — HTML puro + Supabase + Netlify

> Este documento es la especificación completa. Seguila al pie de la letra. Si algo es ambiguo o crees que falta algo, NO inventes: elegí la opción más simple, anotala en el reporte final (sección "Decisiones y dudas") y seguí.

---

## 0. Antes de empezar: Skills

1. Leé `D:\Archivos\Proyectos_personales\Skills-Optimized\MAP.md`.
2. Elegí las skills que apliquen a esta tarea (como mínimo: diseño frontend, Supabase/RLS, HTML/CSS/JS vanilla, accesibilidad/rendimiento móvil si existen).
3. Listá en el reporte final cuáles usaste y para qué.
4. Si la ruta no existe o no se puede leer, seguí igual con esta spec y avisalo en el reporte.

---

## 1. Contexto y objetivo

**Fiesta Alquimia** es una joda de un pueblo de Argentina. Hoy su única "web" es un Taplink con un botón a Instagram (`@fiestaalquimia`). Hay que reemplazarlo por una web propia, rápida y con onda, que se sube a **Netlify** y se administra desde el **celular**.

- Hacen una joda por finde, a veces dos juntas en pueblos distintos, y en carnaval una por día. **La web tiene que soportar varias jodas a la vez.**
- Ya no hacen jodas solo en su pueblo: se quieren expandir a otros. Destinos usados hasta ahora: **General Pinto** y **Germania**.
- Las fotos las suben a un Drive, pero **recién semanas después** de cada joda.
- Instagram: https://www.instagram.com/fiestaalquimia/
- Lema: "Vivamos el momento, disfrutemos cada encuentro ;)"

Idioma de toda la interfaz: **español rioplatense** (vos, tuteo argentino), tono joven y directo.

---

## 2. Stack y restricciones (no negociables)

- **Dos archivos HTML autocontenidos**: `index.html` (público) y `admin.html` (panel). CSS y JS inline en cada uno. **Sin build, sin npm, sin frameworks.** JavaScript vanilla (ES modules o scripts clásicos, lo que sea más simple).
- **Backend: Supabase** (plan gratis) usando `@supabase/supabase-js` v2 por CDN (jsDelivr). Auth + Postgres + Storage.
- **Hosting: Netlify.** Archivos extra permitidos: `netlify.toml`, `_headers`, `SETUP.md`, `supabase/schema.sql`, y (opcional, ver §9) una Edge Function.
- La URL del proyecto y la `anon key` de Supabase van como constantes al principio de cada HTML, con un comentario claro `// ⚠️ COMPLETAR`. La anon key es pública por diseño: **la seguridad la da RLS**, no ocultar la key.
- Fuentes: Google Fonts con `display=swap`. Titulares: **Anton** (o Bebas Neue). Texto: **Inter** (o Archivo). Nada más pesado.
- Mobile-first. Debe verse perfecto en 360px de ancho y escalar bien a desktop.

---

## 3. Identidad visual

Basada en el Instagram de la joda: flyers rojos y negros, fotos en blanco y negro con grano, tipografía condensada gigante en mayúsculas, logo de carpa/tipi en blanco.

- **Paleta**: fondo `#0A0A0A`; rojo principal ~`#D32F2F` (probar entre `#C8102E` y `#E03535`); rojo oscuro `#7A0C12`; blanco `#FFFFFF`; gris `#B5B5B5`. Definir como variables CSS en `:root`.
- **Textura**: grano sutil sobre toda la página (SVG `feTurbulence` inline o PNG en base64 muy liviano), opacidad baja (~6-10%). No debe afectar el rendimiento ni la lectura.
- **Fondo por defecto**: gradiente oscuro con rojo muy sutil + grano. Sin significado particular.
- **Fondo configurable**: si en `site_settings.background_url` hay imagen, se usa como fondo fijo (`background-attachment: fixed` en desktop; en móvil usar un pseudo-elemento `position: fixed` para evitar bugs de iOS) con un overlay oscuro (~70-80%) para que el texto siempre se lea.
- **Logo**: ícono de carpa/tipi (triángulo con líneas horizontales y punta arriba). El logo real lo provee el cliente y se sube desde el admin (`site_settings.logo_url`). **Mientras no haya logo cargado**, usar un SVG placeholder simple de carpa en blanco, dibujado por vos (original, geométrico, 1 color).
- Esquinas casi rectas (radio máx. 4-6px). Bordes finos, nada de sombras blandas tipo "app genérica". Aire y jerarquía fuerte.
- Los textos de fecha usan el formato de los flyers: `SÁB 10.10` (día de semana abreviado + dd.mm), en mayúsculas.

---

## 4. Modelo de datos (Supabase)

Entregar `supabase/schema.sql` ejecutable de una sola vez en el SQL Editor de Supabase, idempotente cuando sea posible (`if not exists`, `drop policy if exists`).

Anon-key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpd2F5dHJqeGticGRra3B2eHZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2MjUyODUsImV4cCI6MjEwODIwMTI4NX0.oMu0L2ADnT20BGDk1tIIacScvvxiNh3EP50SaA-aiAw

Supabase-url: https://riwaytrjxkbpdkkpvxvx.supabase.co

### Tabla `events`

| Columna                    | Tipo                                       | Notas                                                                                                     |
| -------------------------- | ------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `id`                       | uuid PK default `gen_random_uuid()`        |                                                                                                           |
| `title`                    | text not null                              | Ej.: "Alquimia", "Set Llegó El Don"                                                                       |
| `group_name`               | text null                                  | Para agrupar (ej.: "Carnaval 2027"). Las jodas con el mismo `group_name` se muestran bajo un título común |
| `event_date`               | timestamptz not null                       | Inicio de la joda                                                                                         |
| `destination`              | text null                                  | Pueblo/destino. Máx. 16 caracteres (check constraint), se guarda en mayúsculas                            |
| `venue`                    | text null                                  | Lugar/boliche (texto libre)                                                                               |
| `lineup`                   | text null                                  | DJs/line-up, una línea por artista                                                                        |
| `description`              | text null                                  | Texto corto opcional (máx. 280)                                                                           |
| `flyer_url`                | text null                                  | URL pública en Storage                                                                                    |
| `ticket_url`               | text null                                  | Link externo de compra                                                                                    |
| `ticket_button_label`      | text not null default 'Conseguir entradas' | Editable (no sabemos qué plataforma usan)                                                                 |
| `status`                   | text not null default 'preparando'         | check in: `preparando`, `tanda_1`, `tanda_2`, `tanda_3`, `tanda_4`, `tanda_especial`, `ultima_tanda`, `agotado` |
| `drive_url`                | text null                                  | Link de Drive con fotos (se carga semanas después)                                                        |
| `published`                | boolean not null default true              | Borrador/oculta si es `false`                                                                             |
| `created_at`, `updated_at` | timestamptz default `now()`                | `updated_at` con trigger                                                                                  |

Índice por `event_date`.

### Tabla `site_settings` (una sola fila, `id = 1`, check `id = 1`)

`site_title` (default 'Fiesta Alquimia'), `tagline` (default el lema), `instagram_url` (default la URL real), `logo_url`, `background_url`, `og_image_url`, `updated_at`.
Insertar la fila inicial con los defaults.

### Estado "Finalizada" (derivado, NO se guarda)

Una joda está **finalizada** cuando `ahora > event_date + 12 horas` (constante `FINISH_AFTER_HOURS = 12` al inicio del JS). Entre `event_date` y ese límite está "en curso".

### RLS (obligatorio)

- `events`: `select` público solo donde `published = true`; `insert/update/delete` solo rol `authenticated`. Los autenticados también ven las no publicadas (policy de select adicional para `authenticated` sin filtro).
- `site_settings`: `select` público; `update` solo `authenticated`.
- **Storage**: bucket público `alquimia-media` (lectura pública, escritura/borrado solo `authenticated`). Crearlo desde el SQL (`insert into storage.buckets ...`) con sus policies.
- El registro público de usuarios debe quedar **deshabilitado** (indicarlo en `SETUP.md`: los admins se crean a mano desde el dashboard de Supabase).
- Incluir en `schema.sql`, comentado y claramente marcado, un bloque opcional con 2 jodas de ejemplo (General Pinto y Germania) para probar.

---

## 5. `index.html` — página pública

Estructura, de arriba hacia abajo:

### 5.1 Hero

Logo, "FIESTA ALQUIMIA" en tipografía gigante, lema (`site_settings.tagline`). Botón/enlace a Instagram. Debe ser impactante pero corto: la próxima joda tiene que asomar sin tener que scrollear mucho en un celu.

### 5.2 Próximas jodas

- Trae las jodas **no finalizadas** (incluye "en curso"), ordenadas por `event_date` ascendente.
- Si varias comparten `group_name`, se muestran juntas bajo un encabezado con ese nombre (ej.: "CARNAVAL 2027") y orden por fecha. Las que no tienen grupo van sueltas.
- Si no hay ninguna: mensaje "Estamos preparando la próxima. Seguinos en Instagram." con el botón de Instagram.

**Card de joda** (imagen + texto combinados):

- El **flyer** ocupa la parte superior o actúa de fondo de la card con degradado oscuro hacia abajo para que el texto se lea (elegir la variante que mejor quede; ambas deben verse bien con flyers de distintas proporciones: usar `object-fit: cover` y `aspect-ratio` controlado). Sin flyer: fondo rojo oscuro con grano y el logo como marca de agua.
- Sobre/junto al flyer: fecha (`SÁB 10.10` + hora), título, **tablero del destino** (ver §6), lugar (si hay), line-up (si hay), descripción (si hay).
- **Badge de estado** (ver §7).
- **Cuenta regresiva** (ver §8).
- **Botón de entradas** según estado (ver §7).
- **Botón "Compartir"**: abre `https://wa.me/?text=` con mensaje armado: `🔥 {título} — {SÁB 10.10} en {destino}. Entradas y info: {URL de la web}`. Usar `encodeURIComponent`.

### 5.3 Fotos

- Jodas **finalizadas**, más recientes primero, con límite de las últimas 12 y botón "Ver más" si hay más.
- **Sin `drive_url`** → estado **"Revelando fotos…"**:
  - Imagen del flyer (o fondo rojo oscuro si no hay) en blanco y negro con un blur que oscila suavemente (animación CSS en loop, ej.: blur 10px ↔ 4px, 4-6 s).
  - Texto: `Revelando fotos…` y debajo contador `hace N días` (calculado desde `event_date`).
  - Sin botón.
- **Con `drive_url`** → estado **"Fotos listas"**: card destacada con borde rojo, flyer en color nítido y botón **"Ver fotos"** (abre el Drive en pestaña nueva).
- Si no hay jodas pasadas, ocultar toda la sección.

### 5.4 Footer

Logo chico, Instagram, `© {año} Fiesta Alquimia`.

### 5.5 Carga y errores

- Skeletons simples mientras carga.
- Si falla Supabase: mensaje amable "No pudimos cargar las jodas. Reintentar" con botón de reintento. Nunca pantalla en blanco.

---

## 6. Efecto aeropuerto (solo en el destino)

Tablero tipo _split-flap_ únicamente para `destination`.

- Ancho fijo de **16 celdas** (el máximo de caracteres). Cada celda es un cuadradito oscuro con borde fino, letra blanca en tipografía monoespaciada/condensada, línea horizontal fina en el medio.
- Al entrar la card en pantalla (`IntersectionObserver`, una sola vez), cada celda **gira** ciclando letras aleatorias (A-Z, 0-9) y se **fija de izquierda a derecha** con escalonado (~100 ms entre celdas, duración total ~3 s). El destino queda "revelándose de a poco".
- Si hay varias cards, cada tablero arranca cuando su card es visible: el efecto se ve en cascada de forma natural.
- Espacios del destino = celdas vacías. Si el destino tiene menos de 16 letras, centrarlo o alinearlo a la izquierda (elegir una y mantenerla), sin mostrar celdas vacías sobrantes si queda feo (se pueden mostrar solo las necesarias).
- **Accesibilidad**: `aria-label="Destino: {destino}"` en el contenedor, celdas con `aria-hidden="true"`. Respetar `prefers-reduced-motion`: mostrar el destino final sin animación.
- Si `destination` es null o vacío, no se muestra el tablero.
- Pequeño rótulo arriba del tablero: `DESTINO`.

---

## 7. Estados de la joda

| Estado (`status` / derivado) | Badge                                      | Botón de entradas                                          |
| ---------------------------- | ------------------------------------------ | ---------------------------------------------------------- |
| `preparando`                 | `PREPARANDO JODA` (gris/blanco)            | Oculto. Texto "Muy pronto, seguinos en Instagram" con link |
| `tanda_1`                    | `ENTRADAS A LA VENTA · TANDA 1` (rojo)     | Visible (`ticket_url`, `ticket_button_label`)              |
| `tanda_2`                    | `ENTRADAS A LA VENTA · TANDA 2` (rojo)     | Visible                                                    |
| `tanda_3`                    | `ENTRADAS A LA VENTA · TANDA 3` (rojo)     | Visible                                                    |
| `tanda_4`                    | `ENTRADAS A LA VENTA · TANDA 4` (rojo)     | Visible                                                    |
| `tanda_especial`             | `ENTRADAS A LA VENTA · TANDA ESPECIAL` (naranja) | Visible                                              |
| `ultima_tanda`               | `ÚLTIMA TANDA` (rojo intenso, pulso sutil) | Visible                                                    |
| `agotado`                    | `AGOTADO` (gris tachado/apagado)           | Deshabilitado, texto "Agotado"                             |
| en curso (derivado)          | `ES HOY`                                   | Oculto                                                     |
| finalizada (derivado)        | — pasa a sección Fotos                     | —                                                          |

Reglas: si el estado es de venta pero `ticket_url` está vacío, ocultar el botón (no mostrar un botón roto). El `ticket_url` se abre en pestaña nueva con `rel="noopener noreferrer"`.

---

## 8. Cuenta regresiva

- En cada card de joda futura: `DD días · HH h · MM min · SS s`, actualizada cada segundo con **un solo** `setInterval` global (no uno por card).
- Zona horaria: calcular siempre contra `event_date` (UTC) y **mostrar fechas/horas en `America/Argentina/Buenos_Aires`** (`Intl.DateTimeFormat`) sin importar la zona del dispositivo.
- Si falta menos de 24 h, mostrar solo `HH:MM:SS` con énfasis.
- Si ya empezó y no terminó: reemplazar por `¡ES HOY! 🔥` / `EN CURSO`.

---

## 9. Preview al compartir (Open Graph)

- En `index.html` poner meta tags estáticos: `og:title`, `og:description`, `og:image`, `og:type=website`, `twitter:card=summary_large_image`, con valores por defecto razonables y un placeholder claro para la imagen.
- **Limitación**: WhatsApp e Instagram no ejecutan JavaScript, así que los meta tags dinámicos desde el cliente no sirven. Para que el preview muestre el flyer de la **próxima joda**, implementar una **Netlify Edge Function** opcional (`netlify/edge-functions/og.js` + `netlify.toml`) que, en la ruta `/`:
  1. Consulta por la REST API de Supabase (con la anon key) la próxima joda publicada no finalizada.
  2. Reemplaza `og:title`, `og:description` y `og:image` en el HTML antes de responderlo.
  3. Si cualquier cosa falla, devuelve el HTML original sin tocar (fail-safe, nunca romper la página).
- La Edge Function no corre con deploy por arrastrar carpeta en Netlify Drop; requiere deploy por Git o Netlify CLI. **La página debe funcionar perfecto sin ella** (con OG estático). Documentar esto en `SETUP.md`.
- Si no hay joda próxima, usar `site_settings.og_image_url`.

---

## 10. `admin.html` — panel (mobile-first)

Pensado para usar con una mano desde el celular. Botones grandes (mín. 44px de alto), inputs cómodos, sin tablas anchas. Debe incluir `<meta name="robots" content="noindex,nofollow">`.

### 10.1 Login

- Email + contraseña con Supabase Auth. Sesión persistente. Botón "Cerrar sesión".
- Mensajes de error claros ("Email o contraseña incorrectos"). Si no hay sesión, **no** se muestra ningún dato del panel.

### 10.2 Listado de jodas

- Pestañas: **Próximas** | **Pasadas** | **Ajustes**.
- Cada item muestra: miniatura del flyer, título, fecha, destino, badge de estado y si está oculta (`published = false`).
- **Cambio rápido de estado** directo desde la lista (un `<select>`), sin abrir el formulario completo.
- En **Pasadas**: las que no tienen `drive_url` llevan una etiqueta destacada **"Falta subir fotos"** y un campo/botón rápido **"Pegar link de Drive"** para cargarlo en un paso.
- Acciones por item: Editar, Duplicar (copia con fecha vacía y estado `preparando`, abre el formulario), Ocultar/Mostrar, Eliminar (con confirmación explícita).
- Botón flotante grande **"+ Nueva joda"**.

### 10.3 Formulario crear/editar

Pantalla completa en móvil. Campos:

- Título (obligatorio)
- Grupo (opcional, con autocompletado de grupos existentes vía `<datalist>`)
- Fecha y hora (`datetime-local`, interpretada y guardada como hora de **Argentina**, UTC-3)
- Destino (máx. 16 caracteres, contador visible, se pasa a mayúsculas)
- Lugar
- Line-up (textarea, un artista por línea)
- Descripción (máx. 280, contador)
- Flyer: subir imagen desde galería/cámara con vista previa
- Link de entradas + texto del botón
- Estado (selector con las 5 opciones y sus nombres visibles)
- Link de Drive de fotos (opcional)
- Publicada (switch)
- Vista previa en vivo de cómo se ve la card (aunque sea simplificada).
- Guardar con feedback visible (spinner, toast de éxito/error). No perder lo escrito si falla el guardado.

### 10.4 Ajustes

Subir/cambiar **logo**, **imagen de fondo**, **imagen para compartir (OG)**; editar **lema**, **título** y **URL de Instagram**; botón "Quitar fondo" para volver al por defecto.

### 10.5 Subida de imágenes

- Redimensionar en el cliente antes de subir (máx. 1600 px de lado mayor, JPEG calidad ~0.85, usando `canvas`) para cuidar los 1 GB del plan gratis.
- Nombres de archivo únicos (`uuid` o timestamp). Al reemplazar una imagen, borrar la anterior del bucket.
- Validar tipo (jpg/png/webp) y tamaño máximo de origen (ej. 15 MB).

---

## 11. Seguridad y calidad

- **Nunca** usar `innerHTML` con datos que vengan de la base. Usar `textContent`/nodos DOM. Esto evita XSS desde el admin.
- Validar que `ticket_url`, `drive_url` e `instagram_url` empiecen con `https://` (o `http://`); rechazar `javascript:` y cualquier otro esquema. Mostrar error en el formulario.
- Todos los links externos: `target="_blank" rel="noopener noreferrer"`.
- Imágenes con `loading="lazy"` y `alt` descriptivo (excepto las decorativas).
- Contraste suficiente (blanco sobre negro/rojo oscuro). Foco visible en elementos interactivos.
- Sin dependencias externas salvo: supabase-js (CDN), Google Fonts.
- Evitar layout shift (reservar alto de imágenes con `aspect-ratio`).

---

## 12. Fuera de alcance (NO hacer)

- Botón "Cómo llegar" / Google Maps.
- Mapa de rutas entre pueblos.
- Aviso "avisame cuando estén las fotos" (no recolectar contactos).
- Ventas o pagos propios: las entradas siempre van por link externo.
- Cualquier framework, build step o dependencia npm.

---

## 13. Entregables

```
/
├─ index.html
├─ admin.html
├─ netlify.toml                      (config básica + edge function si aplica)
├─ netlify/edge-functions/og.js      (opcional, fail-safe)
├─ supabase/schema.sql
└─ SETUP.md
```

`SETUP.md` (corto, para alguien no técnico, en español) debe explicar paso a paso:

1. Crear el proyecto en Supabase.
2. Ejecutar `schema.sql` en el SQL Editor.
3. Crear el/los usuarios admin en Authentication → Users y **deshabilitar el signup público**.
4. Copiar `Project URL` y `anon key` a las constantes de `index.html` y `admin.html`.
5. Subir a Netlify (drag & drop sirve para la web; para la Edge Function de OG hace falta Git/CLI).
6. Primer uso del admin: cargar logo, fondo, y la primera joda.
7. Qué hacer cuando cambian de dominio o URL.

---

## 14. Criterios de aceptación (verificar TODO antes de reportar)

- [ ] `index.html` carga sin errores de consola, con y sin datos, en 360 px y en desktop.
- [ ] Con 0, 1, 2 y 6+ jodas se ve bien. Agrupación por `group_name` funciona.
- [ ] El tablero de destino anima una vez por card al aparecer; con `prefers-reduced-motion` no anima.
- [ ] La cuenta regresiva usa un único intervalo y la hora siempre se muestra en horario de Argentina.
- [ ] Cada estado muestra su badge y botón correctos (§7). Botón nunca roto.
- [ ] Una joda pasa sola a "Fotos" a las 12 h de su inicio; sin Drive muestra "Revelando fotos…" con `hace N días`; al cargar el link muestra "Ver fotos".
- [ ] El admin funciona 100% desde el celular: login, crear, editar, duplicar, ocultar, borrar, cambio rápido de estado, pegar link de Drive, subir imágenes, ajustes.
- [ ] Usuario sin sesión **no puede** escribir en la base (probar con la anon key sin login: debe fallar por RLS).
- [ ] No hay `innerHTML` con datos de la base. URLs validadas.
- [ ] Si Supabase falla, la web muestra el mensaje con reintento, no pantalla en blanco.
- [ ] `schema.sql` corre limpio en un proyecto nuevo, dos veces seguidas sin romper.
- [ ] La página funciona sin la Edge Function.

---

## 15. Reporte final (devolveme esto al terminar)

1. **Resumen** en 5 líneas máx.: qué quedó hecho.
2. **Skills usadas** de `MAP.md` y para qué.
3. **Checklist de §14**: cada ítem con ✅ / ⚠️ / ❌ y una línea de evidencia.
4. **Decisiones y dudas**: cualquier cosa que decidiste por tu cuenta o que quedó ambigua.
5. **Pendientes para el cliente**: qué tiene que completar él (keys, logo, imágenes, crear usuario admin).
6. **Lo que NO pudiste verificar** (ej.: la Edge Function, el comportamiento en iOS) y cómo probarlo.
7. Árbol de archivos entregados.
