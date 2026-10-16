import 'package:akademik_tesvik/aves_servisi.dart';
import 'package:akademik_tesvik/hesaplama_motoru.dart';
import 'package:flutter_test/flutter_test.dart';

String _satir(String kunye, {String tip = '', List<String> endeks = const []}) =>
    '<tr><td width="20">1.</td><td>$kunye<br>'
    '<span class="label label-warning">$tip</span> '
    '${endeks.map((e) => '<span class="label label-info" style="x">$e</span>').join(' ')}'
    '</td></tr>';

String _panel(String baslik, List<String> satirlar) =>
    '<div class="panel panel-default"><div class="panel-heading"><b>$baslik</b></div>'
    '<table>${satirlar.join()}</table></div>';

void main() {
  final html = [
    _panel('Uluslararası Hakemli Dergilerde Yayımlanan Makaleler', [
      _satir('A B,SAYGILI AHMET, Bir başlık, Applied Sciences, vol. 16, Eylül, 2025.',
          tip: 'Özgün Makale', endeks: ['SCI-Expanded']),
      // Aynı eserin soyadı değişmiş ortak yazarla tekrar kaydı → atlanır.
      _satir('A C,SAYGILI AHMET, Bir başlık, Applied Sciences, vol. 16, Eylül, 2025.',
          tip: 'Özgün Makale', endeks: ['SCI-Expanded']),
      _satir('SAYGILI AHMET, Başka, Bir ESCI Dergisi, vol. 2, 2025.',
          tip: 'Özgün Makale', endeks: ['ESCI']),
      _satir('SAYGILI AHMET, Mektup, Applied Sciences, vol. 1, 2025.',
          tip: 'Editöre Mektup', endeks: ['SCI-Expanded']),
    ]),
    _panel('Ulusal Hakemli Dergilerde Yayımlanan Makaleler', [
      _satir('X Y,SAYGILI AHMET, TR, Dergi, vol. 3, pp. 1-2, Aralık, 2024.',
          tip: 'Özgün Makale', endeks: ['TR DİZİN']),
      _satir('SAYGILI AHMET, Taranmıyor, Dergi, vol. 3, 2024.',
          tip: 'Özgün Makale', endeks: ['Endekste Taranmıyor']),
    ]),
    _panel('Uluslararası Kitaplar veya Kitap Bölümleri', [
      _satir('SAYGILI AHMET, KİTAP, Bölüm: Bölüm adı. Sayfa:1-9, Yayın Yeri: X, 2025.',
          tip: 'Bilimsel Kitap'),
    ]),
    _panel('Uluslararası Bilimsel Toplantılarda Sunulan ve Bildiri Kitaplarında '
        '(proceedings) Basılan Bildiriler', [
      _satir('K H,E M,SAYGILI AHMET, Bildiri, ICSAR 2025, 06.07.2025 - 07.07.2025.',
          tip: 'Tam metin bildiri'),
      _satir('SAYGILI AHMET, Özet, Konf, 01.01.2025.', tip: 'Özet bildiri'),
    ]),
    _panel('Yayın Hakemlikleri', [_satir('Symmetry, 2025, Hakemlik Sayısı:1.')]),
  ].join();

  final q = DergiQ({
    '2076-3417': [
      'APPLIED SCIENCES-BASEL',
      {'2023': 2, '2024': 3},
    ],
  });

  test('AVES yayınları teşvik faaliyetlerine dönüşür', () {
    final f = AvesServisi.ayristir(html, q);
    expect(f.map((e) => e['tur']).toList(), [
      'sciArastirma', 'alanEndeksi', 'ulakbim', 'kitapUlusBolum',
      'uluslararasiTeblig',
    ]);
    expect(f.map((e) => e['yil']).toList(), [2025, 2025, 2024, 2025, 2025]);
    expect(f.map((e) => e['kisi']).toList(), [2, 1, 2, 1, 3]);
    // 2025 listede yok → en yakın önceki yıl (2024: Q3)
    expect(f[0]['quartile'], 'Q3');
    expect(f[0]['qBulunamadi'], false);
    expect(f[0]['ahci'], false);
    expect(f[4]['kategori'], 'teblig');
  });

  test('Q bulunamazsa en alt katsayı', () {
    final f = AvesServisi.ayristir(html);
    expect(f[0]['quartile'], 'Q4');
    expect(f[0]['qBulunamadi'], true);
  });

  test('eklenen faaliyetler motor tarafından puanlanır', () {
    final f = AvesServisi.ayristir(html, q);
    final s = HesaplamaMotoru.toplamHesapla(alan: 'A1', faaliyetler: f);
    // 0,8 × 0,5 × 60 + 20 + 0,8 × 15 + 25 = 81 oran → 24,3 yayın puanı
    expect(s['yayin'], closeTo(81 / 100 * 30, 1e-9));
    // 0,6 × 15 = 9 oran → 1,8 tebliğ puanı
    expect(s['teblig'], closeTo(9 / 100 * 20, 1e-9));
  });

  test('CV adresi normalleştirilir', () {
    expect(AvesServisi.kokAdres('asaygili'), 'https://asaygili.cv.nku.edu.tr');
    expect(AvesServisi.kokAdres('http://asaygili.cv.nku.edu.tr/cv/yayinlar/'),
        'https://asaygili.cv.nku.edu.tr');
  });
}
