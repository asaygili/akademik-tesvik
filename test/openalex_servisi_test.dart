import 'package:akademik_tesvik/aves_servisi.dart';
import 'package:akademik_tesvik/hesaplama_motoru.dart';
import 'package:akademik_tesvik/openalex_servisi.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _w(String id,
        {List<String> yazarlar = const ['A9'],
        String tur = 'article',
        String? kaynakTuru = 'journal',
        List<String> issn = const [],
        List<String> atiflar = const ['W1']}) =>
    {
      'id': 'https://openalex.org/$id',
      'type': tur,
      'authorships': [
        for (final y in yazarlar) {'author': {'id': 'https://openalex.org/$y'}}
      ],
      'primary_location': {
        'source': kaynakTuru == null ? null : {'type': kaynakTuru, 'issn': issn}
      },
      'referenced_works': [for (final a in atiflar) 'https://openalex.org/$a'],
    };

void main() {
  final q = DergiQ({
    '2076-3417': ['APPLIED SCIENCES-BASEL', {'2024': 2}],
  });

  test('atıf yapan yayınlar türlere ayrılır', () {
    final s = OpenAlexServisi.siniflandir([
      _w('W10', issn: ['2076-3417']), // SCI (YÖK listesinde)
      _w('W11', issn: ['2076-3417'], atiflar: ['W1', 'W2', 'W99']), // 2 eser
      _w('W12', issn: ['1111-1111']), // listede yok → diğer uluslararası
      _w('W13', tur: 'book-chapter', kaynakTuru: 'ebook platform'), // kitap
      _w('W14', yazarlar: ['A9', 'A1']), // öz atıf
      _w('W15', kaynakTuru: 'repository'), // ön baskı → sayılmaz
      _w('W16', kaynakTuru: null, tur: 'dissertation'), // tez → sayılmaz
    ], 'A1', {'W1', 'W2'}, q);
    expect(s.sayilar, {'sci': 3, 'digerUlusAtif': 1, 'kitap': 1});
    expect(s.ozAtif, 1);
    expect(s.atlanan, 2);

    // Motor puanı: A1'de SCI 4, diğer 1, kitap 4 oran/atıf.
    final puan = HesaplamaMotoru.toplamHesapla(alan: 'A1', faaliyetler: [
      for (final e in s.sayilar.entries)
        {'kategori': 'atif', 'tur': e.key, 'adet': e.value}
    ]);
    expect(puan['atif'], closeTo((3 * 4 + 1 + 4) / 100 * 30, 1e-9));
  });

  test('AVES başlığından ad soyad', () {
    String? ad(String b) =>
        AvesServisi.adSoyad('<h1 class="page-header">$b <small></small></h1>');
    expect(ad('Doç. Dr.  AHMET SAYGILI'), 'Ahmet Saygılı');
    expect(ad('Prof. Dr. İBRAHİM ÖZTÜRK'), 'İbrahim Öztürk');
    expect(ad('Dr. Öğr. Üyesi ŞULE ÇAĞLAR'), 'Şule Çağlar');
  });
}
