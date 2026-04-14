// lib/hesaplama_motoru.dart

class HesaplamaMotoru {
  // ── KATSAYILAR ──────────────────────────────────────────────

  static double kKatsayisi(int kisiSayisi) {
    if (kisiSayisi == 1) return 1.0;
    if (kisiSayisi == 2) return 0.8;
    if (kisiSayisi == 3) return 0.6;
    if (kisiSayisi == 4) return 0.45;
    if (kisiSayisi == 5) return 1 / 5;
    if (kisiSayisi == 6) return 1 / 6;
    return 1 / kisiSayisi;
  }

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

  static double rKatsayisi(String rol) =>
      rol == 'Yürütücü' ? 1.0 : 0.5;

  // ── PUAN AÇIKLAMASI (her faaliyet için formül metni) ─────────
  static String puanAciklamasi({
    required Map<String, dynamic> f,
    required String alan,
  }) {
    String kategori = f['kategori'];
    int kisi = f['kisi'] ?? 1;
    int adet = f['adet'] ?? 1;
    String tur = f['tur'] ?? '';
    String quartile = f['quartile'] ?? 'Q1';
    bool ahci = f['ahci'] ?? false;
    String rol = f['rol'] ?? 'Yürütücü';
    int ay = f['ay'] ?? 4;

    double k = kKatsayisi(kisi);
    double p = pKatsayisi(quartile, ahci);
    double r = rKatsayisi(rol);
    bool a2a4 = alan == 'A2' || alan == 'A4';

    // Tavan değerleri
    const Map<String, double> tavanlar = {
      'proje': 20, 'arastirma': 15, 'yayin': 30,
      'patent': 30, 'atif': 30, 'teblig': 20,
      'odul': 20, 'sergi': 15, 'tasarim': 15,
    };

    String _gosterim(double oran, String formul) {
      double tavan = tavanlar[kategori] ?? 0;
      double gercekPuan = (oran / 100 * tavan);
      return '$formul = %${oran.toStringAsFixed(2)} oran → '
          '${oran.toStringAsFixed(2)}/100 × ${tavan.toStringAsFixed(0)} (tavan) = '
          '${gercekPuan.toStringAsFixed(2)} puan';
    }

    switch (kategori) {
      case 'yayin':
        switch (tur) {
          case 'sciArastirma':
            int carpan = a2a4 ? 80 : 60;
            double oran = k * p * carpan * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × p(${ahci ? "AHCI" : quartile})=${p.toStringAsFixed(2)} × $carpan × $adet adet');
          case 'sciDerleme':
            int carpan = a2a4 ? 40 : 30;
            double oran = k * p * carpan * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × p(${ahci ? "AHCI" : quartile})=${p.toStringAsFixed(2)} × $carpan × $adet adet');
          case 'alanEndeksi':
            int carpan = a2a4 ? 25 : 20;
            double oran = k * carpan * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × $carpan × $adet adet');
          case 'digerUlus':
            int carpan = a2a4 ? 20 : 15;
            double oran = k * carpan * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × $carpan × $adet adet');
          case 'ulakbim':
            int carpan = a2a4 ? 20 : 15;
            double oran = k * carpan * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × $carpan × $adet adet');
          case 'editSciExpanded':
            return _gosterim(25, 'Sabit 25 oran (tek editörlük)');
          case 'editAlan':
            return _gosterim(15, 'Sabit 15 oran (tek editörlük)');
          case 'editDigerUlus':
            return _gosterim(10, 'Sabit 10 oran (tek editörlük)');
          case 'editUlakbim':
            return _gosterim(10, 'Sabit 10 oran (tek editörlük)');
          case 'kitapUlusYazar':
            double oran = k * 100 * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × 100 × $adet adet');
          case 'kitapUlusEditor':
            double oran = k * 60 * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × 60 × $adet adet');
          case 'kitapUlusBolum':
            double oran = k * 25 * adet;
            return _gosterim(oran,
                'k($kisi)=${k.toStringAsFixed(2)} × 25 × $adet adet');
          case 'sesKisiselUlus':
            return _gosterim(20, 'Sabit 20 oran');
          case 'sesKarmaUlus':
            return _gosterim(10, 'Sabit 10 oran');
          case 'sesKisiselUlus2':
            return _gosterim(10, 'Sabit 10 oran');
          default: return '-';
        }

      case 'atif':
        bool aa = alan == 'A2' || alan == 'A4';
        Map<String, double> birimler = {
          'sci': aa ? 6 : 4,
          'alan': aa ? 3 : 1.5,
          'digerUlusAtif': aa ? 2 : 1,
          'ulakbim': aa ? 2 : 1,
          'kitap': aa ? 8 : 4,
          'guzelUlus': 8,
          'guzelUlus2': 4,
        };
        double birimAtif = birimler[tur] ?? 0;
        double oranAtif = birimAtif * adet;
        return _gosterim(oranAtif,
            '${birimAtif.toStringAsFixed(1)} oran/atıf × $adet atıf');

      case 'teblig':
        double oranT = k * 15 * adet;
        return _gosterim(oranT,
            'k($kisi)=${k.toStringAsFixed(2)} × 15 × $adet adet');

      case 'proje':
        Map<String, double> oranlar = {
          'H2020': 100, '1001': 80, '1005': 70,
          'ulusUzel': 40, 'ulusOzel': 20,
        };
        double carpanP = oranlar[tur] ?? 0;
        double oranP = r * carpanP * adet;
        return _gosterim(oranP,
            'r($rol)=${r.toStringAsFixed(1)} × ${carpanP.toStringAsFixed(0)} × $adet adet');

      case 'arastirma':
        double carpanA = tur == 'yurtdisi' ? 15 : 10;
        double oranA = carpanA * ay;
        return _gosterim(oranA,
            '${carpanA.toStringAsFixed(0)} × $ay ay');

      case 'patent':
        int carpanPat = tur == 'uluslararasi' ? 100 : 60;
        double oranPat = k * carpanPat * adet;
        return _gosterim(oranPat,
            'k($kisi)=${k.toStringAsFixed(2)} × $carpanPat × $adet adet');

      case 'odul':
        Map<String, double> odulPuanlar = {
          'yokTez': 100, 'tubitakBilim': 100, 'tubaAkademi': 100,
          'yurtdisiBilim': 40, 'yurticiiBilim': 20,
          'guzelUlusJuri': 40, 'guzelUlasJuri': 20, 'mimarlik': 20,
        };
        double odulOran = odulPuanlar[tur] ?? 0;
        return _gosterim(odulOran, 'Sabit ${odulOran.toStringAsFixed(0)} oran');

      case 'sergi':
        Map<String, double> sergiPuanlar = {
          'yurtdisiBireysel': 30, 'yurticiiBireysel': 15,
          'yurtdisiGrup': 15, 'yurticiiGrup': 8,
        };
        double sergiOran = sergiPuanlar[tur] ?? 0;
        return _gosterim(sergiOran, 'Sabit ${sergiOran.toStringAsFixed(0)} oran');

      case 'tasarim':
        double oranTas = 15.0 * adet;
        return _gosterim(oranTas, 'Sabit 15 × $adet adet');

      default:
        return '-';
    }
  }

