// lib/tema.dart
//
// Uygulamanın tasarım sistemi: renk şeması, açık/koyu tema, faaliyet türü
// kimlikleri (ad, ikon, renk, tavan) ve Türkçe sayı biçimlendirme.

import 'package:flutter/material.dart';

export 'bicim.dart';

// ════════════════════════════════════════════════════════════════
// TEMA
// ════════════════════════════════════════════════════════════════

class AkademikTema {
  static const Color _tohum = Color(0xFF1B4E8C);

  static ThemeData acik() => _olustur(Brightness.light);
  static ThemeData koyu() => _olustur(Brightness.dark);

  static ThemeData _olustur(Brightness parlaklik) {
    final renk = ColorScheme.fromSeed(
      seedColor: _tohum,
      brightness: parlaklik,
    );
    final koyuMu = parlaklik == Brightness.dark;
    final zemin = koyuMu ? const Color(0xFF12151A) : const Color(0xFFF6F7FB);

    final metin = Typography.material2021(
      colorScheme: renk,
    ).black.apply(
          bodyColor: renk.onSurface,
          displayColor: renk.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: renk,
      scaffoldBackgroundColor: zemin,
      textTheme: koyuMu
          ? Typography.material2021(colorScheme: renk).white.apply(
                bodyColor: renk.onSurface,
                displayColor: renk.onSurface,
              )
          : metin,
      appBarTheme: AppBarTheme(
        backgroundColor: zemin,
        foregroundColor: renk.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: renk.onSurface,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: renk.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: renk.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: koyuMu
            ? renk.surfaceContainerHighest.withValues(alpha: 0.4)
            : renk.surfaceContainerHighest.withValues(alpha: 0.5),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: renk.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: renk.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: renk.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: renk.onSurfaceVariant),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0),
          side: BorderSide(color: renk.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: renk.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: renk.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: renk.onSurfaceVariant),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: renk.outlineVariant.withValues(alpha: 0.7),
        thickness: 1,
        space: 1,
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearMinHeight: 6,
        linearTrackColor: renk.outlineVariant.withValues(alpha: 0.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: renk.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FAALİYET TÜRÜ KİMLİKLERİ
// ════════════════════════════════════════════════════════════════

class Kategori {
  final String anahtar;
  final int sira;
  final String ad;
  final IconData ikon;
  final Color _renk;
  final double tavan;

  const Kategori({
    required this.anahtar,
    required this.sira,
    required this.ad,
    required this.ikon,
    required Color renk,
    required this.tavan,
  }) : _renk = renk;

  String get numarali => '$sira. $ad';

  /// Kategori vurgu rengi; koyu temada okunabilirlik için açılır.
  Color vurgu(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) return _renk;
    final hsl = HSLColor.fromColor(_renk);
    return hsl
        .withLightness((hsl.lightness + 0.22).clamp(0.0, 0.70))
        .withSaturation((hsl.saturation * 0.68).clamp(0.0, 1.0))
        .toColor();
  }

  /// Kart zemini için çok düşük yoğunluklu ton.
  Color zemin(BuildContext context) => vurgu(context).withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.14 : 0.08);

  static const Map<String, Kategori> tumu = {
    'proje': Kategori(
        anahtar: 'proje', sira: 1, ad: 'Proje',
        ikon: Icons.science_outlined, renk: Color(0xFF2563EB), tavan: 20),
    'arastirma': Kategori(
        anahtar: 'arastirma', sira: 2, ad: 'Araştırma',
        ikon: Icons.travel_explore_outlined, renk: Color(0xFF7C3AED),
        tavan: 15),
    'yayin': Kategori(
        anahtar: 'yayin', sira: 3, ad: 'Yayın',
        ikon: Icons.article_outlined, renk: Color(0xFF047857), tavan: 30),
    'tasarim': Kategori(
        anahtar: 'tasarim', sira: 4, ad: 'Tasarım',
        ikon: Icons.architecture_outlined, renk: Color(0xFF92400E),
        tavan: 15),
    'sergi': Kategori(
        anahtar: 'sergi', sira: 5, ad: 'Sergi',
        ikon: Icons.palette_outlined, renk: Color(0xFFBE185D), tavan: 15),
    'patent': Kategori(
        anahtar: 'patent', sira: 6, ad: 'Patent',
        ikon: Icons.workspace_premium_outlined, renk: Color(0xFFC2410C),
        tavan: 30),
    'atif': Kategori(
        anahtar: 'atif', sira: 7, ad: 'Atıf',
        ikon: Icons.format_quote_outlined, renk: Color(0xFF0E7490),
        tavan: 30),
    'teblig': Kategori(
        anahtar: 'teblig', sira: 8, ad: 'Tebliğ',
        ikon: Icons.campaign_outlined, renk: Color(0xFF4338CA), tavan: 20),
    'odul': Kategori(
        anahtar: 'odul', sira: 9, ad: 'Ödül',
        ikon: Icons.emoji_events_outlined, renk: Color(0xFFA16207),
        tavan: 20),
  };

  static Kategori? bul(String? anahtar) => tumu[anahtar];

  /// Yönetmelikteki sıraya göre kategoriler.
  static List<Kategori> get sirali =>
      tumu.values.toList()..sort((a, b) => a.sira.compareTo(b.sira));
}

// ════════════════════════════════════════════════════════════════
// FAALİYET TÜRÜ ADLARI (Tablo 4 satır başlıkları)
// ════════════════════════════════════════════════════════════════

class FaaliyetTuru {
  static const Map<String, String> adlar = {
    // 1. Proje
    '1001': '1.1. TÜBİTAK 1001/1003/1004/1007/1505/2244/3501/SAYEM/COST',
    '1005': '1.2. TÜBİTAK 1005/3001',
    'H2020': '1.3. H2020 / Horizon Projesi',
    'ulusUzel': '1.4. Diğer Uluslararası Proje',
    'ulusOzel': '1.5. Diğer Ulusal Proje',
    // 2. Araştırma
    'yurtdisi': '2.1. Yurt Dışı Araştırma',
    'yurtici': '2.2. Yurt İçi Araştırma',
    // 3. Yayın
    'sciArastirma': '3.1. SCI/SSCI/AHCI Araştırma Makalesi',
    'sciDerleme': '3.2. SCI/SSCI/AHCI Derleme Makale',
    'alanEndeksi': '3.3. Alan Endeksi Makalesi',
    'digerUlus': '3.4. Diğer Uluslararası Hakemli Makale',
    'ulakbim': '3.5. ULAKBİM TR Dizin Makalesi',
    'editSciExpanded': '3.6. SCI/SSCI/AHCI Editörlük',
    'editAlan': '3.7. Alan Endeksi Editörlük',
    'editDigerUlus': '3.8. Diğer Uluslararası Editörlük',
    'editUlakbim': '3.9. ULAKBİM Editörlük',
    'kitapUlusYazar': '3.10. Uluslararası Kitap (Yazar)',
    'kitapUlusEditor': '3.11. Uluslararası Kitap (Editör)',
    'kitapUlusBolum': '3.12. Uluslararası Kitap Bölümü',
    'sesKisiselUlus': '3.15. Kişisel Ses/Görüntü (Uluslararası)',
    'sesKarmaUlus': '3.16. Karma Ses/Görüntü (Uluslararası)',
    'sesKisiselUlus2': '3.17. Kişisel Ses/Görüntü (Ulusal)',
    // 4. Tasarım
    'tasarim': '4.1. Tasarım',
    // 5. Sergi
    'yurtdisiBireysel': '5.1. Yurt Dışı Bireysel Etkinlik',
    'yurticiiBireysel': '5.2. Yurt İçi Bireysel Etkinlik',
    'yurtdisiGrup': '5.3. Yurt Dışı Grup Etkinlik',
    'yurticiiGrup': '5.4. Yurt İçi Grup Etkinlik',
    // 6. Patent
    'uluslararasi': '6.1. Uluslararası Patent',
    'ulusal': '6.2. Ulusal Patent',
    // 7. Atıf
    'sci': '7.1. SCI/SSCI/AHCI Makale Atfı',
    'alan': '7.2. Alan Endeksi Makale Atfı',
    'digerUlusAtif': '7.3. Diğer Uluslararası Makale Atfı',
    'ulakbimAtif': '7.4. ULAKBİM Makale Atfı',
    'kitap': '7.5. Uluslararası Kitap Atfı',
    'guzelUlus': '7.7. Güzel Sanat Uluslararası',
    'guzelUlus2': '7.8. Güzel Sanat Ulusal',
    // 8. Tebliğ
    'uluslararasiTeblig': '8.1. Uluslararası Tebliğ',
    // 9. Ödül
    'yokTez': '9.1. YÖK Yılın Doktora Tezi Ödülü',
    'tubitakBilim': '9.2. TÜBİTAK Bilim Ödülü',
    'tubaAkademi': '9.3. TÜBA Akademi Ödülü',
    'yurtdisiBilim': '9.4. Yurt Dışı Bilim Ödülü',
    'yurticiiBilim': '9.5. Yurt İçi Bilim Ödülü',
    'guzelUlusJuri': '9.6. Güzel Sanat Uluslararası Ödül',
    'guzelUlasJuri': '9.7. Güzel Sanat Ulusal Ödül',
    'mimarlik': '9.8. Mimarlık/Tasarım Yarışması',
  };

