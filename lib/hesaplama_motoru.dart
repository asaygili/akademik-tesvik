// lib/hesaplama_motoru.dart
//
// Akademik Teşvik Ödeneği Yönetmeliği (14/5/2018 tarihli ve 2018/11834 sayılı
// Bakanlar Kurulu Kararı; 16/1/2020 tarihli ve 2043 sayılı Cumhurbaşkanı Kararı
// ile değişik) esas alınarak hazırlanmıştır.

import 'bicim.dart';

class HesaplamaMotoru {
  // ── SABİTLER ────────────────────────────────────────────────

  /// Yönetmelik m.10/3: ödeme yapılabilmesi için gereken en az teşvik puanı.
  static const double enAzTesvikPuani = 30;

  /// Yönetmelik m.3/ç: aylık gösterge (1.500) + ek gösterge (8.000).
  static const double gostergeToplami = 9500;

  /// Yönetmelik m.7/4: farklı dergilerde de olsa yalnızca bir editörlük
  /// dikkate alınır. Bu türler toplama tek seferde (en yükseği) katılır.
  static const Set<String> editorlukTurleri = {
    'editSciExpanded',
    'editAlan',
    'editDigerUlus',
    'editUlakbim',
  };

  /// Tablo 4'te tek bir faaliyet için sabit oran öngörülen yayın türleri;
  /// bunlar adet ile çarpılmaz.
  static const Set<String> sabitPuanliYayinTurleri = {
    'editSciExpanded',
    'editAlan',
    'editDigerUlus',
    'editUlakbim',
    'sesKisiselUlus',
    'sesKarmaUlus',
    'sesKisiselUlus2',
  };

  /// Yönetmelik m.8/4: (k) katsayısının uygulandığı çok isimli yayın türleri.
  static const Set<String> kKatsayiliYayinTurleri = {
    'sciArastirma',
    'sciDerleme',
    'alanEndeksi',
    'digerUlus',
    'ulakbim',
    'kitapUlusYazar',
    'kitapUlusEditor',
    'kitapUlusBolum',
  };

  /// Tablo 4'teki akademik faaliyet türü puanları (tavanlar).
  static const Map<String, double> tavanlar = {
    'proje': 20,
    'arastirma': 15,
    'yayin': 30,
    'patent': 30,
    'atif': 30,
    'teblig': 20,
    'odul': 20,
    'sergi': 15,
    'tasarim': 15,
  };

  // ── KATSAYILAR ──────────────────────────────────────────────

  /// Tablo 1: (k) katsayısı.
  static double kKatsayisi(int kisiSayisi) {
    if (kisiSayisi <= 1) return 1.0;
    if (kisiSayisi == 2) return 0.8;
    if (kisiSayisi == 3) return 0.6;
    if (kisiSayisi == 4) return 0.45;
    return 1 / kisiSayisi;
  }

  /// Tablo 3: (p) katsayısı. m.8/6: AHCI kapsamındaki dergiler için 0,5;
  /// Q değeri belirlenmemiş dergiler için en alt katsayı uygulanır.
  static double pKatsayisi(String quartile, bool ahci) {
    if (ahci) return 0.5;
    switch (quartile) {
      case 'Q1': return 1.0;
      case 'Q2': return 0.8;
      case 'Q3': return 0.5;
      case 'Q4': return 0.25;
      default:   return 0.25;
    }
  }

  /// Tablo 2: (r) katsayısı.
  static double rKatsayisi(String rol) =>
      rol == 'Yürütücü' ? 1.0 : 0.5;

  // ── PROJE ────────────────────────────────────────────────────

  /// Tablo 4'teki proje satırının (r uygulanmadan önceki) temel oranı.
  static double projeCarpani(String tur) {
    switch (tur) {
      case 'H2020':    return 100;
      case '1001':     return 80;
      case '1005':     return 70;
      case 'ulusUzel': return 40;
      case 'ulusOzel': return 20;
      default:         return 0;
    }
  }

  static double projePuani({
    required String tur,
    required String rol,
    required int adet,
  }) =>
      rKatsayisi(rol) * projeCarpani(tur) * adet;

