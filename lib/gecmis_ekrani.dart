// lib/gecmis_ekrani.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'pdf_rapor.dart';

class GecmisEkrani extends StatelessWidget {
  final Function({required Map kayit, required dynamic key}) onKayitDuzenle;

  const GecmisEkrani({super.key, required this.onKayitDuzenle});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('gecmis');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş Hesaplamalar'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Tümünü Sil',
            onPressed: () => _tumunuSilDialog(context, box),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          if (b.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Henüz kayıt yok.',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(
                    'Hesapladıktan sonra "Geçmişe Kaydet" butonunu kullanın.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final keys = b.keys.toList().reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12),
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
              'Bu kayıt eski formatta, faaliyet detayları bulunmuyor. Yeniden hesaplayıp kaydedin.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    onKayitDuzenle(kayit: kayit, key: key);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kayıt düzenleme ekranına yüklendi.'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _silDialog(BuildContext context, Box box, dynamic key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text('Bu kayıt silinecek. Emin misiniz?'),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
        title: const Text('Tümünü Sil'),
        content:
            const Text('Tüm geçmiş kayıtlar silinecek. Emin misiniz?'),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
          (kayit['enYuksekBrut'] as num?)?.toDouble() ?? 45000,
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
    final tarih =
        DateTime.tryParse(kayit['tarih'] ?? '') ?? DateTime.now();
    final guncellenmeTarih = kayit['guncellenmeTarihi'] != null
        ? DateTime.tryParse(kayit['guncellenmeTarihi'])
        : null;
    final puan = (kayit['puan'] as num?)?.toDouble() ?? 0;
    final odeme = (kayit['odeme'] as num?)?.toDouble() ?? 0;
    final alan = kayit['alan'] ?? '';
    final unvan = kayit['unvan'] ?? '';
    final faaliyetSayisi = kayit['faaliyetSayisi'] ?? 0;
    final not = kayit['not'] ?? '';
    final bool duzenlenebilir =
        kayit['faaliyetler'] != null &&
        (kayit['faaliyetler'] as List).isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Üst satır: tarih + butonlar ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _tarihFormat(tarih),
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    if (guncellenmeTarih != null)
                      Row(
                        children: [
                          const Icon(Icons.update,
                              size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Güncellendi: ${_tarihFormat(guncellenmeTarih)}',
                            style: const TextStyle(
                                color: Colors.orange, fontSize: 11),
                          ),
                        ],
                      ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined,
                          color: Colors.red, size: 22),
                      tooltip: 'PDF İndir',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onPdf,
                    ),
                    const SizedBox(width: 12),
                    Tooltip(
                      message: duzenlenebilir
                          ? 'Düzenle'
                          : 'Eski format – düzenlenemiyor',
                      child: IconButton(
                        icon: Icon(Icons.edit_outlined,
                            color: duzenlenebilir
                                ? Colors.blue
                                : Colors.grey,
                            size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: duzenlenebilir ? onDuzenle : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 22),
                      tooltip: 'Sil',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onSil,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Chip'ler ──
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(unvan, Colors.blue),
                _chip(alan, Colors.purple),
                _chip('$faaliyetSayisi faaliyet', Colors.grey),
                if (duzenlenebilir)
                  _chip('✏️ Düzenlenebilir', Colors.green)
                else
                  _chip('⚠️ Eski format', Colors.orange),
              ],
            ),

            // ── Not ──
            if (not.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_outlined,
                        size: 13, color: Colors.amber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        not,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── Puan + Ödeme ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Teşvik Puanı',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 11)),
                    Text(
                      puan.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: puan >= 30
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Aylık Ödeme',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 11)),
                    Text(
                      '₺${odeme.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            Text(
              'Yıllık: ₺${(odeme * 12).toStringAsFixed(2)}',
              style:
                  const TextStyle(color: Colors.grey, fontSize: 12),
            ),

            if (puan < 30)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber,
                        color: Colors.orange, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Ödeme için 30 puan gerekli',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color renk) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: renk.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: renk.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            color: renk,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  String _tarihFormat(DateTime t) {
    return '${t.day.toString().padLeft(2, '0')}.'
        '${t.month.toString().padLeft(2, '0')}.'
        '${t.year}  '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}