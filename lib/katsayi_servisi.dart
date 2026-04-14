// lib/katsayi_servisi.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class KatsayiServisi {
  static const String _jsonUrl =
      'https://raw.githubusercontent.com/asaygili/akademik-tesvik-data/main/katsayi.json';

  static const String _hiveKey = 'katsayi_verisi';
  static const double _varsayilanBrut = 45000;

  // Uygulamada kullanılacak ana metod
  // Önce cache'den okur, arka planda günceller
  static Future<Map<String, dynamic>> katsayiGetir() async {
    final box = Hive.box('gecmis');
    Map<String, dynamic> sonuc = _varsayilanVeri();

    // Cache'den oku
    final cached = box.get(_hiveKey);
    if (cached != null) {
      sonuc = Map<String, dynamic>.from(cached as Map);
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
        return veri;
      }
    } catch (_) {}
    return _varsayilanVeri();
  }

  static Map<String, dynamic> _varsayilanVeri() {
    return {
      'enYuksekBrut': _varsayilanBrut,
      'aciklama': 'Varsayılan değer (internet bağlantısı yok)',
      'guncelleme': '2026-01',
      'sonrakiZam': '2026-07',
    };
  }
}