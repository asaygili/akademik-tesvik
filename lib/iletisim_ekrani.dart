// lib/iletisim_ekrani.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class IletisimEkrani extends StatefulWidget {
  const IletisimEkrani({super.key});

  @override
  State<IletisimEkrani> createState() => _IletisimEkraniState();
}

class _IletisimEkraniState extends State<IletisimEkrani> {
  final _formKey = GlobalKey<FormState>();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _epostaController = TextEditingController();
  final _konuController = TextEditingController();
  final _mesajController = TextEditingController();

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _epostaController.dispose();
    _konuController.dispose();
    _mesajController.dispose();
    super.dispose();
  }

  Future<void> _gonder() async {
    if (!_formKey.currentState!.validate()) return;

    final ad = _adController.text.trim();
    final soyad = _soyadController.text.trim();
    final eposta = _epostaController.text.trim();
    final konu = _konuController.text.trim();
    final mesaj = _mesajController.text.trim();

    final body =
        'Ad Soyad: $ad $soyad\nE-posta: $eposta\n\n$mesaj';

    final uri = Uri(
      scheme: 'mailto',
      path: 'tesvikakademik@gmail.com',
      queryParameters: {
        'subject': '[Akademik Teşvik] $konu',
        'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'E-posta uygulaması açılamadı. Lütfen '
                'tesvikakademik@gmail.com adresine yazın.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _temizle() {
    _adController.clear();
    _soyadController.clear();
    _epostaController.clear();
    _konuController.clear();
    _mesajController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('İletişim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Formu temizle',
            onPressed: _temizle,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Bilgi kartı ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: renk.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: renk.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: renk.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Görüş ve Önerileriniz',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: renk.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Uygulama ile ilgili görüş, öneri ve hata '
                      'bildirimlerinizi aşağıdaki form aracılığıyla '
                      'iletebilirsiniz. Mesajınız e-posta olarak '
                      'gönderilecektir.',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: renk.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.email_outlined,
                            size: 13, color: renk.primary),
                        const SizedBox(width: 4),
                        Text(
                          'tesvikakademik@gmail.com',
                          style: TextStyle(
                              fontSize: 12,
                              color: renk.primary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Ad Soyad ──
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _adController,
                      decoration: const InputDecoration(
                        labelText: 'Ad *',
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ad gerekli'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _soyadController,
                      decoration: const InputDecoration(
                        labelText: 'Soyad *',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Soyad gerekli'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── E-posta ──
              TextFormField(
                controller: _epostaController,
                decoration: const InputDecoration(
                  labelText: 'E-posta *',
                  prefixIcon: Icon(Icons.email_outlined, size: 20),
                  hintText: 'ornek@universite.edu.tr',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'E-posta gerekli';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Geçerli bir e-posta girin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // ── Konu ──
              TextFormField(
                controller: _konuController,
                decoration: const InputDecoration(
                  labelText: 'Konu *',
                  prefixIcon: Icon(Icons.subject_outlined, size: 20),
                  hintText: 'Örn. hata bildirimi, öneri…',
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Konu gerekli'
                    : null,
              ),

              const SizedBox(height: 12),

              // ── Mesaj ──
              TextFormField(
                controller: _mesajController,
                decoration: const InputDecoration(
                  labelText: 'Mesaj *',
                  alignLabelWithHint: true,
                  hintText: 'Görüş ve önerilerinizi buraya yazınız…',
                ),
                maxLines: 6,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Mesaj gerekli';
                  }
                  if (v.trim().length < 10) {
                    return 'Mesaj en az 10 karakter olmalı';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Gönder butonu ──
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _gonder,
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Gönder',
                      style: TextStyle(fontSize: 16)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Alt not ──
              Center(
                child: Text(
                  '* Zorunlu alanlar',
                  style: TextStyle(
                      color: renk.onSurfaceVariant, fontSize: 11),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}