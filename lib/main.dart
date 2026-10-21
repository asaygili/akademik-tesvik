// lib/main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'gecmis_ekrani.dart';
import 'hesaplama_ekrani.dart';
import 'iletisim_ekrani.dart';
import 'tema.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('gecmis');
  runApp(const AkademikTesvik());
}

class AkademikTesvik extends StatelessWidget {
  const AkademikTesvik({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Web'de sekme başlığını belirler; index.html ile aynı kalmalı.
      title: 'Akademik Teşvik Hesaplama',
      debugShowCheckedModeBanner: false,
      theme: AkademikTema.acik(),
      darkTheme: AkademikTema.koyu(),
      themeMode: ThemeMode.system,
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  int _secilenSayfa = 0;
  Map<String, dynamic>? _duzenlenecekKayit;
  dynamic _duzenlenecekKey;

  void _gecmisteKayitDuzenle({
    required Map kayit,
    required dynamic key,
  }) {
    setState(() {
      _duzenlenecekKayit = Map<String, dynamic>.from(kayit);
      _duzenlenecekKey = key;
      _secilenSayfa = 0;
    });
  }

  void _duzenlemeTemizle() {
    setState(() {
      _duzenlenecekKayit = null;
      _duzenlenecekKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _secilenSayfa,
        children: [
          HesaplamaEkrani(
            duzenlenecekKayit: _duzenlenecekKayit,
            duzenlenecekKey: _duzenlenecekKey,
            onDuzenlemeTemizle: _duzenlemeTemizle,
          ),
          GecmisEkrani(
            onKayitDuzenle: _gecmisteKayitDuzenle,
          ),
          const IletisimEkrani(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _secilenSayfa,
        onDestinationSelected: (index) {
          setState(() => _secilenSayfa = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Hesapla',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'İletişim',
          ),
        ],
      ),
    );
  }
}