  // ── ARAŞTIRMA ────────────────────────────────────────────────
  /// m.3/ş: araştırma en az dört ay süreli görevlendirmeyi gerektirir.
  static double arastirmaPuani({required String tur, required int ay}) {
    if (ay < 4) return 0;
    double carpan = tur == 'yurtdisi' ? 15.0 : 10.0;
    return carpan * ay;
  }

  // ── YAYIN ────────────────────────────────────────────────────

  /// Tablo 4'teki yayın satırının (k ve p uygulanmadan önceki) temel oranı.
  static double yayinCarpani(String tur, String alan) {
    bool a2a4 = alan == 'A2' || alan == 'A4';
    switch (tur) {
      case 'sciArastirma':    return a2a4 ? 80 : 60;
      case 'sciDerleme':      return a2a4 ? 40 : 30;
      case 'alanEndeksi':     return a2a4 ? 25 : 20;
      case 'digerUlus':       return a2a4 ? 20 : 15;
      case 'ulakbim':         return a2a4 ? 20 : 15;
      case 'editSciExpanded': return 25;
      case 'editAlan':        return 15;
      case 'editDigerUlus':   return 10;
      case 'editUlakbim':     return 10;
      case 'kitapUlusYazar':  return 100;
      case 'kitapUlusEditor': return 60;
      case 'kitapUlusBolum':  return 25;
      // Ses ve/veya görüntü kaydı satırları yalnızca A4 alanında puanlanır.
      case 'sesKisiselUlus':  return alan == 'A4' ? 20 : 0;
      case 'sesKarmaUlus':    return alan == 'A4' ? 10 : 0;
      case 'sesKisiselUlus2': return alan == 'A4' ? 10 : 0;
      default:                return 0;
    }
  }

  static double yayinPuani({
    required String tur,
    required String alan,
    int kisi = 1,
    int adet = 1,
    String quartile = 'Q1',
    bool ahci = false,
  }) {
    double carpan = yayinCarpani(tur, alan);
    if (carpan == 0) return 0;

    double birimPuan;
    if (tur == 'sciArastirma' || tur == 'sciDerleme') {
      birimPuan = kKatsayisi(kisi) * pKatsayisi(quartile, ahci) * carpan;
    } else if (kKatsayiliYayinTurleri.contains(tur)) {
      birimPuan = kKatsayisi(kisi) * carpan;
    } else {
      birimPuan = carpan;
    }

    // Sabit oranlı satırlar (editörlük, ses/görüntü kaydı) adetle çarpılmaz.
    return sabitPuanliYayinTurleri.contains(tur) ? birimPuan : birimPuan * adet;
  }

  // ── PATENT ───────────────────────────────────────────────────
  static double patentPuani({
    required String tur,
    required int kisi,
    required int adet,
  }) {
    double k = kKatsayisi(kisi);
    double birim = tur == 'uluslararasi' ? k * 100 : k * 60;
    return birim * adet;
  }

  // ── ATIF ─────────────────────────────────────────────────────
  /// m.7/8: atıfların değerlendirilmesinde kişi sayısı dikkate alınmaz.
  static double atifBirimi({required String tur, required String alan}) {
    bool a2a4 = alan == 'A2' || alan == 'A4';
    switch (tur) {
      case 'sci':       return a2a4 ? 6   : 4;
      case 'alan':      return a2a4 ? 3   : 1.5;
      case 'digerUlus':
      case 'digerUlusAtif': return a2a4 ? 2 : 1;
      case 'ulakbim':   return a2a4 ? 2   : 1;
      case 'kitap':     return a2a4 ? 8   : 4;
      // Güzel sanat eserleri satırları yalnızca A4 alanında puanlanır.
      case 'guzelUlus': return alan == 'A4' ? 8 : 0;
      case 'guzelUlus2':return alan == 'A4' ? 4 : 0;
      default:          return 0;
    }
  }

  static double atifPuani({
    required String tur,
    required String alan,
    required int adet,
  }) =>
      atifBirimi(tur: tur, alan: alan) * adet;

  // ── TEBLİĞ ───────────────────────────────────────────────────
  static double tebligPuani({required int kisi, required int adet}) =>
      kKatsayisi(kisi) * 15 * adet;

