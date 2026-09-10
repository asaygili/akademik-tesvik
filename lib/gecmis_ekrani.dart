// lib/gecmis_ekrani.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hesaplama_motoru.dart';
import 'katsayi_servisi.dart';
import 'pdf_rapor.dart';
import 'tema.dart';

class GecmisEkrani extends StatelessWidget {
  final Function({required Map kayit, required dynamic key}) onKayitDuzenle;

  const GecmisEkrani({super.key, required this.onKayitDuzenle});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('gecmis');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Tüm kayıtları sil',
            onPressed: () => _tumunuSilDialog(context, box),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          if (b.isEmpty) {
            final renk = Theme.of(context).colorScheme;
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_toggle_off_outlined,
                        size: 48, color: renk.onSurfaceVariant),
                    const SizedBox(height: 14),
                    Text(
                      'Henüz kayıt yok',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: renk.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hesapla sekmesinde puanınızı hesaplayıp "Kaydet" '
                      'ile buraya ekleyebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: renk.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          final keys = b.keys.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: keys.length,
            itemBuilder: (ctx, i) {
              final kayit = b.get(keys[i]) as Map;
              return _KayitKarti(
                kayit: kayit,
                onSil: () => _silDialog(context, b, keys[i]),
                onDuzenle: () => _duzenleVeGec(context, kayit, keys[i]),
                onPdf: () => _pdfOlustur(kayit),
              );
            },
          );
        },
      ),
    );
  }

  void _duzenleVeGec(BuildContext context, Map kayit, dynamic key) {
    // Faaliyetler mevcut mu kontrol et
    final faaliyetler = kayit['faaliyetler'];
    if (faaliyetler == null || (faaliyetler as List).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bu kayıt eski formatta; faaliyet detayları bulunmuyor. '
              'Yeniden hesaplayıp kaydedin.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    onKayitDuzenle(kayit: kayit, key: key);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kayıt düzenleme ekranına yüklendi.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _silDialog(BuildContext context, Box box, dynamic key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: const Text('Bu kayıt kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              box.delete(key);
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _tumunuSilDialog(BuildContext context, Box box) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm kayıtları sil'),
        content: const Text(
            'Geçmişteki bütün kayıtlar kalıcı olarak silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              box.clear();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _pdfOlustur(Map kayit) {
    final faaliyetler = (kayit['faaliyetler'] as List?)
            ?.map((f) => Map<String, dynamic>.from(f as Map))
            .toList() ??
        [];
    final sonuclar = (kayit['sonuclar'] as Map?)
            ?.map((k, v) =>
                MapEntry(k.toString(), (v as num).toDouble())) ??
        {};

    PdfRapor.olusturVeGoster(
      alan: kayit['alan'] ?? 'A1',
      unvan: kayit['unvan'] ?? 'Profesör',
      enYuksekBrut:
          (kayit['enYuksekBrut'] as num?)?.toDouble() ??
              KatsayiServisi.varsayilanBrutAylik,
      faaliyetler: faaliyetler,
      sonuclar: sonuclar,
      toplamPuan: (kayit['puan'] as num?)?.toDouble() ?? 0,
      odeme: (kayit['odeme'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ════════════════════════════════════════════════════════════════
// KAYIT KARTI
// ════════════════════════════════════════════════════════════════

class _KayitKarti extends StatelessWidget {
  final Map kayit;
  final VoidCallback onSil;
  final VoidCallback onDuzenle;
  final VoidCallback onPdf;

  const _KayitKarti({
    required this.kayit,
    required this.onSil,
    required this.onDuzenle,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tema.colorScheme;

    final tarih = DateTime.tryParse(kayit['tarih'] ?? '') ?? DateTime.now();
    final guncellenmeTarih = kayit['guncellenmeTarihi'] != null
        ? DateTime.tryParse(kayit['guncellenmeTarihi'])
        : null;
    final puan = (kayit['puan'] as num?)?.toDouble() ?? 0;
    final odeme = (kayit['odeme'] as num?)?.toDouble() ?? 0;
    final alan = (kayit['alan'] ?? '') as String;
    final unvan = (kayit['unvan'] ?? '') as String;
    final faaliyetSayisi = kayit['faaliyetSayisi'] ?? 0;
    final not = (kayit['not'] ?? '') as String;
    final duzenlenebilir = kayit['faaliyetler'] != null &&
        (kayit['faaliyetler'] as List).isNotEmpty;

    final yeterli = puan >= HesaplamaMotoru.enAzTesvikPuani;
    final durumRengi = yeterli ? renk.primary : renk.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tarih ve eylemler ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Bicim.tarihSaat(tarih),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: renk.onSurface,
                          ),
                        ),
                        if (guncellenmeTarih != null)
                          Text(
                            'Güncellendi: ${Bicim.tarihSaat(guncellenmeTarih)}',
                            style: TextStyle(
                                fontSize: 11, color: renk.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined, size: 20),
                    color: renk.onSurfaceVariant,
                    tooltip: 'PDF raporu',
                    visualDensity: VisualDensity.compact,
                    onPressed: onPdf,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    color: duzenlenebilir
                        ? renk.onSurfaceVariant
                        : renk.onSurfaceVariant.withValues(alpha: 0.35),
                    tooltip: duzenlenebilir
                        ? 'Düzenle'
                        : 'Eski kayıt · düzenlenemiyor',
                    visualDensity: VisualDensity.compact,
                    onPressed: duzenlenebilir ? onDuzenle : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: renk.onSurfaceVariant,
                    tooltip: 'Sil',
                    visualDensity: VisualDensity.compact,
                    onPressed: onSil,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Puan ve ödeme ──
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Teşvik puanı',
                          style: TextStyle(
                              fontSize: 11.5, color: renk.onSurfaceVariant),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Bicim.puan(puan),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                height: 1.1,
                                color: durumRengi,
                              ),
                            ),
                            Text(
                              ' / 100',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: renk.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Aylık ödeme',
                          style: TextStyle(
                              fontSize: 11.5, color: renk.onSurfaceVariant),
                        ),
                        Text(
                          Bicim.para(odeme),
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.25,
                            color: renk.onSurface,
                          ),
                        ),
                        if (yeterli)
                          Text(
                            'yıllık ${Bicim.para(odeme * 12)}',
                            style: TextStyle(
                                fontSize: 11, color: renk.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // ── Yüz puanlık ölçekte doluluk ──
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (puan / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    color: durumRengi,
                    backgroundColor: renk.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (!yeterli)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 13, color: renk.error),
                      const SizedBox(width: 5),
                      Text(
                        'Ödeme için en az 30 puan gerekir (m.10/3)',
                        style: TextStyle(fontSize: 11, color: renk.error),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // ── Etiketler ──
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _etiket(context, unvan),
                  _etiket(context, alan),
                  _etiket(context, '$faaliyetSayisi faaliyet'),
                  if (!duzenlenebilir)
                    _etiket(context, 'Eski kayıt', uyari: true),
                ],
              ),

              if (not.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.sticky_note_2_outlined,
                        size: 14, color: renk.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        not,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: renk.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _etiket(BuildContext context, String metin, {bool uyari = false}) {
    final renk = Theme.of(context).colorScheme;
    final zemin = uyari
        ? renk.errorContainer
        : renk.surfaceContainerHighest.withValues(alpha: 0.7);
    final yazi = uyari ? renk.onErrorContainer : renk.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: zemin,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        metin,
        style: TextStyle(
            fontSize: 11.5, color: yazi, fontWeight: FontWeight.w500),
      ),
    );
  }
}
