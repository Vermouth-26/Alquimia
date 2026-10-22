// Netlify Edge Function: Dynamic Open Graph preview for WhatsApp / Instagram / Twitter crawlers
// Fail-safe: Any failure returns original response without crashing.

const SUPABASE_URL = "https://riwaytrjxkbpdkkpvxvx.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpd2F5dHJqeGticGRra3B2eHZ4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2MjUyODUsImV4cCI6MjEwODIwMTI4NX0.oMu0L2ADnT20BGDk1tIIacScvvxiNh3EP50SaA-aiAw";
const FINISH_AFTER_HOURS = 12;

export default async function handler(request, context) {
  try {
    const response = await context.next();
    
    // Solo modificar respuestas HTML
    const contentType = response.headers.get("content-type") || "";
    if (!contentType.includes("text/html")) {
      return response;
    }

    const html = await response.text();

    // Consultar eventos publicados de Supabase
    const headers = {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      "Content-Type": "application/json",
    };

    const eventsRes = await fetch(
      `${SUPABASE_URL}/rest/v1/events?published=eq.true&order=event_date.asc&select=*`,
      { headers }
    );

    let nextEvent = null;
    const now = Date.now();

    if (eventsRes.ok) {
      const events = await eventsRes.json();
      nextEvent = events.find((evt) => {
        const evtTime = new Date(evt.event_date).getTime();
        return now <= evtTime + FINISH_AFTER_HOURS * 3600 * 1000;
      });
    }

    let ogTitle = "Fiesta Alquimia";
    let ogDesc = "Vivamos el momento, disfrutemos cada encuentro ;)";
    let ogImage = "";

    if (nextEvent) {
      const dest = nextEvent.destination ? ` · ${nextEvent.destination}` : "";
      ogTitle = `Fiesta Alquimia — ${nextEvent.title}${dest}`;
      ogDesc = nextEvent.description || `Próxima joda: ${nextEvent.title}. Entradas e info oficial.`;
      if (nextEvent.flyer_url) {
        ogImage = nextEvent.flyer_url;
      }
    }

    // Si no hay imagen de flyer, intentar cargar imagen OG de site_settings
    if (!ogImage) {
      try {
        const settingsRes = await fetch(
          `${SUPABASE_URL}/rest/v1/site_settings?id=eq.1&select=*`,
          { headers }
        );
        if (settingsRes.ok) {
          const [settings] = await settingsRes.json();
          if (settings) {
            if (settings.og_image_url) ogImage = settings.og_image_url;
            if (settings.tagline && !nextEvent) ogDesc = settings.tagline;
          }
        }
      } catch (_) {
        // Fallback silencioso
      }
    }

    // Reemplazar metatags en el HTML
    let modifiedHtml = html;

    const escapeAttr = (str) =>
      str.replace(/"/g, "&quot;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

    if (ogTitle) {
      modifiedHtml = modifiedHtml.replace(
        /<meta property="og:title" content="[^"]*"/i,
        `<meta property="og:title" content="${escapeAttr(ogTitle)}"`
      );
      modifiedHtml = modifiedHtml.replace(
        /<meta name="twitter:title" content="[^"]*"/i,
        `<meta name="twitter:title" content="${escapeAttr(ogTitle)}"`
      );
      modifiedHtml = modifiedHtml.replace(
        /<title>[^<]*<\/title>/i,
        `<title>${escapeAttr(ogTitle)}</title>`
      );
    }

    if (ogDesc) {
      modifiedHtml = modifiedHtml.replace(
        /<meta property="og:description" content="[^"]*"/i,
        `<meta property="og:description" content="${escapeAttr(ogDesc)}"`
      );
      modifiedHtml = modifiedHtml.replace(
        /<meta name="twitter:description" content="[^"]*"/i,
        `<meta name="twitter:description" content="${escapeAttr(ogDesc)}"`
      );
      modifiedHtml = modifiedHtml.replace(
        /<meta name="description" content="[^"]*"/i,
        `<meta name="description" content="${escapeAttr(ogDesc)}"`
      );
    }

    if (ogImage) {
      modifiedHtml = modifiedHtml.replace(
        /<meta property="og:image" content="[^"]*"/i,
        `<meta property="og:image" content="${escapeAttr(ogImage)}"`
      );
      modifiedHtml = modifiedHtml.replace(
        /<meta name="twitter:image" content="[^"]*"/i,
        `<meta name="twitter:image" content="${escapeAttr(ogImage)}"`
      );
    }

    const newHeaders = new Headers(response.headers);
    newHeaders.delete("content-length");

    return new Response(modifiedHtml, {
      status: response.status,
      statusText: response.statusText,
      headers: newHeaders,
    });
  } catch (err) {
    // Fail-safe: si falla, devolver la respuesta sin tocar
    return context.next();
  }
}