  // ── ÖDÜL ─────────────────────────────────────────────────────

  /// Tablo 4'teki ödül satırının oranı (kişi sayısına bölünmeden önce).
  static double odulBirimi({required String tur, required String alan}) {
    switch (tur) {
      case 'yokTez':        return 100;
      case 'tubitakBilim':  return 100;
      case 'tubaAkademi':   return 100;
      case 'yurtdisiBilim': return 40;
      case 'yurticiiBilim': return 20;
      case 'guzelUlusJuri': return alan == 'A4' ? 40 : 0;
      case 'guzelUlasJuri': return alan == 'A4' ? 20 : 0;
      case 'mimarlik':      return alan == 'A3' ? 20 : 0;
      default:              return 0;
    }
  }

  /// m.8/7: özel bir paylaşım oranı veya isim sıralaması bulunmayan
  /// faaliyetler için "oran/kişi sayısı" dikkate alınır.
  static double odulPuani({
    required String tur,
    required String alan,
    int kisi = 1,
  }) =>
      odulBirimi(tur: tur, alan: alan) / (kisi < 1 ? 1 : kisi);

  // ── SERGİ ────────────────────────────────────────────────────

  static double sergiBirimi(String tur) {
    switch (tur) {
      case 'yurtdisiBireysel': return 30;
      case 'yurticiiBireysel': return 15;
      case 'yurtdisiGrup':     return 15;
      case 'yurticiiGrup':     return 8;
      default:                 return 0;
    }
  }

  /// Sergi faaliyet türü yalnızca A4 alanında puanlanır.
  /// m.7/6: tekrarlayan faaliyetler için en çok iki etkinlik dikkate alınır ve
  /// ikinci tekrar etkinliğe öncekinin puanının yarısı verilir.
  /// m.8/7: karma etkinlikler kişi sayısına bakılmaksızın tam puan alır.
  static double sergiPuani({
    required String tur,
    required String alan,
    int tekrar = 1,
    int kisi = 1,
  }) {
    if (alan != 'A4') return 0;
    double birim = sergiBirimi(tur);
    if (birim == 0) return 0;

    bool karma = tur == 'yurtdisiGrup' || tur == 'yurticiiGrup';
    if (!karma && kisi > 1) birim = birim / kisi;

    if (tekrar <= 1) return birim;
    if (tekrar == 2) return birim / 2;
    return 0; // İkinciden sonraki tekrar etkinlikler dikkate alınmaz.
  }

  // ── TASARIM ──────────────────────────────────────────────────
  /// m.8/7: paylaşım oranı bulunmadığından oran kişi sayısına bölünür.
  static double tasarimPuani({int kisi = 1, int adet = 1}) =>
      (15.0 / (kisi < 1 ? 1 : kisi)) * adet;

  // ── FAALİYET ORANI (tek bir kaydın Tablo 4 oranı) ────────────
  static double faaliyetOrani({
    required Map<String, dynamic> f,
    required String alan,
  }) {
    final String kategori = (f['kategori'] as String?) ?? '';
    final String tur = (f['tur'] as String?) ?? '';
    final String rol = (f['rol'] as String?) ?? 'Yürütücü';
    final int kisi = (f['kisi'] as num?)?.toInt() ?? 1;
    final int adet = (f['adet'] as num?)?.toInt() ?? 1;
    final int ay = (f['ay'] as num?)?.toInt() ?? 0;
    final int tekrar = (f['tekrar'] as num?)?.toInt() ?? 1;
    final String quartile = (f['quartile'] as String?) ?? 'Q1';
    final bool ahci = f['ahci'] == true;

    switch (kategori) {
      case 'proje':
        return projePuani(tur: tur, rol: rol, adet: adet);
      case 'arastirma':
        return arastirmaPuani(tur: tur, ay: ay);
      case 'yayin':
        return yayinPuani(
          tur: tur, alan: alan, kisi: kisi,
          adet: adet, quartile: quartile, ahci: ahci,
        );
      case 'patent':
        return patentPuani(tur: tur, kisi: kisi, adet: adet);
      case 'atif':
        return atifPuani(tur: tur, alan: alan, adet: adet);
      case 'teblig':
        return tebligPuani(kisi: kisi, adet: adet);
      case 'odul':
        return odulPuani(tur: tur, alan: alan, kisi: kisi);
      case 'sergi':
        return sergiPuani(tur: tur, alan: alan, tekrar: tekrar, kisi: kisi);
      case 'tasarim':
        return tasarimPuani(kisi: kisi, adet: adet);
      default:
        return 0;
    }
  }

