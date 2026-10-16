// lib/hesaplama_ekrani.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'aves_ekrani.dart';
import 'aves_servisi.dart';
import 'hesaplama_motoru.dart';
import 'katsayi_servisi.dart';
import 'pdf_rapor.dart';
import 'puan_gostergesi.dart';
import 'tema.dart';

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
  double _enYuksekBrut = KatsayiServisi.varsayilanBrutAylik;
  String _katsayiAciklama = '';
  bool _katsayiYuklendi = false;
  final List<Map<String, dynamic>> _faaliyetler = [];

  Map<String, double> _sonuclar = {};
  double _toplamPuan = 0;
  double _odeme = 0;
  bool _hesaplandimi = false;
  bool _duzenlemeModu = false;
  dynamic _duzenlenenKey;

  final ScrollController _kaydirmaKumandasi = ScrollController();
  final GlobalKey _sonucAnahtari = GlobalKey();

  @override
  void dispose() {
    _kaydirmaKumandasi.dispose();
    super.dispose();
  }

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
            (veri['enYuksekBrut'] as num?)?.toDouble() ??
            KatsayiServisi.varsayilanBrutAylik;
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
          (kayit['enYuksekBrut'] as num?)?.toDouble() ??
          KatsayiServisi.varsayilanBrutAylik;
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

    // Sonuç kartı katlamanın altında kaldığı için görünür alana getir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final baglam = _sonucAnahtari.currentContext;
      if (baglam != null) {
        Scrollable.ensureVisible(
          baglam,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.1,
        );
      }
    });
  }

  void _kaydet() {
    if (!_hesaplandimi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce hesaplayın.')),
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
          content: Text('Kayıt güncellendi.'),
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
          content: Text('Kayıt geçmişe eklendi.'),
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
        const SnackBar(content: Text('Önce hesaplayın.')),
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
            // AVES'ten gelen künye ve yıl bilgisi düzenlemede korunur.
            final eski = _faaliyetler[duzenleIndex];
            _faaliyetGuncelle(duzenleIndex, {
              for (final k in const ['kunye', 'yil', 'kaynak'])
                if (eski[k] != null) k: eski[k],
              ...f,
            });
          } else {
            _faaliyetEkle(f);
          }
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _avesDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AvesYukleSheet(
        onEkle: (liste, unvan) {
          final onceki = _faaliyetler.length;
          final (yeniListe, temizlenen) =
              AvesServisi.birlestir(_faaliyetler, liste);
          setState(() {
            _faaliyetler
              ..clear()
              ..addAll(yeniListe);
            if (unvan != null) _unvan = unvan;
            _hesaplandimi = false;
          });
          Navigator.pop(ctx);
          final eklenen = yeniListe.length - (temizlenen > 0 ? 0 : onceki);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text([
            if (temizlenen > 0)
              'Farklı kişinin CV\'si: önceki $temizlenen faaliyet temizlendi.',
            '$eklenen faaliyet AVES\'ten eklendi.',
            if (unvan != null) 'Unvan: $unvan.',
          ].join(' '))));
        },
      ),
    );
  }

  // ── Anlık kategori puanları (canlı geri bildirim) ────────────
  Map<String, double> get _anlikSonuclar => HesaplamaMotoru.toplamHesapla(
        alan: _alan,
        faaliyetler: _faaliyetler,
      );

  /// m.7/4: birden fazla editörlük girildiğinde toplama yalnızca en yüksek
  /// oranlı olan katılır; diğer satırlar listede sayılmadı olarak işaretlenir.
  bool _editorlukSayilmiyor(int index) {
    final f = _faaliyetler[index];
    if (f['kategori'] != 'yayin') return false;
    if (!HesaplamaMotoru.editorlukTurleri.contains(f['tur'])) return false;

    final benim = HesaplamaMotoru.faaliyetOrani(f: f, alan: _alan);
    for (int i = 0; i < _faaliyetler.length; i++) {
      final d = _faaliyetler[i];
      if (d['kategori'] != 'yayin') continue;
      if (!HesaplamaMotoru.editorlukTurleri.contains(d['tur'])) continue;
      final oran = HesaplamaMotoru.faaliyetOrani(f: d, alan: _alan);
      if (oran > benim || (oran == benim && i < index)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final renk = tema.colorScheme;
    final anlik = _anlikSonuclar;

    return Scaffold(
      appBar: AppBar(
        title: Text(_duzenlemeModu
            ? 'Kayıt düzenleniyor'
            : 'Akademik Teşvik'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF raporu oluştur',
            onPressed: _pdfOlustur,
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Formu sıfırla',
            onPressed: _sifirla,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        controller: _kaydirmaKumandasi,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_duzenlemeModu) _duzenlemeBanneri(),

            _bolumBasligi(
              'Unvan ve alan',
              'Ödeme oranı unvana, faaliyet çarpanları bilim alanına göre '
                  'belirlenir.',
            ),
            const SizedBox(height: 10),
            _kimlikKarti(),

            const SizedBox(height: 24),
            _bolumBasligi(
              'Faaliyetler',
              _faaliyetler.isEmpty
                  ? 'Yönetmelik Tablo 4 kapsamındaki faaliyetlerinizi ekleyin.'
                  : '${_faaliyetler.length} faaliyet · anlık toplam '
                      '${Bicim.puan(anlik['toplam'] ?? 0)} puan',
            ),
            const SizedBox(height: 10),

            if (_faaliyetler.isEmpty)
              _bosDurum()
            else
              ..._kategoriGruplari(anlik),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _faaliyetDialog,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Faaliyet ekle'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _avesDialog,
                    icon: const Icon(Icons.cloud_download_outlined, size: 20),
                    label: const Text('AVES CV\'den yükle'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _faaliyetler.isEmpty ? null : _hesapla,
                icon: const Icon(Icons.calculate_outlined, size: 20),
                label: const Text('Hesapla'),
              ),
            ),

            if (_hesaplandimi) ...[
              const SizedBox(height: 20),
              _sonucKarti(key: _sonucAnahtari),
            ] else if (_faaliyetler.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Ödeme tutarı için hesaplayın.',
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: renk.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bölüm başlığı ────────────────────────────────────────────
  Widget _bolumBasligi(String baslik, [String? aciklama]) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          baslik,
          style: tema.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (aciklama != null) ...[
          const SizedBox(height: 2),
          Text(
            aciklama,
            style: tema.textTheme.bodySmall
                ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  // ── Düzenleme modu banneri ───────────────────────────────────
  Widget _duzenlemeBanneri() {
    final renk = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: renk.tertiaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_outlined, size: 18, color: renk.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Geçmiş bir kayıt düzenleniyor. Değişikliklerden sonra tekrar '
              'hesaplayıp kaydedin.',
              style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: renk.onTertiaryContainer),
            ),
          ),
          TextButton(
            onPressed: _sifirla,
            child: const Text('Vazgeç'),
          ),
        ],
      ),
    );
  }

  // ── Unvan / alan / brüt aylık ────────────────────────────────
  Widget _kimlikKarti() {
    final renk = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _alan,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Bilim alanı'),
              selectedItemBuilder: (_) => BilimAlani.secili.values
                  .map((ad) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(ad,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              items: BilimAlani.kisa.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _alan = v!;
                _hesaplandimi = false;
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              // Unvan AVES'ten değişince açılır listenin de yenilenmesi için.
              key: ValueKey(_unvan),
              initialValue: _unvan,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kadro unvanı'),
              items: Unvan.oranlar.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                            '${e.key}  ·  ${(e.value * 100).round()}%',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _unvan = v!;
                _hesaplandimi = false;
              }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey(_enYuksekBrut),
              initialValue: Bicim.sayi(_enYuksekBrut),
              decoration: InputDecoration(
                labelText: 'En yüksek Devlet memuru brüt aylığı (₺)',
                helperText: _katsayiAciklama.isNotEmpty
                    ? _katsayiAciklama
                    : 'Güncel değer yükleniyor…',
                helperStyle: TextStyle(
                  color: renk.onSurfaceVariant,
                  fontSize: 11.5,
                  height: 1.3,
                ),
                suffixIcon: IconButton(
                  icon: Icon(Icons.sync,
                      size: 20,
                      color: _katsayiYuklendi ? renk.primary : null),
                  tooltip: 'Güncel değeri internetten çek',
                  onPressed: () => _katsayiYukle(zorla: true),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              onChanged: (v) {
                final ayiklanmis =
                    v.replaceAll('.', '').replaceAll(',', '.').trim();
                _enYuksekBrut =
                    double.tryParse(ayiklanmis) ?? _enYuksekBrut;
                if (_hesaplandimi) setState(() => _hesaplandimi = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Boş durum ────────────────────────────────────────────────
  Widget _bosDurum() {
    final renk = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        child: Column(
          children: [
            Icon(Icons.playlist_add_outlined,
                size: 40, color: renk.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Henüz faaliyet eklenmedi',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: renk.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Proje, yayın, atıf, tebliğ ve diğer faaliyet türlerini '
              'ekleyerek teşvik puanınızı hesaplayın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12.5, height: 1.4, color: renk.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  // ── Kategori kartları ────────────────────────────────────────
  List<Widget> _kategoriGruplari(Map<String, double> anlik) {
    final widgetlar = <Widget>[];

    for (final kat in Kategori.sirali) {
      final ilgili = _faaliyetler
          .where((f) => f['kategori'] == kat.anahtar)
          .toList();
      if (ilgili.isEmpty) continue;

      final puan = anlik[kat.anahtar] ?? 0;
      final doldu = puan >= kat.tavan - 0.005;

      widgetlar.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kategoriBasligi(kat, puan, doldu),
              const Divider(height: 1),
              for (int i = 0; i < ilgili.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 14, endIndent: 14),
                _faaliyetSatiri(
                  f: ilgili[i],
                  kat: kat,
                  index: _faaliyetler.indexOf(ilgili[i]),
                ),
              ],
            ],
          ),
        ),
      ));
    }

    return widgetlar;
  }

  Widget _kategoriBasligi(Kategori kat, double puan, bool doldu) {
    final renk = Theme.of(context).colorScheme;
    final vurgu = kat.vurgu(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      color: kat.zemin(context),
      child: Column(
        children: [
          Row(
            children: [
              Icon(kat.ikon, size: 18, color: vurgu),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  kat.numarali,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: vurgu,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Text(
                Bicim.puan(puan),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: vurgu,
                ),
              ),
              Text(
                ' / ${kat.tavan.toStringAsFixed(0)}',
                style: TextStyle(
                    fontSize: 12.5, color: renk.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TavanCubugu(puan: puan, tavan: kat.tavan, renk: vurgu),
          if (doldu) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: renk.onSurfaceVariant),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Bu faaliyet türünün tavanı doldu; fazlası toplama '
                    'eklenmez (m.8/3).',
                    style: TextStyle(
                        fontSize: 11, color: renk.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Faaliyet satırı ──────────────────────────────────────────
  Widget _faaliyetSatiri({
    required Map<String, dynamic> f,
    required Kategori kat,
    required int index,
  }) {
    final renk = Theme.of(context).colorScheme;
    final vurgu = kat.vurgu(context);
    final oran = HesaplamaMotoru.faaliyetOrani(f: f, alan: _alan);
    final puan = oran / 100 * kat.tavan;
    final aciklama = HesaplamaMotoru.puanAciklamasi(f: f, alan: _alan);
    final detay = _faaliyetDetay(f);
    final sayilmiyor = _editorlukSayilmiyor(index);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 6, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  FaaliyetTuru.ad(f),
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
                if (detay.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detay,
                    style: TextStyle(
                        fontSize: 11.5, color: renk.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 7),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.functions, size: 13, color: vurgu),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        aciklama,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.4,
                          color: renk.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                if (sayilmiyor) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.block, size: 12, color: renk.error),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Toplama katılmıyor: yalnızca bir editörlük '
                          'dikkate alınır (m.7/4).',
                          style: TextStyle(fontSize: 11, color: renk.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Bicim.puan(puan),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: sayilmiyor ? renk.onSurfaceVariant : vurgu,
                  decoration:
                      sayilmiyor ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                'puan',
                style:
                    TextStyle(fontSize: 10, color: renk.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 19),
                    color: renk.onSurfaceVariant,
                    tooltip: 'Düzenle',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _faaliyetDialog(duzenleIndex: index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 19),
                    color: renk.onSurfaceVariant,
                    tooltip: 'Sil',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _faaliyetSil(index),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sonuç kartı ──────────────────────────────────────────────
  Widget _sonucKarti({Key? key}) {
    final tema = Theme.of(context);
    final renk = tema.colorScheme;
    final yeterli = _toplamPuan >= HesaplamaMotoru.enAzTesvikPuani;
    final durumRengi = yeterli ? renk.primary : renk.error;

    final kirilim = Kategori.sirali
        .where((k) => (_sonuclar[k.anahtar] ?? 0) > 0)
        .toList();

    return Card(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sonuç',
              style: tema.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // ── Puan halkası ve ödeme durumu ──
            Row(
              children: [
                PuanHalkasi(puan: _toplamPuan),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: durumRengi.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              yeterli
                                  ? Icons.check_circle_outline
                                  : Icons.error_outline,
                              size: 14,
                              color: durumRengi,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              yeterli ? 'Ödemeye uygun' : 'Eşiğin altında',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: durumRengi,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        yeterli
                            ? 'Aylık ödeme'
                            : 'Ödeme için en az 30 puan gerekir (m.10/3)',
                        style: TextStyle(
                            fontSize: 12, color: renk.onSurfaceVariant),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Bicim.para(_odeme),
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: yeterli ? renk.onSurface : renk.error,
                        ),
                      ),
                      if (yeterli)
                        Text(
                          '12 ay · yıllık ${Bicim.para(_odeme * 12)}',
                          style: TextStyle(
                              fontSize: 11.5, color: renk.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 14),

            Text(
              'Faaliyet türlerine göre dağılım',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: renk.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final kat in kirilim) ...[
              _kirilimSatiri(kat, _sonuclar[kat.anahtar] ?? 0),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _kaydet,
                    icon: Icon(
                        _duzenlemeModu
                            ? Icons.update
                            : Icons.bookmark_add_outlined,
                        size: 19),
                    label: Text(_duzenlemeModu ? 'Güncelle' : 'Kaydet'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _pdfOlustur,
                    icon: const Icon(Icons.download_outlined, size: 19),
                    label: const Text('PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _kirilimSatiri(Kategori kat, double puan) {
    final renk = Theme.of(context).colorScheme;
    final vurgu = kat.vurgu(context);
    return Row(
      children: [
        Icon(kat.ikon, size: 15, color: vurgu),
        const SizedBox(width: 8),
        SizedBox(
          width: 74,
          child: Text(
            kat.ad,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: TavanCubugu(puan: puan, tavan: kat.tavan, renk: vurgu),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 62,
          child: Text(
            '${Bicim.puan(puan)} / ${kat.tavan.toStringAsFixed(0)}',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: renk.onSurface),
          ),
        ),
      ],
    );
  }

  String _faaliyetDetay(Map<String, dynamic> f) {
    final parcalar = <String>[];
    final kunye = f['kunye'] as String?;
    if (kunye != null) {
      parcalar.add(kunye.length > 90 ? '${kunye.substring(0, 90)}…' : kunye);
    }
    if (f['adet'] != null && f['adet'] > 1) {
      parcalar.add('${f['adet']} adet');
    }
    if (f['kisi'] != null && f['kisi'] > 1) {
      parcalar.add('${f['kisi']} kişi');
    }
    if (f['quartile'] != null &&
        (f['tur'] == 'sciArastirma' || f['tur'] == 'sciDerleme')) {
      parcalar.add(f['ahci'] == true ? 'AHCI' : f['quartile']);
    }
    if (f['kategori'] == 'proje' && f['rol'] != null) {
      parcalar.add(f['rol']);
    }
    if (f['kategori'] == 'arastirma' && f['ay'] != null) {
      parcalar.add('${f['ay']} ay');
    }
    if (f['kategori'] == 'sergi' && f['tekrar'] == 2) {
      parcalar.add('2. tekrar etkinlik');
    }
    return parcalar.join(' · ');
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
              initialValue: _kategori,
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
                initialValue: _tur,
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
              if (HesaplamaMotoru.editorlukTurleri.contains(_tur))
                _kuralNotu(
                    'm.7/4: Farklı dergilerde de olsa yalnızca bir editörlük '
                    'dikkate alınır. Birden fazla editörlük eklerseniz '
                    'toplamda yalnızca en yüksek oranlı olan sayılır.'),
              if (_tur == 'sciArastirma' || _tur == 'sciDerleme') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _quartile,
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
                initialValue: _tur,
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
              _bilgiNotu(
                  '8.1. Hakemli uluslararası bilimsel konferansta, '
                  'sempozyumda veya kongrede sözlü olarak sunulan ve '
                  'bunların kitabında yayımlanan tam bildiri.'),
              const SizedBox(height: 12),
              _kisiSecici(),
              const SizedBox(height: 12),
              _adetSecici('Tebliğ Adedi'),
            ],

            if (_kategori == 'proje') ...[
              DropdownButtonFormField<String>(
                initialValue: _tur,
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
                initialValue: _rol,
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
                initialValue: _tur,
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
              _kuralNotu('m.3/ş: Araştırma en az dört ay süreli '
                  'görevlendirmeyi gerektirir.'),
            ],

            if (_kategori == 'patent') ...[
              DropdownButtonFormField<String>(
                initialValue: _tur,
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
                initialValue: _tur,
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
              _kuralNotu('m.8/7: Ödül birden fazla kişiye verilmişse oran '
                  'kişi sayısına bölünür.'),
            ],

            if (_kategori == 'sergi') ...[
              DropdownButtonFormField<String>(
                initialValue: _tur,
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
                initialValue: _tekrar,
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
              _kuralNotu(
                  'm.7/6: Tekrarlayan faaliyetler için en çok iki etkinlik '
                  'dikkate alınır; ikinci tekrar etkinliğe öncekinin puanının '
                  'yarısı verilir.'),
            ],

            if (_kategori == 'tasarim') ...[
              _bilgiNotu(
                  '4.1. Endüstriyel, çevresel (bina, peyzaj ve iç mekan) '
                  'veya grafiksel tasarım; sahne, moda veya çalgı tasarımı.'),
              const SizedBox(height: 12),
              _kisiSecici(),
              const SizedBox(height: 12),
              _adetSecici('Tasarım Adedi'),
              _kuralNotu(
                  'm.8/7: Tasarımın paylaşım oranı bulunmadığından oran '
                  'kişi sayısına bölünür.'),
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

  /// Tablo 4 satır açıklaması için nötr bilgi kutusu.
  Widget _bilgiNotu(String metin) {
    final renk = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: renk.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        metin,
        style: TextStyle(
            fontSize: 12, height: 1.4, color: renk.onSurfaceVariant),
      ),
    );
  }

  /// Yönetmelik kuralına dair kısa hatırlatma.
  Widget _kuralNotu(String metin) {
    final renk = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 14, color: renk.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              metin,
              style: TextStyle(
                  fontSize: 11.5, height: 1.35, color: renk.onSurfaceVariant),
            ),
          ),
        ],
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