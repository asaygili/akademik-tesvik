// lib/openalex_servisi.dart
//
// Kişinin yayınlarına seçilen yılda yapılan atıfları OpenAlex'ten çeker ve
// Tablo 4 atıf türlerine ayırır. OpenAlex ücretsizdir ve tarayıcıdan doğrudan
// erişime (CORS) izin verir; proxy gerekmez.
//
// Sınırlar: OpenAlex ESCI / Scopus / TR Dizin bilgisini tutmaz. SCI/SSCI/AHCI
// ayrımı YÖK dergi listesindeki ISSN'lerle yapılır; diğer dergi atıfları
// "diğer uluslararası" sayılır ve kullanıcı tarafından düzeltilebilir.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'aves_servisi.dart';

class OpenAlexYazar {
  final String id; // "A5061416209"
  final String ad;
  final String kurum;
  final int yayinSayisi;
  final int atifSayisi;

  const OpenAlexYazar(
      this.id, this.ad, this.kurum, this.yayinSayisi, this.atifSayisi);

  @override
  String toString() =>
      '$ad${kurum.isEmpty ? '' : ' · $kurum'} · $yayinSayisi yayın, '
      '$atifSayisi atıf';
}

class AtifSonucu {
  /// Atıf türü ('sci', 'digerUlusAtif', 'kitap') → atıf sayısı.
  final Map<String, int> sayilar;
  final int ozAtif;
  final int atlanan; // dergi/kitap dışı kaynaklar (ön baskı, tez, bildiri …)

  const AtifSonucu(this.sayilar, this.ozAtif, this.atlanan);
}

class OpenAlexServisi {
  static const _kok = 'https://api.openalex.org';

  static Future<Map<String, dynamic>> _getir(
      String yol, Map<String, String> parametreler) async {
    final r = await http
        .get(Uri.parse('$_kok/$yol').replace(queryParameters: parametreler))
        .timeout(const Duration(seconds: 30));
    if (r.statusCode != 200) {
      throw Exception('OpenAlex yanıt vermedi (${r.statusCode})');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  static String _kisaId(String? url) => (url ?? '').split('/').last;

  /// Ada göre yazar adayları; Namık Kemal Üniversitesi'ndekiler önce gelir.
  static Future<List<OpenAlexYazar>> yazarAra(String ad) async {
    final d = await _getir('authors', {'search': ad, 'per-page': '10'});
    final adaylar = [
      for (final a in d['results'] as List)
        OpenAlexYazar(
          _kisaId(a['id']),
          a['display_name'] ?? '',
          [
            for (final k in (a['last_known_institutions'] as List? ?? []))
              k['display_name'] ?? ''
          ].join(', '),
          (a['works_count'] as num?)?.toInt() ?? 0,
          (a['cited_by_count'] as num?)?.toInt() ?? 0,
        ),
    ];
    int puan(OpenAlexYazar y) =>
        (y.kurum.contains('Namık Kemal') ? 1000000 : 0) + y.yayinSayisi;
    adaylar.sort((a, b) => puan(b).compareTo(puan(a)));
    return adaylar;
  }

  /// Cursor ile tüm sayfaları dolaşır.
  static Future<List<Map<String, dynamic>>> _hepsi(
      Map<String, String> parametreler) async {
    final sonuc = <Map<String, dynamic>>[];
    String? imlec = '*';
    while (imlec != null) {
      final d = await _getir(
          'works', {...parametreler, 'per-page': '200', 'cursor': imlec});
      sonuc.addAll((d['results'] as List).cast<Map<String, dynamic>>());
      imlec = (d['meta'] as Map?)?['next_cursor'] as String?;
      if ((d['results'] as List).isEmpty) break;
    }
    return sonuc;
  }

  /// Yazarın yayınlarına [yil] içinde yapılan atıflar.
  static Future<AtifSonucu> atiflar(String yazarId, int yil,
      [DergiQ? dergiQ]) async {
    final q = dergiQ ?? await DergiQ.yukle();
    final eserler = {
      for (final w in await _hepsi(
          {'filter': 'author.id:$yazarId', 'select': 'id'}))
        _kisaId(w['id'])
    };
    final atifYapanlar = <String, Map<String, dynamic>>{};
    final liste = eserler.toList();
    // OpenAlex bir filtrede en çok 100 değeri "|" ile birleştirmeye izin verir.
    for (var i = 0; i < liste.length; i += 100) {
      final parca = liste.sublist(i, (i + 100).clamp(0, liste.length));
      for (final w in await _hepsi({
        'filter': 'cites:${parca.join('|')},publication_year:$yil',
        'select': 'id,type,primary_location,authorships,referenced_works',
      })) {
        atifYapanlar[_kisaId(w['id'])] = w;
      }
    }
    return siniflandir(atifYapanlar.values, yazarId, eserler, q);
  }

  /// Atıf yapan yayınları türlere ayırır. Bir yayın kişinin birden fazla
  /// eserine atıf yapıyorsa her eser için ayrı atıf sayılır.
  static AtifSonucu siniflandir(Iterable<Map<String, dynamic>> atifYapanlar,
      String yazarId, Set<String> eserler, DergiQ q) {
    final sayilar = <String, int>{};
    var ozAtif = 0, atlanan = 0;
    for (final w in atifYapanlar) {
      final yazarlar = [
        for (final a in (w['authorships'] as List? ?? []))
          _kisaId((a['author'] as Map?)?['id'])
      ];
      final adet = [
        for (final r in (w['referenced_works'] as List? ?? []))
          if (eserler.contains(_kisaId(r))) r
      ].length.clamp(1, 1 << 20);
      if (yazarlar.contains(yazarId)) {
        ozAtif += adet;
        continue;
      }
      final kaynak =
          ((w['primary_location'] as Map?)?['source'] as Map?) ?? const {};
      final tur = w['type'] as String? ?? '';
      String? atifTuru;
      if (tur == 'book' || tur == 'book-chapter') {
        atifTuru = 'kitap';
      } else if (kaynak['type'] == 'journal') {
        final issnler = [
          for (final i in (kaynak['issn'] as List? ?? []))
            (i as String).toUpperCase()
        ];
        atifTuru = issnler.any(q.dergiler.containsKey) ? 'sci' : 'digerUlusAtif';
      }
      if (atifTuru == null) {
        atlanan += adet;
      } else {
        sayilar[atifTuru] = (sayilar[atifTuru] ?? 0) + adet;
      }
    }
    return AtifSonucu(sayilar, ozAtif, atlanan);
  }
}