  // ── PUAN AÇIKLAMASI (her faaliyet için formül metni) ─────────
  static String puanAciklamasi({
    required Map<String, dynamic> f,
    required String alan,
  }) {
    final String kategori = (f['kategori'] as String?) ?? '';
    final String tur = (f['tur'] as String?) ?? '';
    final String rol = (f['rol'] as String?) ?? 'Yürütücü';
    final int kisi = (f['kisi'] as num?)?.toInt() ?? 1;
    final int adet = (f['adet'] as num?)?.toInt() ?? 1;
    final int ay = (f['ay'] as num?)?.toInt() ?? 0;
    final int tekrar = (f['tekrar'] as num?)?.toInt() ?? 1;
    final String quartile = (f['quartile'] as String?) ?? 'Q1';
    final bool ahci = f['ahci'] == true;

    final double k = kKatsayisi(kisi);
    final double p = pKatsayisi(quartile, ahci);
    final double r = rKatsayisi(rol);

    // Oran, puanlamada kullanılan fonksiyonların ta kendisinden alınır; böylece
    // açıklama metni ile sonuç tablosu hiçbir durumda çelişmez.
    final double oran = faaliyetOrani(f: f, alan: alan);

    String gosterim(String formul) {
      final double tavan = tavanlar[kategori] ?? 0;
      final double gercekPuan = oran / 100 * tavan;
      return '$formul = ${Bicim.oran(oran)} oran; '
          '${Bicim.oran(oran)} × ${Bicim.sayi(tavan, basamak: 0)} (tavan) = '
          '${Bicim.puan(gercekPuan)} puan';
    }

    // Oran sıfırsa nedenini açıkça yaz.
    if (oran == 0) {
      if (kategori == 'arastirma') {
        return 'Dört aydan kısa araştırmalar değerlendirmeye alınmaz '
            '(m.3/ş): 0,00 puan';
      }
      if (kategori == 'sergi' && tekrar > 2) {
        return 'Tekrarlayan faaliyetlerde en çok iki etkinlik dikkate alınır '
            '(m.7/6): 0,00 puan';
      }
      return 'Bu faaliyet türü seçilen bilim alanında ($alan) '
          'puanlanmaz: 0,00 puan';
    }

    switch (kategori) {
      case 'yayin':
        final double carpan = yayinCarpani(tur, alan);
        if (tur == 'sciArastirma' || tur == 'sciDerleme') {
          return gosterim(
              'k($kisi)=${Bicim.sayi(k)} × p(${ahci ? "AHCI" : quartile})='
              '${Bicim.sayi(p)} × ${Bicim.sayi(carpan, basamak: 0)} × '
              '$adet adet');
        }
        if (editorlukTurleri.contains(tur)) {
          return gosterim('Sabit ${Bicim.sayi(carpan, basamak: 0)} oran '
              '(m.7/4: yalnızca bir editörlük sayılır)');
        }
        if (sabitPuanliYayinTurleri.contains(tur)) {
          return gosterim('Sabit ${Bicim.sayi(carpan, basamak: 0)} oran');
        }
        return gosterim('k($kisi)=${Bicim.sayi(k)} × '
            '${Bicim.sayi(carpan, basamak: 0)} × $adet adet');

      case 'atif':
        final double birim = atifBirimi(tur: tur, alan: alan);
        return gosterim(
            '${Bicim.sayi(birim, basamak: 1)} oran/atıf × $adet atıf');

      case 'teblig':
        return gosterim('k($kisi)=${Bicim.sayi(k)} × 15 × $adet adet');

      case 'proje':
        return gosterim('r($rol)=${Bicim.sayi(r, basamak: 1)} × '
            '${Bicim.sayi(projeCarpani(tur), basamak: 0)} × $adet adet');

      case 'arastirma':
        final double carpan = tur == 'yurtdisi' ? 15 : 10;
        return gosterim(
            '${Bicim.sayi(carpan, basamak: 0)} × $ay ay');

      case 'patent':
        final int carpan = tur == 'uluslararasi' ? 100 : 60;
        return gosterim(
            'k($kisi)=${Bicim.sayi(k)} × $carpan × $adet adet');

      case 'odul':
        final double birim = odulBirimi(tur: tur, alan: alan);
        if (kisi > 1) {
          return gosterim(
              '${Bicim.sayi(birim, basamak: 0)} oran / $kisi kişi (m.8/7)');
        }
        return gosterim('Sabit ${Bicim.sayi(birim, basamak: 0)} oran');

      case 'sergi':
        final double birim = sergiBirimi(tur);
        final List<String> parcalar = [
          '${Bicim.sayi(birim, basamak: 0)} oran'
        ];
        final bool karma = tur == 'yurtdisiGrup' || tur == 'yurticiiGrup';
        if (kisi > 1) {
          parcalar.add(karma
              ? 'karma etkinlik: kişi sayısına bakılmaz (m.8/7)'
              : '/ $kisi kişi (m.8/7)');
        }
        if (tekrar == 2) parcalar.add('× 1/2 (ikinci tekrar etkinlik, m.7/6)');
        return gosterim(parcalar.join(' '));

      case 'tasarim':
        if (kisi > 1) {
          return gosterim('15 oran / $kisi kişi (m.8/7) × $adet adet');
        }
        return gosterim('Sabit 15 × $adet adet');

      default:
        return '-';
    }
  }

