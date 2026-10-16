// lib/aves_servisi.dart
//
// AVES CV sisteminden (ör. asaygili.cv.nku.edu.tr) yayınları çeker ve
// Akademik Teşvik Tablo 4 faaliyetlerine dönüştürür. Dergi Q değerleri YÖK
// dergi listesinden (yayın yılına göre) bulunur; tnku-atama'daki dergi_q.py
// ile aynı veri ve aynı eşleştirme kuralları kullanılır.

import 'dart:convert';

import 'package:archive/archive.dart' show GZipDecoder;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class AvesServisi {
  /// Web sürümünde AVES'e doğrudan erişilemediği (CORS) için kullanılan
  /// Cloudflare Worker (cloudflare/aves-proxy). Derlemede
  /// --dart-define=AVES_PROXY=… ile değiştirilebilir.
  static const proxy = String.fromEnvironment('AVES_PROXY',
      defaultValue: 'https://aves-proxy.aves-proxy.workers.dev');

  static const _basliklar = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
        'AppleWebKit/537.36 Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
    'Accept-Language': 'tr-TR,tr;q=0.9',
  };

  /// "asaygili", "asaygili.cv.nku.edu.tr" ya da tam adres → https://… kökü.
  static String kokAdres(String girdi) {
    var a = girdi.trim().replaceAll(RegExp(r'^https?://'), '');
    a = a.split('/').first;
    if (!a.contains('.')) a = '$a.cv.nku.edu.tr';
    return 'https://$a';
  }

  /// AVES yayınlar sayfasını çeker. Sayfa oturum çerezi olmadan boş döner;
  /// bu yüzden önce ana sayfa ziyaret edilip `ci_session` çerezi alınır.
  static Future<String> yayinlarSayfasi(String adres) async {
    final kok = kokAdres(adres);
    if (kIsWeb) {
      final r = await http
          .get(Uri.parse(proxy)
              .replace(queryParameters: {'cv': Uri.parse(kok).host}))
          .timeout(const Duration(seconds: 30));
      if (r.statusCode != 200) {
        throw Exception('AVES çekilemedi (${r.statusCode}): ${r.body}');
      }
      return utf8.decode(r.bodyBytes, allowMalformed: true);
    }
    final ilk = await http
        .get(Uri.parse('$kok/'), headers: _basliklar)
        .timeout(const Duration(seconds: 15));
    final cerez = (ilk.headers['set-cookie'] ?? '').split(';').first;
    final r = await http.get(Uri.parse('$kok/cv/yayinlar/'), headers: {
      ..._basliklar,
      'Referer': '$kok/',
      if (cerez.isNotEmpty) 'Cookie': cerez,
    }).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) {
      throw Exception('AVES yanıt vermedi (${r.statusCode}): $kok');
    }
    return utf8.decode(r.bodyBytes, allowMalformed: true);
  }

  /// Yayınları çeker; her kayda hangi CV'den geldiği ('cv') işlenir.
  static Future<List<Map<String, dynamic>>> cek(String adres) async {
    final cv = Uri.parse(kokAdres(adres)).host;
    return [
      for (final f
          in ayristir(await yayinlarSayfasi(adres), await DergiQ.yukle()))
        {...f, 'cv': cv},
    ];
  }

  /// AVES'ten seçilen faaliyetleri mevcut listeye ekler. Listede başka bir
  /// kişinin CV'sinden gelen faaliyet varsa liste o kişiye ait sayılır ve
  /// tamamen temizlenir; aynı kişide daha önce eklenmiş yayınlar tekrar
  /// eklenmez. Döner: (yeni liste, temizlenen faaliyet sayısı).
  static (List<Map<String, dynamic>>, int) birlestir(
      List<Map<String, dynamic>> mevcut, List<Map<String, dynamic>> yeni) {
    final cv = yeni.isEmpty ? null : yeni.first['cv'];
    final baskaKisi =
        mevcut.any((f) => f['kaynak'] == 'AVES' && f['cv'] != cv);
    final kalan = baskaKisi ? <Map<String, dynamic>>[] : [...mevcut];
    final varolan = {
      for (final f in kalan)
        if (f['kunye'] != null) f['kunye'],
    };
    return (
      [...kalan, ...yeni.where((f) => !varolan.contains(f['kunye']))],
      baskaKisi ? mevcut.length : 0,
    );
  }

  // ── Ayrıştırma ─────────────────────────────────────────────

  static String _duzMetin(String html) => html
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static List<String> _etiketler(String td, String sinif) => RegExp(
          '<span[^>]*class="[^"]*$sinif[^"]*"[^>]*>(.*?)</span>',
          dotAll: true)
      .allMatches(td)
      .map((m) => _duzMetin(m.group(1)!))
      .toList();

  /// Künyedeki son yıl (bildirilerde etkinlik tarihi, diğerlerinde yayın yılı).
  static int? yil(String metin) {
    final yillar = RegExp(r'\b(?:19|20)\d{2}\b').allMatches(metin);
    return yillar.isEmpty ? null : int.parse(yillar.last.group(0)!);
  }

  /// Künyenin başındaki yazar sayısı. AVES yazarları virgülle (boşluksuz)
  /// ayırır, başlıktan önce ", " gelir. Kitaplarda biçim değişebildiği için
  /// sonuç kullanıcı tarafından düzeltilebilir.
  static int yazarSayisi(String metin) {
    final yazarlar = metin.split(', ').first.split(',');
    return yazarlar.where((y) => y.trim().isNotEmpty).length.clamp(1, 999);
  }

  static String _ascii(String s) {
    const harita = {
      'ı': 'i', 'ş': 's', 'ğ': 'g', 'ü': 'u', 'ö': 'o', 'ç': 'c',
      'â': 'a', 'á': 'a', 'à': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'í': 'i', 'î': 'i',
      'ó': 'o', 'ô': 'o', 'ø': 'o', 'ú': 'u', 'û': 'u', 'ñ': 'n',
    };
    final k = s.replaceAll('İ', 'i').toLowerCase().replaceAll('̇', '');
    return k.split('').map((c) => harita[c] ?? c).join();
  }

  /// tnku-atama dergi_q._norm karşılığı.
  static String norm(String s) => _ascii(s)
      .replaceAll('&', ' and ')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim()
      .replaceAll(RegExp(r' +'), ' ');

  static const _degilMakale = [
    'mektup', 'teknik not', 'vaka', 'olgu', 'ozet', 'kritik', 'arastirma notu',
  ];

  /// Yayınlar sayfasının HTML'inden teşvik faaliyetleri. Teşvikte karşılığı
  /// olmayan kayıtlar (ulusal kitap, TR Dizin dışı ulusal makale, özet bildiri,
  /// editöre mektup …) atlanır.
  static List<Map<String, dynamic>> ayristir(String html, [DergiQ? q]) {
    final sonuc = <Map<String, dynamic>>[];
    // AVES'te aynı eser iki kez kayıtlı olabilir (ör. ortak yazarın soyadı
    // değişince); yazarlardan sonraki kısım aynıysa ilk kayıt tutulur.
    final gorulen = <String>{};
    for (final panel in html.split('panel-heading').skip(1)) {
      final baslik = norm(
          RegExp(r'<b>(.*?)</b>', dotAll: true).firstMatch(panel)?.group(1) ??
              '');
      for (final m
          in RegExp(r'<td>(.*?)</td>', dotAll: true).allMatches(panel)) {
        final td = m.group(1)!;
        final metin = _duzMetin(td.split(RegExp(r'<br\s*/?>')).first);
        if (metin.length < 6) continue;
        final i = metin.indexOf(', ');
        if (!gorulen.add(norm(i < 0 ? metin : metin.substring(i)))) continue;
        final tip = norm(_etiketler(td, 'label-warning').join(' '));
        final endeks = _etiketler(td, 'label-info').map(norm).toSet();
        final y = yil(metin);

        String? kategori, tur;
        if (baslik.contains('hakemli dergi')) {
          if (_degilMakale.any(tip.contains)) continue;
          final sci = endeks.any((e) =>
              e == 'sci' || e == 'sci expanded' || e == 'ssci' || e == 'ahci');
          kategori = 'yayin';
          if (baslik.startsWith('ulusal')) {
            if (!endeks.contains('tr dizin')) continue;
            tur = 'ulakbim';
          } else if (sci) {
            tur = tip.contains('derleme') ? 'sciDerleme' : 'sciArastirma';
          } else if (endeks.any((e) =>
              e == 'esci' || e == 'scopus' || e.contains('alan endeks'))) {
            tur = 'alanEndeksi';
          } else if (endeks.contains('tr dizin')) {
            tur = 'ulakbim';
          } else {
            tur = 'digerUlus';
          }
        } else if (baslik.startsWith('uluslararasi kitap')) {
          if (tip.contains('tercume') || tip.contains('ceviri')) continue;
          kategori = 'yayin';
          tur = RegExp(r'Bölüm\s*:').hasMatch(metin)
              ? 'kitapUlusBolum'
              : 'kitapUlusYazar';
        } else if (baslik.startsWith('uluslararasi bilimsel toplanti')) {
          if (!tip.contains('tam metin')) continue;
          kategori = 'teblig';
          tur = 'uluslararasiTeblig';
        } else {
          continue;
        }

        final f = <String, dynamic>{
          'kategori': kategori,
          'tur': tur,
          'kisi': yazarSayisi(metin),
          'adet': 1,
          'yil': y,
          'kunye': metin,
          'kaynak': 'AVES',
        };
        if (tur == 'sciArastirma' || tur == 'sciDerleme') {
          final bulunan = q?.q(y, metin);
          // m.8/6: Q değeri belirlenemeyen dergiye en alt katsayı uygulanır.
          f['quartile'] = bulunan ?? 'Q4';
          f['qBulunamadi'] = bulunan == null;
          f['ahci'] = endeks.contains('ahci') &&
              !endeks.any((e) => e.startsWith('sci') || e == 'ssci');
        }
        sonuc.add(f);
      }
    }
    return sonuc;
  }
}

