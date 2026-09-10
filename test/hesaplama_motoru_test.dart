// test/hesaplama_motoru_test.dart
//
// Akademik Teşvik Ödeneği Yönetmeliği hükümlerinin hesaplama motorunda
// doğru uygulandığını doğrulayan testler.

import 'package:flutter_test/flutter_test.dart';
import 'package:akademik_tesvik/hesaplama_motoru.dart';

double toplam(String alan, List<Map<String, dynamic>> f) =>
    HesaplamaMotoru.toplamHesapla(alan: alan, faaliyetler: f)['toplam']!;

double kategori(String alan, List<Map<String, dynamic>> f, String k) =>
    HesaplamaMotoru.toplamHesapla(alan: alan, faaliyetler: f)[k]!;

void main() {
  group('Tablo 1-2-3 katsayıları', () {
    test('(k) katsayısı kişi sayısına göre', () {
      expect(HesaplamaMotoru.kKatsayisi(1), 1.0);
      expect(HesaplamaMotoru.kKatsayisi(2), 0.8);
      expect(HesaplamaMotoru.kKatsayisi(3), 0.6);
      expect(HesaplamaMotoru.kKatsayisi(4), 0.45);
      expect(HesaplamaMotoru.kKatsayisi(5), closeTo(1 / 5, 0.0001));
      expect(HesaplamaMotoru.kKatsayisi(6), closeTo(1 / 6, 0.0001));
      expect(HesaplamaMotoru.kKatsayisi(9), closeTo(1 / 9, 0.0001));
    });

    test('(p) katsayısı; m.8/6 AHCI 0,5 ve Q yoksa en alt katsayı', () {
      expect(HesaplamaMotoru.pKatsayisi('Q1', false), 1.0);
      expect(HesaplamaMotoru.pKatsayisi('Q2', false), 0.8);
      expect(HesaplamaMotoru.pKatsayisi('Q3', false), 0.5);
      expect(HesaplamaMotoru.pKatsayisi('Q4', false), 0.25);
      expect(HesaplamaMotoru.pKatsayisi('Q1', true), 0.5);
      expect(HesaplamaMotoru.pKatsayisi('', false), 0.25);
    });

    test('(r) katsayısı projedeki role göre', () {
      expect(HesaplamaMotoru.rKatsayisi('Yürütücü'), 1.0);
      expect(HesaplamaMotoru.rKatsayisi('Araştırmacı'), 0.5);
    });
  });

  group('m.8/2-a ve m.8/3 puan hesabı', () {
    test('oranlar toplamı × tür puanı', () {
      // A1, 3 yazarlı Q1 araştırma makalesi × 2 → 0,6 × 1 × 60 × 2 = %72
      expect(
        kategori('A1', [
          {
            'kategori': 'yayin',
            'tur': 'sciArastirma',
            'kisi': 3,
            'adet': 2,
            'quartile': 'Q1'
          }
        ], 'yayin'),
        closeTo(21.6, 0.001),
      );
      // A2, SCI kapsamında 15 atıf → 6 × 15 = %90 → tavan 30 × 0,90
      expect(
        kategori('A2', [
          {'kategori': 'atif', 'tur': 'sci', 'adet': 15}
        ], 'atif'),
        closeTo(27.0, 0.001),
      );
    });

    test('faaliyet türü puanı tavanı geçemez', () {
      expect(
        kategori('A1', [
          {
            'kategori': 'yayin',
            'tur': 'sciArastirma',
            'adet': 5,
            'quartile': 'Q1'
          }
        ], 'yayin'),
        30.0,
      );
    });

    test('akademik teşvik puanı yüzü geçemez', () {
      expect(
        toplam('A1', [
          {'kategori': 'yayin', 'tur': 'sciArastirma', 'adet': 20},
          {'kategori': 'atif', 'tur': 'sci', 'adet': 100},
          {'kategori': 'patent', 'tur': 'uluslararasi', 'adet': 5},
          {'kategori': 'teblig', 'adet': 20},
          {'kategori': 'proje', 'tur': 'H2020', 'rol': 'Yürütücü', 'adet': 3},
        ]),
        100.0,
      );
    });
  });

  group('m.7/4 editörlük', () {
    test('sabit oranlı satırlar adetle çarpılmaz', () {
      expect(
        HesaplamaMotoru.yayinPuani(
            tur: 'editSciExpanded', alan: 'A1', adet: 5),
        25.0,
      );
      expect(
        HesaplamaMotoru.yayinPuani(tur: 'sesKisiselUlus', alan: 'A4', adet: 4),
        20.0,
      );
    });

    test('farklı dergilerde de olsa yalnızca bir editörlük sayılır', () {
      // 25 + 15 + 10 değil, yalnızca en yüksek olan 25 → %25 → 7,5 puan
      expect(
        kategori('A1', [
          {'kategori': 'yayin', 'tur': 'editSciExpanded'},
          {'kategori': 'yayin', 'tur': 'editAlan'},
          {'kategori': 'yayin', 'tur': 'editUlakbim'},
        ], 'yayin'),
        closeTo(7.5, 0.001),
      );
    });

    test('editörlük diğer yayınlarla birlikte toplanır', () {
      // editAlan %15 + Q1 makale %60 = %75 → 22,5 puan
      expect(
        kategori('A1', [
          {'kategori': 'yayin', 'tur': 'editAlan'},
          {'kategori': 'yayin', 'tur': 'sciArastirma', 'quartile': 'Q1'},
        ], 'yayin'),
        closeTo(22.5, 0.001),
      );
    });
  });

  group('m.8/7 oran / kişi sayısı', () {
    test('tasarım kişi sayısına bölünür', () {
      expect(HesaplamaMotoru.tasarimPuani(kisi: 3), closeTo(5.0, 0.001));
      expect(HesaplamaMotoru.tasarimPuani(adet: 2), 30.0);
    });

    test('ödül kişi sayısına bölünür', () {
      expect(
        HesaplamaMotoru.odulPuani(tur: 'yurtdisiBilim', alan: 'A1', kisi: 2),
        20.0,
      );
    });

    test('karma sergi etkinliği kişi sayısına bakılmaksızın tam puan alır',
        () {
      expect(
        HesaplamaMotoru.sergiPuani(tur: 'yurtdisiGrup', alan: 'A4', kisi: 5),
        15.0,
      );
    });
  });

  group('m.7/6 sergide tekrarlayan faaliyet', () {
    test('ilk etkinlik tam, ikinci tekrar yarım, sonrası sayılmaz', () {
      expect(
        HesaplamaMotoru.sergiPuani(
            tur: 'yurtdisiBireysel', alan: 'A4', tekrar: 1),
        30.0,
      );
      expect(
        HesaplamaMotoru.sergiPuani(
            tur: 'yurtdisiBireysel', alan: 'A4', tekrar: 2),
        15.0,
      );
      expect(
        HesaplamaMotoru.sergiPuani(
            tur: 'yurtdisiBireysel', alan: 'A4', tekrar: 3),
        0.0,
      );
    });
  });

  group('Tablo 4 alan kısıtları', () {
    test('sergi ve ses/görüntü kaydı yalnızca A4 alanında puanlanır', () {
      expect(
        HesaplamaMotoru.sergiPuani(tur: 'yurtdisiBireysel', alan: 'A1'),
        0.0,
      );
      expect(
        HesaplamaMotoru.yayinPuani(tur: 'sesKisiselUlus', alan: 'A1'),
        0.0,
      );
    });

    test('güzel sanat atıfları yalnızca A4, mimarlık ödülü yalnızca A3', () {
      expect(
        HesaplamaMotoru.atifPuani(tur: 'guzelUlus', alan: 'A1', adet: 5),
        0.0,
      );
      expect(HesaplamaMotoru.odulPuani(tur: 'mimarlik', alan: 'A3'), 20.0);
      expect(HesaplamaMotoru.odulPuani(tur: 'mimarlik', alan: 'A1'), 0.0);
    });

    test('açıklama metni ile hesaplanan puan hiçbir alanda çelişmez', () {
      final ornekler = <Map<String, dynamic>>[
        {'kategori': 'sergi', 'tur': 'yurtdisiBireysel', 'tekrar': 1},
        {'kategori': 'atif', 'tur': 'guzelUlus', 'adet': 3},
        {'kategori': 'yayin', 'tur': 'sesKisiselUlus', 'adet': 2},
        {'kategori': 'odul', 'tur': 'mimarlik'},
        {'kategori': 'arastirma', 'tur': 'yurtdisi', 'ay': 3},
      ];
      for (final f in ornekler) {
        for (final alan in ['A1', 'A2', 'A3', 'A4']) {
          final oran = HesaplamaMotoru.faaliyetOrani(f: f, alan: alan);
          final metin = HesaplamaMotoru.puanAciklamasi(f: f, alan: alan);
          expect(metin.contains('0,00 puan'), oran == 0,
              reason: '${f['kategori']}/${f['tur']} · $alan · oran=$oran');
        }
      }
    });
  });

  group('m.3/ş araştırma alt sınırı', () {
    test('dört aydan kısa araştırma değerlendirilmez', () {
      expect(HesaplamaMotoru.arastirmaPuani(tur: 'yurtdisi', ay: 3), 0.0);
      expect(HesaplamaMotoru.arastirmaPuani(tur: 'yurtdisi', ay: 4), 60.0);
      expect(HesaplamaMotoru.arastirmaPuani(tur: 'yurtici', ay: 6), 60.0);
    });
  });

  group('m.10/3 ve m.8/1 ödeme', () {
    test('otuz puanın altında ödeme yapılmaz', () {
      expect(
        HesaplamaMotoru.odemeHesapla(
            tesvikPuani: 29.99,
            unvan: 'Profesör',
            enYuksekBrutAylik: 14967.36),
        0.0,
      );
      expect(
        HesaplamaMotoru.odemeHesapla(
            tesvikPuani: 30,
            unvan: 'Profesör',
            enYuksekBrutAylik: 14967.36),
        closeTo(14967.36 * 0.30, 0.001),
      );
    });

    test('unvan oranları', () {
      const brut = 14967.36;
      expect(
        HesaplamaMotoru.odemeHesapla(
            tesvikPuani: 100, unvan: 'Profesör', enYuksekBrutAylik: brut),
        closeTo(brut, 0.001),
      );
      expect(
        HesaplamaMotoru.odemeHesapla(
            tesvikPuani: 100, unvan: 'Doçent', enYuksekBrutAylik: brut),
        closeTo(brut * 0.90, 0.001),
      );
      expect(
        HesaplamaMotoru.odemeHesapla(
            tesvikPuani: 100,
            unvan: 'Dr. Öğr. Üyesi',
            enYuksekBrutAylik: brut),
        closeTo(brut * 0.80, 0.001),
      );
      expect(
        HesaplamaMotoru.odemeHesapla(
            tesvikPuani: 100,
            unvan: 'Araştırma Görevlisi',
            enYuksekBrutAylik: brut),
        closeTo(brut * 0.70, 0.001),
      );
      expect(
        HesaplamaMotoru.odemeHesapla(
            tesvikPuani: 100,
            unvan: 'Öğretim Görevlisi',
            enYuksekBrutAylik: brut),
        closeTo(brut * 0.70, 0.001),
      );
    });
  });

  group('Dayanıklılık', () {
    test('alanları eksik eski kayıtlar hata vermez ve puan üretmez', () {
      expect(
        toplam('A1', [
          {'kategori': 'arastirma'},
          {'kategori': 'proje'},
          {'kategori': 'yayin'},
          {'kategori': 'bilinmeyen'},
          <String, dynamic>{},
        ]),
        0.0,
      );
    });
  });
}