  // ── TOPLAM ───────────────────────────────────────────────────
  static Map<String, double> toplamHesapla({
    required String alan,
    required List<Map<String, dynamic>> faaliyetler,
  }) {
    final Map<String, double> oranlar = {
      for (final anahtar in tavanlar.keys) anahtar: 0.0
    };

    // m.7/4: farklı dergilerde de olsa yalnızca bir editörlük dikkate alınır;
    // birden fazla editörlük girilmişse en yüksek oranlı olan sayılır.
    double enYuksekEditorluk = 0;

    for (final f in faaliyetler) {
      final String kategori = (f['kategori'] as String?) ?? '';
      if (!oranlar.containsKey(kategori)) continue;

      final double oran = faaliyetOrani(f: f, alan: alan);

      if (kategori == 'yayin' &&
          editorlukTurleri.contains((f['tur'] as String?) ?? '')) {
        if (oran > enYuksekEditorluk) enYuksekEditorluk = oran;
        continue;
      }

      oranlar[kategori] = oranlar[kategori]! + oran;
    }

    oranlar['yayin'] = oranlar['yayin']! + enYuksekEditorluk;

    double toplamPuan = 0;
    final Map<String, double> sonuc = {};
    oranlar.forEach((anahtar, oran) {
      final double tavan = tavanlar[anahtar] ?? 0;
      final double puanTavanli = (oran / 100 * tavan).clamp(0, tavan);
      sonuc[anahtar] = puanTavanli;
      toplamPuan += puanTavanli;
    });
    sonuc['toplam'] = toplamPuan.clamp(0, 100);
    return sonuc;
  }

  // ── ÖDEME ────────────────────────────────────────────────────
  static double odemeHesapla({
    required double tesvikPuani,
    required String unvan,
    required double enYuksekBrutAylik,
  }) {
    // m.10/3: akademik teşvik ödeneğinin ödenebilmesi için akademik teşvik
    // puanının en az otuz olması gerekir.
    if (tesvikPuani < enAzTesvikPuani) return 0;

    double oran;
    switch (unvan) {
      case 'Profesör':            oran = 1.00; break;
      case 'Doçent':              oran = 0.90; break;
      case 'Dr. Öğr. Üyesi':      oran = 0.80; break;
      case 'Araştırma Görevlisi':
      case 'Öğretim Görevlisi':   oran = 0.70; break;
      default:                    oran = 0.70;
    }
    return enYuksekBrutAylik * oran * (tesvikPuani / 100);
  }
}