  static String ad(Map f) =>
      adlar[f['tur']] ??
      (f['tur'] as String?) ??
      (f['kategori'] as String?) ??
      '-';
}

// ════════════════════════════════════════════════════════════════
// BİLİM ALANLARI VE UNVANLAR
// ════════════════════════════════════════════════════════════════

class BilimAlani {
  /// Açılır listede görünen tam etiketler.
  static const Map<String, String> kisa = {
    'A1': 'A1 · Fen, Mühendislik, Sağlık, Ziraat, Eğitim',
    'A2': 'A2 · Sosyal, Hukuk, İlahiyat, Filoloji, Spor',
    'A3': 'A3 · Mimarlık, Planlama ve Tasarım',
    'A4': 'A4 · Güzel Sanatlar',
  };

  /// Alan seçili haldeyken tek satıra sığan etiketler.
  static const Map<String, String> secili = {
    'A1': 'A1 · Fen ve Mühendislik',
    'A2': 'A2 · Sosyal ve Beşeri',
    'A3': 'A3 · Mimarlık ve Tasarım',
    'A4': 'A4 · Güzel Sanatlar',
  };

  static const Map<String, String> uzun = {
    'A1': 'A1 – Eğitim Bilimleri, Fen Bilimleri ve Matematik, Mühendislik, '
        'Sağlık Bilimleri, Ziraat, Orman ve Su Ürünleri',
    'A2': 'A2 – Filoloji, Hukuk, İlahiyat, Sosyal, Beşeri ve İdari Bilimler, '
        'Spor Bilimleri',
    'A3': 'A3 – Mimarlık, Planlama ve Tasarım',
    'A4': 'A4 – Güzel Sanatlar',
  };
}

class Unvan {
  static const Map<String, double> oranlar = {
    'Profesör': 1.00,
    'Doçent': 0.90,
    'Dr. Öğr. Üyesi': 0.80,
    'Araştırma Görevlisi': 0.70,
    'Öğretim Görevlisi': 0.70,
  };
}
