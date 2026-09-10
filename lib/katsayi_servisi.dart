// lib/katsayi_servisi.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

import 'hesaplama_motoru.dart';

class KatsayiServisi {
  static const String _jsonUrl =
      'https://raw.githubusercontent.com/asaygili/akademik-tesvik-data/main/katsayi.json';

  static const String _hiveKey = 'katsayi_verisi';

  /// Çevrimdışı varsayılan memur aylık katsayısı (Temmuz 2026).
  /// Yönetmelik m.3/ç uyarınca en yüksek Devlet memuru brüt aylığı
  /// 9.500 gösterge × memur aylık katsayısı ile bulunur.
  static const double _varsayilanMemurAylikKatsayisi = 1.575512;

  /// m.3/ç: en yüksek Devlet memuru brüt aylığı.
  static double brutAylik(double memurAylikKatsayisi) =>
      HesaplamaMotoru.gostergeToplami * memurAylikKatsayisi;

  /// İnternet erişimi yokken kullanılacak brüt aylık.
  static double get varsayilanBrutAylik =>
      brutAylik(_varsayilanMemurAylikKatsayisi);

  // Uygulamada kullanılacak ana metod
  // Önce cache'den okur, arka planda günceller
  static Future<Map<String, dynamic>> katsayiGetir() async {
    final box = Hive.box('gecmis');
    Map<String, dynamic> sonuc = _varsayilanVeri();

    // Cache'den oku
    final cached = box.get(_hiveKey);
    if (cached != null) {
      sonuc = _normalize(Map<String, dynamic>.from(cached as Map));
    }

    // Arka planda güncel veriyi çek
    _guncelleAsync(box);

    return sonuc;
  }

  // Güncel veriyi internetten çek ve cache'e yaz
  static Future<void> _guncelleAsync(Box box) async {
    try {
      final response = await http
          .get(Uri.parse(_jsonUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final veri = jsonDecode(response.body) as Map<String, dynamic>;
        await box.put(_hiveKey, veri);
      }
    } catch (_) {
      // İnternet yoksa sessizce geç, cache kullanılır
    }
  }

  // İnternet bağlantısı ile zorla güncelle
  static Future<Map<String, dynamic>> zorlaGuncelle() async {
    try {
      final response = await http
          .get(Uri.parse(_jsonUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final veri = jsonDecode(response.body) as Map<String, dynamic>;
        final box = Hive.box('gecmis');
        await box.put(_hiveKey, veri);
        return _normalize(veri);
      }
    } catch (_) {}
    return _varsayilanVeri();
  }

  /// Gelen veride memur aylık katsayısı varsa brüt aylığı m.3/ç formülüyle
  /// hesaplar; yoksa doğrudan verilen brüt aylığı kullanır. Hiçbiri geçerli
  /// değilse çevrimdışı varsayılana döner.
  static Map<String, dynamic> _normalize(Map<String, dynamic> veri) {
    final sonuc = Map<String, dynamic>.from(veri);

    final katsayi = (veri['memurAylikKatsayisi'] as num?)?.toDouble();
    final brut = (veri['enYuksekBrut'] as num?)?.toDouble();

    if (katsayi != null && katsayi > 0) {
      sonuc['enYuksekBrut'] = brutAylik(katsayi);
    } else if (brut != null && brut > 0) {
      sonuc['enYuksekBrut'] = brut;
    } else {
      return _varsayilanVeri();
    }
    return sonuc;
  }

  static Map<String, dynamic> _varsayilanVeri() {
    return {
      'enYuksekBrut': brutAylik(_varsayilanMemurAylikKatsayisi),
      'memurAylikKatsayisi': _varsayilanMemurAylikKatsayisi,
      'aciklama':
          'Varsayılan değer (internet bağlantısı yok) – Temmuz 2026 katsayısı',
      'guncelleme': '2026-07',
      'sonrakiZam': '2027-01',
    };
  }
}
