// lib/aves_ekrani.dart
//
// AVES CV'den yayınları çekip seçilen yıla ait olanları faaliyet olarak
// eklemeye yarayan alt sayfa.

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'aves_servisi.dart';
import 'tema.dart';

class AvesYukleSheet extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> faaliyetler, String? unvan)
      onEkle;

  const AvesYukleSheet({super.key, required this.onEkle});

  @override
  State<AvesYukleSheet> createState() => _AvesYukleSheetState();
}

class _AvesYukleSheetState extends State<AvesYukleSheet> {
  static const _adresAnahtari = 'aves_adres';

  late final TextEditingController _adres = TextEditingController(
      text: Hive.box('gecmis').get(_adresAnahtari, defaultValue: '') as String);
  int _yil = DateTime.now().year;
  bool _yukleniyor = false;
  String? _hata;
  List<Map<String, dynamic>>? _tumu;
  String? _unvan;
  final Set<int> _secili = {};

  List<Map<String, dynamic>> get _yildakiler =>
      (_tumu ?? []).where((f) => f['yil'] == _yil).toList();

  @override
  void dispose() {
    _adres.dispose();
    super.dispose();
  }

  Future<void> _getir() async {
    if (_adres.text.trim().isEmpty) return;
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      final sonuc = await AvesServisi.cek(_adres.text);
      final liste = sonuc.faaliyetler;
      await Hive.box('gecmis').put(_adresAnahtari, _adres.text.trim());
      // OpenAlex atıf aramasında ad olarak kullanılır.
      if (sonuc.ad != null) {
        await Hive.box('gecmis').put('aves_ad_soyad', sonuc.ad);
      }
      setState(() {
        _tumu = liste;
        _unvan = sonuc.unvan;
        _yilSeciminiYenile();
        if (liste.isEmpty) _hata = 'Bu CV\'de teşvikte puan alan yayın bulunamadı.';
      });
    } catch (e) {
      setState(() => _hata = 'AVES\'ten çekilemedi: $e');
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _yilSeciminiYenile() {
    _secili
      ..clear()
      ..addAll(List.generate(_yildakiler.length, (i) => i));
  }

  String _ozet(Map<String, dynamic> f) => [
        if ((f['kisi'] as int) > 1) '${f['kisi']} kişi',
        if (f['quartile'] != null)
          f['ahci'] == true
              ? 'AHCI'
              : '${f['quartile']}${f['qBulunamadi'] == true ? ' (bulunamadı)' : ''}',
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final yildakiler = _yildakiler;
    final buYil = DateTime.now().year;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AVES CV\'den yükle',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Yayınlar AVES\'ten çekilir; seçtiğiniz yılda yayımlananlar '
            'teşvik türlerine göre eklenir. Kişi sayısı ve Q değerini '
            'ekledikten sonra düzenleyebilirsiniz.',
            style: TextStyle(fontSize: 12, color: renk.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _adres,
                    decoration: const InputDecoration(
                      labelText: 'AVES CV adresi',
                      hintText: 'asaygili.cv.nku.edu.tr',
                    ),
                    onSubmitted: (_) => _getir(),
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
                    onChanged: (y) => setState(() {
                      _yil = y!;
                      _yilSeciminiYenile();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _yukleniyor ? null : _getir,
                icon: _yukleniyor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.cloud_download_outlined, size: 20),
                label: Text(_tumu == null ? 'Yayınları getir' : 'Yeniden getir'),
              ),
            ),
          ],
          if (_hata != null) ...[
            const SizedBox(height: 8),
            Text(_hata!, style: TextStyle(color: renk.error, fontSize: 12.5)),
          ],
          if (_tumu != null && _tumu!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${_unvan == null ? '' : 'Unvan: $_unvan · '}'
              '$_yil: ${yildakiler.length} yayın '
              '(CV\'de toplam ${_tumu!.length} teşvik kapsamında yayın)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: yildakiler.length,
                itemBuilder: (_, i) {
                  final f = yildakiler[i];
                  final ozet = _ozet(f);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: _secili.contains(i),
                    onChanged: (v) => setState(
                        () => v! ? _secili.add(i) : _secili.remove(i)),
                    title: Text(FaaliyetTuru.ad(f),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      [if (ozet.isNotEmpty) ozet, f['kunye']].join('\n'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _secili.isEmpty
                    ? null
                    : () => widget.onEkle([
                          for (final i in _secili.toList()..sort())
                            yildakiler[i]
                        ], _unvan),
                icon: const Icon(Icons.add, size: 20),
                label: Text('${_secili.length} faaliyeti ekle'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