/// YÖK dergi listesi: ISSN → [ad, {yıl: çeyreklik}] (SCIE / SSCI / AHCI).
class DergiQ {
  final Map<String, dynamic> dergiler;
  final Map<String, String> _adlar = {};

  DergiQ(this.dergiler) {
    dergiler.forEach((issn, v) {
      final ad = (v as List)[0] as String;
      _adlar.putIfAbsent(AvesServisi.norm(ad), () => issn);
      // "APPLIED SCIENCES-BASEL" → "APPLIED SCIENCES"
      for (final parca in ad.split(RegExp(r'-(?=[A-Z])'))) {
        final n = AvesServisi.norm(parca);
        if (n.length >= 12) _adlar.putIfAbsent(n, () => issn);
      }
    });
  }

  static DergiQ? _onbellek;

  static Future<DergiQ> yukle() async {
    if (_onbellek != null) return _onbellek!;
    final veri = await rootBundle.load('assets/yok_dergi_q.json.gz');
    final metin = utf8.decode(GZipDecoder().decodeBytes(veri.buffer.asUint8List()));
    return _onbellek = DergiQ(
        (jsonDecode(metin) as Map<String, dynamic>)['dergiler']
            as Map<String, dynamic>);
  }

  static final _son = RegExp(r',\s*(vol|volume|cilt|ss|pp|no|sayı)\b',
      caseSensitive: false);

  /// Künye "Yazarlar, Başlık, Dergi, vol. …" biçimindedir; dergi adı
  /// başlıktan sonraki son 1-4 virgüllü parçada TAM eşleşmeyle aranır.
  String? issn(String kunye) {
    final m = _son.firstMatch(kunye);
    if (m == null) return null;
    final parcalar = kunye.substring(0, m.start).split(',');
    for (var k = 1; k <= 4 && k <= parcalar.length; k++) {
      final i = _adlar[AvesServisi.norm(
          parcalar.sublist(parcalar.length - k).join(','))];
      if (i != null) return i;
    }
    return null;
  }

  /// Yayın yılının çeyrekliği; listede yoksa en yakın önceki yıl.
  String? q(int? yil, String kunye) {
    final i = issn(kunye);
    if (i == null) return null;
    final yillar = ((dergiler[i] as List)[1] as Map)
        .map((y, q) => MapEntry(int.parse(y as String), q as int));
    final onceki = yillar.keys.where((y) => yil == null || y <= yil);
    final y = onceki.isEmpty
        ? yillar.keys.reduce((a, b) => a < b ? a : b)
        : onceki.reduce((a, b) => a > b ? a : b);
    return 'Q${yillar[y]}';
  }
}
