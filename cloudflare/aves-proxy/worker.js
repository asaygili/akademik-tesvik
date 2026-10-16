// AVES CV yayınlar sayfası için CORS proxy'si (akademik-tesvik web sürümü).
// AVES sayfası oturum çerezi olmadan boş döner; bu yüzden önce ana sayfadan
// ci_session çerezi alınır, ardından /cv/yayinlar/ çekilir.
//
// Kullanım: GET https://aves-proxy.aves-proxy.workers.dev/?cv=asaygili.cv.nku.edu.tr
// Yalnızca *.cv.nku.edu.tr adreslerine ve izinli kökenlerden gelen isteklere izin verir.

const IZINLI_CV = /^[a-z0-9-]+\.cv\.nku\.edu\.tr$/;
const IZINLI_KOKEN = /^(https:\/\/asaygili\.github\.io|http:\/\/(localhost|127\.0\.0\.1)(:\d+)?)$/;
const UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36";

export default {
  async fetch(istek) {
    const koken = istek.headers.get("Origin") || "";
    const cors = IZINLI_KOKEN.test(koken)
      ? { "Access-Control-Allow-Origin": koken, "Vary": "Origin" }
      : {};
    const yanit = (govde, durum = 200, tur = "text/plain; charset=utf-8") =>
      new Response(govde, { status: durum, headers: { ...cors, "Content-Type": tur } });

    if (istek.method === "OPTIONS") return yanit(null, 204);
    if (istek.method !== "GET") return yanit("Yalnızca GET", 405);
    if (!cors["Access-Control-Allow-Origin"]) return yanit("İzinsiz köken", 403);

    const cv = (new URL(istek.url).searchParams.get("cv") || "").toLowerCase();
    if (!IZINLI_CV.test(cv)) return yanit("Geçersiz CV adresi", 400);

    const kok = `https://${cv}`;
    const ilk = await fetch(`${kok}/`, { headers: { "User-Agent": UA } });
    const cerez = (ilk.headers.get("set-cookie") || "").split(";")[0];
    const sayfa = await fetch(`${kok}/cv/yayinlar/`, {
      headers: { "User-Agent": UA, "Referer": `${kok}/`, ...(cerez ? { "Cookie": cerez } : {}) },
    });
    if (!sayfa.ok) return yanit(`AVES yanıt vermedi (${sayfa.status})`, 502);
    return yanit(await sayfa.text(), 200, "text/html; charset=utf-8");
  },
};
