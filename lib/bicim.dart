// lib/bicim.dart
//
// Türkçe sayı, para ve tarih biçimlendirme. Flutter'a bağımlı değildir;
// hesaplama motoru da bu dosyayı kullanır.

// ════════════════════════════════════════════════════════════════
// TÜRKÇE SAYI BİÇİMLENDİRME
// ════════════════════════════════════════════════════════════════

class Bicim {
  /// 1234.5 → "1.234,50"
  static String sayi(num deger, {int basamak = 2}) {
    final negatif = deger < 0;
    final metin = deger.abs().toStringAsFixed(basamak);
    final parcalar = metin.split('.');
    final tam = parcalar[0];

    final tampon = StringBuffer();
    for (int i = 0; i < tam.length; i++) {
      if (i > 0 && (tam.length - i) % 3 == 0) tampon.write('.');
      tampon.write(tam[i]);
    }

    final sonuc = parcalar.length > 1
        ? '${tampon.toString()},${parcalar[1]}'
        : tampon.toString();
    return negatif ? '-$sonuc' : sonuc;
  }

  /// 61.5 → "61,50"
  static String puan(num deger) => sayi(deger, basamak: 2);

  /// 14967.36 → "14.967,36 ₺"
  static String para(num deger) => '${sayi(deger, basamak: 2)} ₺';

  /// 72.0 → "%72,00"
  static String oran(num deger) => '%${sayi(deger, basamak: 2)}';

  /// 2026-02-15T10:00 → "15.02.2026 · 10:00"
  static String tarihSaat(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}'
      '.${t.year} · ${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