  // ── PROJE ────────────────────────────────────────────────────
  static double projePuani({
    required String tur,
    required String rol,
    required int adet,
  }) {
    double r = rKatsayisi(rol);
    double oran;
    switch (tur) {
      case 'H2020':    oran = r * 100; break;
      case '1001':     oran = r * 80;  break;
      case '1005':     oran = r * 70;  break;
      case 'ulusUzel': oran = r * 40;  break;
      case 'ulusOzel': oran = r * 20;  break;
      default:         oran = 0;
    }
    return oran * adet;
  }

  // ── ARAŞTIRMA ────────────────────────────────────────────────
  static double arastirmaPuani({required String tur, required int ay}) {
    if (ay < 4) return 0;
    double carpan = tur == 'yurtdisi' ? 15.0 : 10.0;
    return carpan * ay;
  }

  // ── YAYIN ────────────────────────────────────────────────────
  static double yayinPuani({
    required String tur,
    required String alan,
    int kisi = 1,
    int adet = 1,
    String quartile = 'Q1',
    bool ahci = false,
  }) {
    double k = kKatsayisi(kisi);
    double p = pKatsayisi(quartile, ahci);
    bool a2a4 = alan == 'A2' || alan == 'A4';
    double birimPuan;
    switch (tur) {
      case 'sciArastirma':    birimPuan = k * p * (a2a4 ? 80 : 60); break;
      case 'sciDerleme':      birimPuan = k * p * (a2a4 ? 40 : 30); break;
      case 'alanEndeksi':     birimPuan = k * (a2a4 ? 25 : 20); break;
      case 'digerUlus':       birimPuan = k * (a2a4 ? 20 : 15); break;
      case 'ulakbim':         birimPuan = k * (a2a4 ? 20 : 15); break;
      case 'editSciExpanded': birimPuan = 25; break;
      case 'editAlan':        birimPuan = 15; break;
      case 'editDigerUlus':   birimPuan = 10; break;
      case 'editUlakbim':     birimPuan = 10; break;
      case 'kitapUlusYazar':  birimPuan = k * 100; break;
      case 'kitapUlusEditor': birimPuan = k * 60;  break;
      case 'kitapUlusBolum':  birimPuan = k * 25;  break;
      case 'sesKisiselUlus':  birimPuan = alan == 'A4' ? 20 : 0; break;
      case 'sesKarmaUlus':    birimPuan = alan == 'A4' ? 10 : 0; break;
      case 'sesKisiselUlus2': birimPuan = alan == 'A4' ? 10 : 0; break;
      default: birimPuan = 0;
    }
    return birimPuan * adet;
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
  static double atifPuani({
    required String tur,
    required String alan,
    required int adet,
  }) {
    bool a2a4 = alan == 'A2' || alan == 'A4';
    double birim;
    switch (tur) {
      case 'sci':       birim = a2a4 ? 6   : 4;   break;
      case 'alan':      birim = a2a4 ? 3   : 1.5; break;
      case 'digerUlus':
      case 'digerUlusAtif': birim = a2a4 ? 2 : 1; break;
      case 'ulakbim':   birim = a2a4 ? 2   : 1;   break;
      case 'kitap':     birim = a2a4 ? 8   : 4;   break;
      case 'guzelUlus': birim = alan == 'A4' ? 8 : 0; break;
      case 'guzelUlus2':birim = alan == 'A4' ? 4 : 0; break;
      default: birim = 0;
    }
    return birim * adet;
  }

  // ── TEBLİĞ ───────────────────────────────────────────────────
  static double tebligPuani({required int kisi, required int adet}) =>
      kKatsayisi(kisi) * 15 * adet;

  // ── ÖDÜL ─────────────────────────────────────────────────────
  static double odulPuani({required String tur, required String alan}) {
    switch (tur) {
      case 'yokTez':        return 100;
      case 'tubitakBilim':  return 100;
      case 'tubaAkademi':   return 100;
      case 'yurtdisiBilim': return 40;
      case 'yurticiiBilim': return 20;
      case 'guzelUlusJuri': return alan == 'A4' ? 40 : 0;
      case 'guzelUlasJuri': return alan == 'A4' ? 20 : 0;
      case 'mimarlik':      return alan == 'A3' ? 20 : 0;
      default: return 0;
    }
  }

  // ── SERGİ ────────────────────────────────────────────────────
  static double sergiPuani({required String tur, required String alan}) {
    if (alan != 'A4') return 0;
    switch (tur) {
      case 'yurtdisiBireysel': return 30;
      case 'yurticiiBireysel': return 15;
      case 'yurtdisiGrup':     return 15;
      case 'yurticiiGrup':     return 8;
      default: return 0;
    }
  }

  // ── TASARIM ──────────────────────────────────────────────────
  static double tasarimPuani({required int adet}) => 15.0 * adet;

  // ── TOPLAM ───────────────────────────────────────────────────
  static Map<String, double> toplamHesapla({
    required String alan,
    required List<Map<String, dynamic>> faaliyetler,
  }) {
    Map<String, double> oranlar = {
      'proje': 0, 'arastirma': 0, 'yayin': 0,
      'patent': 0, 'atif': 0, 'teblig': 0,
      'odul': 0, 'sergi': 0, 'tasarim': 0,
    };
    Map<String, double> tavanlar = {
      'proje': 20, 'arastirma': 15, 'yayin': 30,
      'patent': 30, 'atif': 30, 'teblig': 20,
      'odul': 20, 'sergi': 15, 'tasarim': 15,
    };

    for (var f in faaliyetler) {
      String kategori = f['kategori'];
      int adet = f['adet'] ?? 1;
      double puan = 0;
      switch (kategori) {
        case 'proje':
          puan = projePuani(tur: f['tur'], rol: f['rol'], adet: adet); break;
        case 'arastirma':
          puan = arastirmaPuani(tur: f['tur'], ay: f['ay']); break;
        case 'yayin':
          puan = yayinPuani(
            tur: f['tur'], alan: alan, kisi: f['kisi'] ?? 1,
            adet: adet, quartile: f['quartile'] ?? 'Q1',
            ahci: f['ahci'] ?? false,
          ); break;
        case 'patent':
          puan = patentPuani(tur: f['tur'], kisi: f['kisi'] ?? 1, adet: adet); break;
        case 'atif':
          puan = atifPuani(tur: f['tur'], alan: alan, adet: adet); break;
        case 'teblig':
          puan = tebligPuani(kisi: f['kisi'] ?? 1, adet: adet); break;
        case 'odul':
          puan = odulPuani(tur: f['tur'], alan: alan); break;
        case 'sergi':
          puan = sergiPuani(tur: f['tur'], alan: alan); break;
        case 'tasarim':
          puan = tasarimPuani(adet: adet); break;
      }
      oranlar[kategori] = (oranlar[kategori] ?? 0) + puan;
    }

    double toplamPuan = 0;
    Map<String, double> sonuc = {};
    oranlar.forEach((key, value) {
      double tavan = tavanlar[key] ?? 0;
      double puanTavanli = (value / 100 * tavan).clamp(0, tavan);
      sonuc[key] = puanTavanli;
      toplamPuan += puanTavanli;
    });
    sonuc['toplam'] = toplamPuan.clamp(0, 100);
    return sonuc;
  }

  // ── ÖDEME ────────────────────────────────────────────────────
  static double odemeHesapla({
    required double tesfikPuani,
    required String unvan,
    required double enYuksekBrutAylik,
  }) {
    double oran;
    switch (unvan) {
      case 'Profesör':            oran = 1.00; break;
      case 'Doçent':              oran = 0.90; break;
      case 'Dr. Öğr. Üyesi':     oran = 0.80; break;
      case 'Araştırma Görevlisi':
      case 'Öğretim Görevlisi':  oran = 0.70; break;
      default:                    oran = 0.70;
    }
    return enYuksekBrutAylik * oran * (tesfikPuani / 100);
  }
}