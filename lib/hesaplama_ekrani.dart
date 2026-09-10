// lib/hesaplama_ekrani.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hesaplama_motoru.dart';
import 'pdf_rapor.dart';
import 'katsayi_servisi.dart';

class HesaplamaEkrani extends StatefulWidget {
  final Map<String, dynamic>? duzenlenecekKayit;
  final dynamic duzenlenecekKey;
  final VoidCallback? onDuzenlemeTemizle;

  const HesaplamaEkrani({
    super.key,
    this.duzenlenecekKayit,
    this.duzenlenecekKey,
    this.onDuzenlemeTemizle,
  });

  @override
  State<HesaplamaEkrani> createState() => _HesaplamaEkraniState();
}

class _HesaplamaEkraniState extends State<HesaplamaEkrani> {
  String _alan = 'A1';
  String _unvan = 'Profesör';
  double _enYuksekBrut = 45000;
  String _katsayiAciklama = '';
  bool _katsayiYuklendi = false;
  final List<Map<String, dynamic>> _faaliyetler = [];

  Map<String, double> _sonuclar = {};
  double _toplamPuan = 0;
  double _odeme = 0;
  bool _hesaplandimi = false;
  bool _duzenlemeModu = false;
  dynamic _duzenlenenKey;

  @override
  void didUpdateWidget(HesaplamaEkrani oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duzenlenecekKayit != null &&
        widget.duzenlenecekKayit != oldWidget.duzenlenecekKayit) {
      _kayitYukle(widget.duzenlenecekKayit!, widget.duzenlenecekKey);
    }
  }
  @override
  void initState() {
    super.initState();
    _katsayiYukle();
  }

  Future<void> _katsayiYukle({bool zorla = false}) async {
    final veri = zorla
        ? await KatsayiServisi.zorlaGuncelle()
        : await KatsayiServisi.katsayiGetir();
    if (mounted) {
      setState(() {
        _enYuksekBrut =
            (veri['enYuksekBrut'] as num?)?.toDouble() ?? 45000;
        final aciklama = veri['aciklama'] ?? '';
        final varsayilanMi = aciklama.contains('internet') ||
            aciklama.contains('Varsayılan');
        _katsayiAciklama = varsayilanMi
            ? 'Güncel brüt aylık değeri için sağdaki yenile butonuna tıklayınız'
            : aciklama;
        _katsayiYuklendi = !varsayilanMi;
      });
    }
  }

  void _kayitYukle(Map<String, dynamic> kayit, dynamic key) {
    setState(() {
      _alan = kayit['alan'] ?? 'A1';
      _unvan = kayit['unvan'] ?? 'Profesör';
      _enYuksekBrut =
          (kayit['enYuksekBrut'] as num?)?.toDouble() ?? 45000;
      _faaliyetler.clear();
      final liste = kayit['faaliyetler'] as List?;
      if (liste != null) {
        for (var f in liste) {
          _faaliyetler.add(Map<String, dynamic>.from(f as Map));
        }
      }
      _sonuclar = {};
      _toplamPuan = 0;
      _odeme = 0;
      _hesaplandimi = false;
      _duzenlemeModu = true;
      _duzenlenenKey = key;
    });
  }

  void _faaliyetEkle(Map<String, dynamic> faaliyet) {
    setState(() {
      _faaliyetler.add(faaliyet);
      _hesaplandimi = false;
    });
  }

  void _faaliyetGuncelle(int index, Map<String, dynamic> faaliyet) {
    setState(() {
      _faaliyetler[index] = faaliyet;
      _hesaplandimi = false;
    });
  }

  void _faaliyetSil(int index) {
    setState(() {
      _faaliyetler.removeAt(index);
      _hesaplandimi = false;
    });
  }

  void _hesapla() {
    final sonuclar = HesaplamaMotoru.toplamHesapla(
      alan: _alan,
      faaliyetler: _faaliyetler,
    );
    final toplam = sonuclar['toplam'] ?? 0;
    final odeme = HesaplamaMotoru.odemeHesapla(
      tesvikPuani: toplam,
      unvan: _unvan,
      enYuksekBrutAylik: _enYuksekBrut,
    );
    setState(() {
      _sonuclar = sonuclar;
      _toplamPuan = toplam;
      _odeme = odeme;
      _hesaplandimi = true;
    });
  }

  void _kaydet() {
    if (!_hesaplandimi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce hesaplayın!')),
      );
      return;
    }
    final box = Hive.box('gecmis');

    final veri = {
      'tarih': _duzenlemeModu
          ? (widget.duzenlenecekKayit?['tarih'] ??
              DateTime.now().toIso8601String())
          : DateTime.now().toIso8601String(),
      'guncellenmeTarihi': _duzenlemeModu
          ? DateTime.now().toIso8601String()
          : null,
      'alan': _alan,
      'unvan': _unvan,
      'enYuksekBrut': _enYuksekBrut,
      'puan': _toplamPuan,
      'odeme': _odeme,
      'faaliyetSayisi': _faaliyetler.length,
      'faaliyetler':
          _faaliyetler.map((f) => Map<String, dynamic>.from(f)).toList(),
      'sonuclar': Map<String, double>.from(_sonuclar),
      'not': widget.duzenlenecekKayit?['not'] ?? '',
    };

    if (_duzenlemeModu && _duzenlenenKey != null) {
      box.put(_duzenlenenKey, veri);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt güncellendi!'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() {
        _duzenlemeModu = false;
        _duzenlenenKey = null;
      });
      widget.onDuzenlemeTemizle?.call();
    } else {
      box.add(veri);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarıyla eklendi!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _sifirla() {
    setState(() {
      _faaliyetler.clear();
      _sonuclar = {};
      _toplamPuan = 0;
      _odeme = 0;
      _hesaplandimi = false;
      _duzenlemeModu = false;
      _duzenlenenKey = null;
    });
    widget.onDuzenlemeTemizle?.call();
  }

  void _pdfOlustur() {
    if (!_hesaplandimi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce hesaplayın!')),
      );
      return;
    }
    PdfRapor.olusturVeGoster(
      alan: _alan,
      unvan: _unvan,
      enYuksekBrut: _enYuksekBrut,
      faaliyetler: _faaliyetler,
      sonuclar: _sonuclar,
      toplamPuan: _toplamPuan,
      odeme: _odeme,
    );
  }

  void _faaliyetDialog({int? duzenleIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => FaaliyetEkleSheet(
        alan: _alan,
        mevcutFaaliyet:
            duzenleIndex != null ? _faaliyetler[duzenleIndex] : null,
        onKaydet: (f) {
          if (duzenleIndex != null) {
            _faaliyetGuncelle(duzenleIndex, f);
          } else {
            _faaliyetEkle(f);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeModu
            ? '✏️ Kayıt Düzenleniyor'
            : 'Akademik Teşvik Hesaplama'),
        backgroundColor:
            _duzenlemeModu ? Colors.orange.shade700 : renk.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF Oluştur',
            onPressed: _pdfOlustur,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Sıfırla',
            onPressed: _sifirla,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Düzenleme modu banner ──
            if (_duzenlemeModu)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Geçmiş kayıt düzenleniyor. Değişiklik yapıp tekrar hesaplayın ve kaydedin.',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _sifirla,
                      child: const Text('İptal',
                          style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
              ),

            // ── Unvan ve Alan Bilgileri ──
            _baslik('Unvan ve Alan Bilgileri'),
            const SizedBox(height: 4),
            const Text(
              'Faaliyetlerinizi girmeden önce unvanınızı ve çalışma alanınızı seçiniz.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _alan,
                      decoration: const InputDecoration(
                        labelText: 'Bilim Alanı',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'A1',
                            child: Text(
                                'A1 – Fen/Müh/Sağlık/Ziraat/Eğitim')),
                        DropdownMenuItem(
                            value: 'A2',
                            child: Text(
                                'A2 – Sosyal/Hukuk/İlahiyat/Filoloji')),
                        DropdownMenuItem(
                            value: 'A3',
                            child: Text('A3 – Mimarlık/Tasarım')),
                        DropdownMenuItem(
                            value: 'A4',
                            child: Text('A4 – Güzel Sanatlar')),
                      ],
                      onChanged: (v) => setState(() {
                        _alan = v!;
                        _hesaplandimi = false;
                      }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _unvan,
                      decoration: const InputDecoration(
                        labelText: 'Kadro Unvanı',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Profesör',
                            child: Text('Profesör (%100)')),
                        DropdownMenuItem(
                            value: 'Doçent',
                            child: Text('Doçent (%90)')),
                        DropdownMenuItem(
                            value: 'Dr. Öğr. Üyesi',
                            child: Text('Dr. Öğr. Üyesi (%80)')),
                        DropdownMenuItem(
                            value: 'Araştırma Görevlisi',
                            child: Text('Araştırma Görevlisi (%70)')),
                        DropdownMenuItem(
                            value: 'Öğretim Görevlisi',
                            child: Text('Öğretim Görevlisi (%70)')),
                      ],
                      onChanged: (v) => setState(() => _unvan = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: ValueKey(_enYuksekBrut),
                      initialValue: _enYuksekBrut.toStringAsFixed(2),
                      decoration: InputDecoration(
                        labelText:
                            'En Yüksek Devlet Memuru Brüt Aylığı (₺)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        helperText: _katsayiAciklama.isNotEmpty
                            ? _katsayiAciklama
                            : 'Güncel değer yükleniyor...',
                        helperStyle: TextStyle(
                          color: _katsayiYuklendi
                              ? Colors.green.shade700
                              : Colors.orange,
                          fontSize: 11,
                        ),
                        suffixIcon: Tooltip(
                          message: 'Güncel değeri internetten çek',
                          child: IconButton(
                            icon: const Icon(Icons.sync, size: 20),
                            onPressed: () => _katsayiYukle(zorla: true),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        _enYuksekBrut =
                            double.tryParse(v) ?? _enYuksekBrut;
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Faaliyetler ──
            _baslik('Faaliyetler'),
            const SizedBox(height: 8),

            ..._kategoriGruplari(),

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _faaliyetDialog,
                icon: const Icon(Icons.add),
                label: const Text('Yeni Faaliyet Ekle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Hesapla ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _faaliyetler.isEmpty ? null : _hesapla,
                icon: const Icon(Icons.calculate),
                label: const Text('Hesapla',
                    style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ── Sonuçlar ──
            if (_hesaplandimi) ...[
              const SizedBox(height: 16),
              Card(
                color: _toplamPuan >= 30
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sonuçlar',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ..._sonuclar.entries
                          .where((e) =>
                              e.key != 'toplam' && e.value > 0)
                          .map((e) => _sonucSatiri(e.key, e.value)),
                      const Divider(),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOPLAM PUAN',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(
                            '${_toplamPuan.toStringAsFixed(2)} / 100',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _toplamPuan >= 30
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (_toplamPuan < 30)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '⚠️ Ödeme için minimum 30 puan gereklidir.',
                            style: TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AYLIK ÖDEME',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text(
                            '₺${_odeme.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '12 ay × ₺${_odeme.toStringAsFixed(2)} = ₺${(_odeme * 12).toStringAsFixed(2)} / yıl',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _kaydet,
                              icon: Icon(_duzenlemeModu
                                  ? Icons.update
                                  : Icons.save_outlined),
                              label: Text(_duzenlemeModu
                                  ? 'Güncelle ve Kaydet'
                                  : 'Geçmişe Kaydet'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _pdfOlustur,
                              icon: const Icon(
                                  Icons.picture_as_pdf_outlined),
                              label: const Text('PDF İndir'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  List<Widget> _kategoriGruplari() {
    final kategoriler = {
      'proje': '1. Proje (20 puan)',
      'arastirma': '2. Araştırma (15 puan)',
      'yayin': '3. Yayın (30 puan)',
      'tasarim': '4. Tasarım (15 puan)',
      'sergi': '5. Sergi (15 puan)',
      'patent': '6. Patent (30 puan)',
      'atif': '7. Atıf (30 puan)',
      'teblig': '8. Tebliğ (20 puan)',
      'odul': '9. Ödül (20 puan)',
    };

    final renkler = {
      'proje': Colors.blue,
      'arastirma': Colors.purple,
      'yayin': Colors.green,
      'tasarim': Colors.brown,
      'sergi': Colors.pink,
      'patent': Colors.orange,
      'atif': Colors.teal,
      'teblig': Colors.indigo,
      'odul': Colors.amber,
    };

    List<Widget> widgets = [];
    kategoriler.forEach((key, baslik) {
      final ilgili =
          _faaliyetler.where((f) => f['kategori'] == key).toList();
      if (ilgili.isEmpty) return;

      widgets.add(const SizedBox(height: 8));
      widgets.add(Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: (renkler[key] ?? Colors.grey).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    (renkler[key] ?? Colors.grey).withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11)),
              ),
              child: Text(
                baslik,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: renkler[key] ?? Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
            ...ilgili.asMap().entries.map((entry) {
              final globalIndex = _faaliyetler.indexOf(entry.value);
              final f = entry.value;
              final aciklama = HesaplamaMotoru.puanAciklamasi(
                  f: f, alan: _alan);
              return Column(
                children: [
                  if (entry.key > 0)
                    const Divider(height: 1, indent: 12),
                  ListTile(
                    dense: true,
                    title: Text(
                      _faaliyetAdi(f),
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _faaliyetDetay(f),
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (renkler[key] ?? Colors.grey)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '📐 $aciklama',
                            style: TextStyle(
                              fontSize: 11,
                              color: renkler[key] ?? Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: SizedBox(
                      width: 80,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                color: renkler[key], size: 20),
                            tooltip: 'Güncelle',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _faaliyetDialog(
                                duzenleIndex: globalIndex),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            tooltip: 'Sil',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _faaliyetSil(globalIndex),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ));
    });

    return widgets;
  }

  Widget _baslik(String metin) {
    return Text(
      metin,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  String _faaliyetAdi(Map<String, dynamic> f) {
    final turAdlari = {
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
      'H2020': '1.3. H2020 / Horizon Projesi',
      '1001': '1.1. TÜBİTAK 1001/1003/1004/1007/1505/2244/3501/SAYEM/COST',
      '1005': '1.2. TÜBİTAK 1005/3001',
      'ulusUzel': '1.4. Diğer Uluslararası Proje',
      'ulusOzel': '1.5. Diğer Ulusal Proje',
      'yurtdisi': '2.1. Yurt Dışı Araştırma',
      'yurtici': '2.2. Yurt İçi Araştırma',
      'uluslararasi': '6.1. Uluslararası Patent',
      'ulusal': '6.2. Ulusal Patent',
      'sci': '7.1. SCI/SSCI/AHCI Makale Atfı',
      'alan': '7.2. Alan Endeksi Makale Atfı',
      'digerUlusAtif': '7.3. Diğer Uluslararası Makale Atfı',
      'ulakbimAtif': '7.4. ULAKBİM Makale Atfı',
      'kitap': '7.5. Uluslararası Kitap Atfı',
      'guzelUlus': '7.7. Güzel Sanat Uluslararası',
      'guzelUlus2': '7.8. Güzel Sanat Ulusal',
      'uluslararasiTeblig': '8.1. Uluslararası Tebliğ',
      'yokTez': '9.1. YÖK Yılın Doktora Tezi Ödülü',
      'tubitakBilim': '9.2. TÜBİTAK Bilim Ödülü',
      'tubaAkademi': '9.3. TÜBA Akademi Ödülü',
      'yurtdisiBilim': '9.4. Yurt Dışı Bilim Ödülü',
      'yurticiiBilim': '9.5. Yurt İçi Bilim Ödülü',
      'guzelUlusJuri': '9.6. Güzel Sanat Uluslararası Ödül',
      'guzelUlasJuri': '9.7. Güzel Sanat Ulusal Ödül',
      'mimarlik': '9.8. Mimarlık/Tasarım Yarışması',
      'yurtdisiBireysel': '5.1. Yurt Dışı Bireysel Etkinlik',
      'yurticiiBireysel': '5.2. Yurt İçi Bireysel Etkinlik',
      'yurtdisiGrup': '5.3. Yurt Dışı Grup Etkinlik',
      'yurticiiGrup': '5.4. Yurt İçi Grup Etkinlik',
      'tasarim': '4.1. Tasarım',
    };
    return turAdlari[f['tur']] ?? f['tur'] ?? f['kategori'];
  }

  String _faaliyetDetay(Map<String, dynamic> f) {
    List<String> parcalar = [];
    if (f['adet'] != null && f['adet'] > 1)
      parcalar.add('${f['adet']} adet');
    if (f['kisi'] != null && f['kisi'] > 1)
      parcalar.add('${f['kisi']} kişi');
    if (f['quartile'] != null &&
        (f['tur'] == 'sciArastirma' || f['tur'] == 'sciDerleme'))
      parcalar.add(f['ahci'] == true ? 'AHCI' : f['quartile']);
    if (f['kategori'] == 'proje' && f['rol'] != null)
      parcalar.add(f['rol']);
    if (f['kategori'] == 'arastirma' && f['ay'] != null)
      parcalar.add('${f['ay']} ay');
    if (f['kategori'] == 'sergi' && f['tekrar'] == 2)
      parcalar.add('2. tekrar etkinlik');
    return parcalar.join(' · ');
  }

  Widget _sonucSatiri(String kategori, double puan) {
    final adlar = {
      'proje': '1. Proje (max 20)',
      'arastirma': '2. Araştırma (max 15)',
      'yayin': '3. Yayın (max 30)',
      'tasarim': '4. Tasarım (max 15)',
      'sergi': '5. Sergi (max 15)',
      'patent': '6. Patent (max 30)',
      'atif': '7. Atıf (max 30)',
      'teblig': '8. Tebliğ (max 20)',
      'odul': '9. Ödül (max 20)',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(adlar[kategori] ?? kategori,
              style: const TextStyle(fontSize: 13)),
          Text(puan.toStringAsFixed(2),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// FAAALİYET EKLEME / GÜNCELLEME
// ════════════════════════════════════════════════════════════════

class FaaliyetEkleSheet extends StatefulWidget {
  final String alan;
  final Map<String, dynamic>? mevcutFaaliyet;
  final Function(Map<String, dynamic>) onKaydet;

  const FaaliyetEkleSheet({
    super.key,
    required this.alan,
    required this.onKaydet,
    this.mevcutFaaliyet,
  });

  @override
  State<FaaliyetEkleSheet> createState() => _FaaliyetEkleSheetState();
}

class _FaaliyetEkleSheetState extends State<FaaliyetEkleSheet> {
  late String _kategori;
  late String _tur;
  late String _rol;
  late String _quartile;
  late bool _ahci;
  late int _kisi;
  late int _adet;
  late int _ay;
  late int _tekrar;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcutFaaliyet;
    _kategori = m?['kategori'] ?? 'yayin';
    _tur = m?['tur'] ?? (_kategori == 'teblig' ? 'uluslararasiTeblig' : 'sciArastirma');
    _rol = m?['rol'] ?? 'Yürütücü';
    _quartile = m?['quartile'] ?? 'Q1';
    _ahci = m?['ahci'] ?? false;
    _kisi = m?['kisi'] ?? 1;
    _adet = m?['adet'] ?? 1;
    _ay = m?['ay'] ?? 4;
    _tekrar = m?['tekrar'] ?? 1;
  }

  bool get _duzenlemeModu => widget.mevcutFaaliyet != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _duzenlemeModu ? 'Faaliyet Güncelle' : 'Faaliyet Ekle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _kategori,
              decoration: const InputDecoration(
                labelText: 'Faaliyet Kategorisi',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'yayin', child: Text('3. Yayın')),
                DropdownMenuItem(value: 'atif', child: Text('7. Atıf')),
                DropdownMenuItem(value: 'teblig', child: Text('8. Tebliğ')),
                DropdownMenuItem(value: 'proje', child: Text('1. Proje')),
                DropdownMenuItem(value: 'arastirma', child: Text('2. Araştırma')),
                DropdownMenuItem(value: 'patent', child: Text('6. Patent')),
                DropdownMenuItem(value: 'odul', child: Text('9. Ödül')),
                DropdownMenuItem(value: 'sergi', child: Text('5. Sergi')),
                DropdownMenuItem(value: 'tasarim', child: Text('4. Tasarım')),
              ],
              onChanged: (v) => setState(() {
                _kategori = v!;
                if (_kategori == 'yayin') _tur = 'sciArastirma';
                if (_kategori == 'atif') _tur = 'sci';
                if (_kategori == 'proje') _tur = '1001';
                if (_kategori == 'patent') _tur = 'uluslararasi';
                if (_kategori == 'odul') _tur = 'yurtdisiBilim';
                if (_kategori == 'sergi') _tur = 'yurtdisiBireysel';
                if (_kategori == 'teblig') _tur = 'uluslararasiTeblig';
                if (_kategori == 'arastirma') _tur = 'yurtdisi';
                if (_kategori == 'tasarim') _tur = 'tasarim';
                _adet = 1;
                _kisi = 1;
                _tekrar = 1;
              }),
            ),
            const SizedBox(height: 12),

            if (_kategori == 'yayin') ...[
              DropdownButtonFormField<String>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Yayın Türü',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'sciArastirma', child: Text('3.1. SCI/SSCI/AHCI Araştırma Makalesi')),
                  DropdownMenuItem(value: 'sciDerleme', child: Text('3.2. SCI/SSCI/AHCI Derleme Makale')),
                  DropdownMenuItem(value: 'alanEndeksi', child: Text('3.3. Alan Endeksi Makalesi')),
                  DropdownMenuItem(value: 'digerUlus', child: Text('3.4. Diğer Uluslararası Hakemli')),
                  DropdownMenuItem(value: 'ulakbim', child: Text('3.5. ULAKBİM TR Dizin')),
                  DropdownMenuItem(value: 'editSciExpanded', child: Text('3.6. SCI/SSCI/AHCI Editörlük')),
                  DropdownMenuItem(value: 'editAlan', child: Text('3.7. Alan Endeksi Editörlük')),
                  DropdownMenuItem(value: 'editDigerUlus', child: Text('3.8. Diğer Uluslararası Editörlük')),
                  DropdownMenuItem(value: 'editUlakbim', child: Text('3.9. ULAKBİM Editörlük')),
                  DropdownMenuItem(value: 'kitapUlusYazar', child: Text('3.10. Uluslararası Kitap (Yazar)')),
                  DropdownMenuItem(value: 'kitapUlusEditor', child: Text('3.11. Uluslararası Kitap (Editör)')),
                  DropdownMenuItem(value: 'kitapUlusBolum', child: Text('3.12. Uluslararası Kitap Bölümü')),
                  DropdownMenuItem(value: 'sesKisiselUlus', child: Text('3.15. Kişisel Ses/Görüntü (Uluslararası)')),
                  DropdownMenuItem(value: 'sesKarmaUlus', child: Text('3.16. Karma Ses/Görüntü (Uluslararası)')),
                  DropdownMenuItem(value: 'sesKisiselUlus2', child: Text('3.17. Kişisel Ses/Görüntü (Ulusal)')),
                ],
                onChanged: (v) => setState(() {
                  _tur = v!;
                  // Sabit oranlı satırlarda adet puanı etkilemez (m.7/4).
                  if (HesaplamaMotoru.sabitPuanliYayinTurleri.contains(_tur)) {
                    _adet = 1;
                  }
                }),
              ),
              if (HesaplamaMotoru.editorlukTurleri.contains(_tur)) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'm.7/4: Farklı dergilerde de olsa yalnızca bir editörlük '
                    'dikkate alınır. Birden fazla editörlük eklerseniz '
                    'toplamda yalnızca en yüksek oranlı olan sayılır.',
                    style: TextStyle(fontSize: 11, color: Colors.deepOrange),
                  ),
                ),
              ],
              if (_tur == 'sciArastirma' || _tur == 'sciDerleme') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _quartile,
                  decoration: const InputDecoration(
                    labelText: 'Dergi Çeyreği (Q)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['Q1', 'Q2', 'Q3', 'Q4']
                      .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                      .toList(),
                  onChanged: (v) => setState(() => _quartile = v!),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  dense: true,
                  title: const Text('AHCI kapsamında (katsayı: 0.5)'),
                  value: _ahci,
                  onChanged: (v) => setState(() => _ahci = v!),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
              if (!_tur.startsWith('edit') && !_tur.startsWith('ses')) ...[
                const SizedBox(height: 12),
                _kisiSecici(),
                const SizedBox(height: 12),
                _adetSecici('Makale/Kitap Adedi'),
              ],
            ],

            if (_kategori == 'atif') ...[
              DropdownButtonFormField<String>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Atıf Türü',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'sci', child: Text('7.1. SCI/SSCI/AHCI Makale Atfı')),
                  DropdownMenuItem(value: 'alan', child: Text('7.2. Alan Endeksi Makale Atfı')),
                  DropdownMenuItem(value: 'digerUlusAtif', child: Text('7.3. Diğer Uluslararası Makale Atfı')),
                  DropdownMenuItem(value: 'ulakbim', child: Text('7.4. ULAKBİM Makale Atfı')),
                  DropdownMenuItem(value: 'kitap', child: Text('7.5. Uluslararası Kitap Atfı')),
                  DropdownMenuItem(value: 'guzelUlus', child: Text('7.7. Güzel Sanat Uluslararası')),
                  DropdownMenuItem(value: 'guzelUlus2', child: Text('7.8. Güzel Sanat Ulusal')),
                ],
                onChanged: (v) => setState(() => _tur = v!),
              ),
              const SizedBox(height: 12),
              _adetSecici('Atıf Adedi'),
            ],

            if (_kategori == 'teblig') ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '8.1. Hakemli uluslararası bilimsel konferansta, sempozyumda veya kongrede sözlü olarak sunulan ve bunların kitabında yayımlanan tam bildiri',
                  style: TextStyle(fontSize: 12, color: Colors.indigo),
                ),
              ),
              const SizedBox(height: 12),
              _kisiSecici(),
              const SizedBox(height: 12),
              _adetSecici('Tebliğ Adedi'),
            ],

            if (_kategori == 'proje') ...[
              DropdownButtonFormField<String>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Proje Türü',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: '1001', child: Text('1.1. TÜBİTAK 1001/1003/1004/1007/1505/2244/3501/SAYEM/COST')),
                  DropdownMenuItem(value: '1005', child: Text('1.2. TÜBİTAK 1005/3001')),
                  DropdownMenuItem(value: 'H2020', child: Text('1.3. H2020 / Horizon Projesi')),
                  DropdownMenuItem(value: 'ulusUzel', child: Text('1.4. Diğer Uluslararası Proje')),
                  DropdownMenuItem(value: 'ulusOzel', child: Text('1.5. Diğer Ulusal Proje')),
                ],
                onChanged: (v) => setState(() => _tur = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _rol,
                decoration: const InputDecoration(
                  labelText: 'Projedeki Rol',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'Yürütücü', child: Text('Yürütücü (r = 1.0)')),
                  DropdownMenuItem(value: 'Araştırmacı', child: Text('Araştırmacı / Bursiyer (r = 0.5)')),
                ],
                onChanged: (v) => setState(() => _rol = v!),
              ),
              const SizedBox(height: 12),
              _adetSecici('Proje Adedi'),
            ],

            if (_kategori == 'arastirma') ...[
              DropdownButtonFormField<String>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Araştırma Türü',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'yurtdisi', child: Text('2.1. Yurt Dışı Araştırma')),
                  DropdownMenuItem(value: 'yurtici', child: Text('2.2. Yurt İçi Araştırma')),
                ],
                onChanged: (v) => setState(() => _tur = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Süre: '),
                  Expanded(
                    child: Slider(
                      value: _ay.toDouble(),
                      min: 4, max: 24, divisions: 20,
                      label: '$_ay ay',
                      onChanged: (v) => setState(() => _ay = v.round()),
                    ),
                  ),
                  Text('$_ay ay', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text('* Minimum 4 ay',
                    style: TextStyle(color: Colors.orange, fontSize: 11)),
              ),
            ],

            if (_kategori == 'patent') ...[
              DropdownButtonFormField<String>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Patent Türü',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'uluslararasi', child: Text('6.1. Uluslararası Patent')),
                  DropdownMenuItem(value: 'ulusal', child: Text('6.2. Ulusal Patent')),
                ],
                onChanged: (v) => setState(() => _tur = v!),
              ),
              const SizedBox(height: 12),
              _kisiSecici(),
              const SizedBox(height: 12),
              _adetSecici('Patent Adedi'),
            ],

            if (_kategori == 'odul') ...[
              DropdownButtonFormField<String>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Ödül Türü',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'yokTez', child: Text('9.1. YÖK Yılın Doktora Tezi Ödülü')),
                  DropdownMenuItem(value: 'tubitakBilim', child: Text('9.2. TÜBİTAK Bilim Ödülü')),
                  DropdownMenuItem(value: 'tubaAkademi', child: Text('9.3. TÜBA Akademi Ödülü')),
                  DropdownMenuItem(value: 'yurtdisiBilim', child: Text('9.4. Yurt Dışı Bilim Ödülü')),
                  DropdownMenuItem(value: 'yurticiiBilim', child: Text('9.5. Yurt İçi Bilim Ödülü')),
                  DropdownMenuItem(value: 'guzelUlusJuri', child: Text('9.6. Güzel Sanat Uluslararası Ödül')),
                  DropdownMenuItem(value: 'guzelUlasJuri', child: Text('9.7. Güzel Sanat Ulusal Ödül')),
                  DropdownMenuItem(value: 'mimarlik', child: Text('9.8. Mimarlık/Tasarım Yarışması')),
                ],
                onChanged: (v) => setState(() => _tur = v!),
              ),
              const SizedBox(height: 12),
              _kisiSecici(),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                    '* m.8/7: Ödül birden fazla kişiye verilmişse oran '
                    'kişi sayısına bölünür.',
                    style: TextStyle(color: Colors.orange, fontSize: 11)),
              ),
            ],

            if (_kategori == 'sergi') ...[
              DropdownButtonFormField<String>(
                value: _tur,
                decoration: const InputDecoration(
                  labelText: 'Sergi Türü',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'yurtdisiBireysel', child: Text('5.1. Yurt Dışı Bireysel Etkinlik')),
                  DropdownMenuItem(value: 'yurticiiBireysel', child: Text('5.2. Yurt İçi Bireysel Etkinlik')),
                  DropdownMenuItem(value: 'yurtdisiGrup', child: Text('5.3. Yurt Dışı Grup Etkinlik')),
                  DropdownMenuItem(value: 'yurticiiGrup', child: Text('5.4. Yurt İçi Grup Etkinlik')),
                ],
                onChanged: (v) => setState(() => _tur = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _tekrar,
                decoration: const InputDecoration(
                  labelText: 'Etkinlik Tekrarı',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                      value: 1, child: Text('İlk etkinlik (tam puan)')),
                  DropdownMenuItem(
                      value: 2,
                      child: Text('İkinci (tekrar) etkinlik (yarım puan)')),
                ],
                onChanged: (v) => setState(() => _tekrar = v!),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, top: 4, bottom: 4),
                child: Text(
                    '* m.7/6: Tekrarlayan faaliyetler için en çok iki etkinlik '
                    'dikkate alınır; ikinci tekrar etkinliğe öncekinin '
                    'puanının yarısı verilir.',
                    style: TextStyle(color: Colors.orange, fontSize: 11)),
              ),
            ],

            if (_kategori == 'tasarim') ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '4.1. Endüstriyel, çevresel (bina, peyzaj ve iç mekan) veya grafiksel tasarım; sahne, moda veya çalgı tasarımı',
                  style: TextStyle(fontSize: 12, color: Colors.brown),
                ),
              ),
              const SizedBox(height: 12),
              _kisiSecici(),
              const SizedBox(height: 12),
              _adetSecici('Tasarım Adedi'),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                    '* m.8/7: Tasarımın paylaşım oranı bulunmadığından oran '
                    'kişi sayısına bölünür.',
                    style: TextStyle(color: Colors.orange, fontSize: 11)),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  widget.onKaydet({
                    'kategori': _kategori,
                    'tur': _tur,
                    'kisi': _kisi,
                    'adet': _adet,
                    'rol': _rol,
                    'quartile': _quartile,
                    'ahci': _ahci,
                    'ay': _ay,
                    'tekrar': _tekrar,
                  });
                },
                icon: Icon(_duzenlemeModu ? Icons.save : Icons.add),
                label: Text(_duzenlemeModu ? 'Güncelle' : 'Ekle'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _kisiSecici() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Yazar / Kişi Sayısı:', style: TextStyle(fontSize: 13)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _kisi.toDouble(),
                min: 1, max: 15, divisions: 14,
                label: '$_kisi kişi',
                onChanged: (v) => setState(() => _kisi = v.round()),
              ),
            ),
            SizedBox(
              width: 65,
              child: Text('$_kisi kişi',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _adetSecici(String etiket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiket, style: const TextStyle(fontSize: 13)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _adet.toDouble(),
                min: 1, max: 30, divisions: 29,
                label: '$_adet adet',
                onChanged: (v) => setState(() => _adet = v.round()),
              ),
            ),
            SizedBox(
              width: 65,
              child: Text('$_adet adet',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}