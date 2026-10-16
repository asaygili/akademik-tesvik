// lib/openalex_ekrani.dart
//
// Seçilen yılda kişinin yayınlarına yapılan atıfları OpenAlex'ten getirip
// atıf faaliyeti olarak eklemeye yarayan alt sayfa.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'openalex_servisi.dart';
import 'tema.dart';

class OpenAlexAtifSheet extends StatefulWidget {
  /// Eklenecek atıf faaliyetleri ve yılı.
  final void Function(List<Map<String, dynamic>> atiflar, int yil) onEkle;

  const OpenAlexAtifSheet({super.key, required this.onEkle});

  @override
  State<OpenAlexAtifSheet> createState() => _OpenAlexAtifSheetState();
}

class _OpenAlexAtifSheetState extends State<OpenAlexAtifSheet> {
  static const adAnahtari = 'openalex_ad';
  static const _turSirasi = ['sci', 'digerUlusAtif', 'kitap'];

  late final TextEditingController _ad = TextEditingController(
      text: (Hive.box('gecmis').get(adAnahtari) ??
          Hive.box('gecmis').get('aves_ad_soyad') ??
          '') as String);
  int _yil = DateTime.now().year;
  bool _yukleniyor = false;
  String? _hata;
  List<OpenAlexYazar> _adaylar = [];
  OpenAlexYazar? _yazar;
  AtifSonucu? _sonuc;

  @override
  void dispose() {
    _ad.dispose();
    super.dispose();
  }

  Future<void> _calistir(Future<void> Function() is_) async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      await is_();
    } catch (e) {
      setState(() => _hata = 'OpenAlex\'ten çekilemedi: $e');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _ara() => _calistir(() async {
        final ad = _ad.text.trim();
        if (ad.isEmpty) return;
        final adaylar = await OpenAlexServisi.yazarAra(ad);
        await Hive.box('gecmis').put(adAnahtari, ad);
        setState(() {
          _adaylar = adaylar;
          _yazar = adaylar.isEmpty ? null : adaylar.first;
          _sonuc = null;
          if (adaylar.isEmpty) _hata = 'OpenAlex\'te bu ada ait yazar bulunamadı.';
        });
        if (_yazar != null) await _atiflariGetir();
      });

  Future<void> _atiflariGetir() async {
    final sonuc = await OpenAlexServisi.atiflar(_yazar!.id, _yil);
    setState(() => _sonuc = sonuc);
  }

  List<Map<String, dynamic>> get _faaliyetler => [
        for (final tur in _turSirasi)
          if ((_sonuc?.sayilar[tur] ?? 0) > 0)
            {
              'kategori': 'atif',
              'tur': tur,
              'adet': _sonuc!.sayilar[tur],
              'yil': _yil,
              'kaynak': 'OpenAlex',
              'kunye': 'OpenAlex: ${_yazar!.ad} · $_yil atıfları',
            },
      ];

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final buYil = DateTime.now().year;
    final faaliyetler = _faaliyetler;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Atıfları OpenAlex\'ten getir',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Seçilen yılda yayınlarınıza yapılan atıflar sayılır; öz atıflar '
            've dergi/kitap dışı kaynaklar (ön baskı, tez, bildiri) çıkarılır. '
            'SCI/SSCI/AHCI ayrımı YÖK dergi listesiyle yapılır. ESCI, Scopus '
            've TR Dizin ayırt edilemediğinden "diğer uluslararası" sayılır; '
            'ekledikten sonra düzenleyebilirsiniz.',
            style: TextStyle(fontSize: 12, color: renk.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ad,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    hintText: 'Ahmet Saygılı',
                  ),
                  onSubmitted: (_) => _ara(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 110,
                child: DropdownButtonFormField<int>(
                  initialValue: _yil,
                  decoration: const InputDecoration(labelText: 'Yıl'),
                  items: [
                    for (var y = buYil; y >= buYil - 15; y--)
                      DropdownMenuItem(value: y, child: Text('$y')),
                  ],
                  onChanged: (y) {
                    _yil = y!;
                    if (_yazar != null) _calistir(_atiflariGetir);
                  },
                ),
              ),
            ],
          ),
          if (_adaylar.length > 1) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<OpenAlexYazar>(
              key: ValueKey(_adaylar),
              initialValue: _yazar,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'OpenAlex yazarı'),
              items: [
                for (final a in _adaylar)
                  DropdownMenuItem(
                      value: a,
                      child: Text('$a',
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (a) {
                _yazar = a;
                _calistir(_atiflariGetir);
              },
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _yukleniyor ? null : _ara,
              icon: _yukleniyor
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.format_quote_outlined, size: 20),
              label: Text(_sonuc == null ? 'Atıfları getir' : 'Yeniden getir'),
            ),
          ),
          if (_hata != null) ...[
            const SizedBox(height: 8),
            Text(_hata!, style: TextStyle(color: renk.error, fontSize: 12.5)),
          ],
          if (_sonuc != null && !_yukleniyor) ...[
            const SizedBox(height: 12),
            Text('${_yazar!.ad} · $_yil',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            for (final tur in _turSirasi)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(FaaliyetTuru.adlar[tur] ?? tur,
                            style: const TextStyle(fontSize: 13))),
                    Text('${_sonuc!.sayilar[tur] ?? 0}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Text(
              'Sayılmayan: ${_sonuc!.ozAtif} öz atıf, '
              '${_sonuc!.atlanan} dergi/kitap dışı kaynak.',
              style: TextStyle(fontSize: 11.5, color: renk.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: faaliyetler.isEmpty
                    ? null
                    : () => widget.onEkle(faaliyetler, _yil),
                icon: const Icon(Icons.add, size: 20),
                label: Text(faaliyetler.isEmpty
                    ? 'Bu yılda atıf yok'
                    : 'Atıfları ekle'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
