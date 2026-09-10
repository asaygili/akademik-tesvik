// lib/puan_gostergesi.dart
//
// Teşvik puanını yüz puanlık ölçek üzerinde gösteren halka; ödeme için
// gereken otuz puanlık eşik (m.10/3) halka üzerinde işaretlenir.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'hesaplama_motoru.dart';
import 'tema.dart';

class PuanHalkasi extends StatelessWidget {
  final double puan;
  final double cap;

  const PuanHalkasi({super.key, required this.puan, this.cap = 116});

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme;
    final yeterli = puan >= HesaplamaMotoru.enAzTesvikPuani;
    final dolgu = yeterli ? renk.primary : renk.error;

    return SizedBox(
      width: cap,
      height: cap,
      child: CustomPaint(
        painter: _HalkaBoyayici(
          oran: (puan / 100).clamp(0.0, 1.0),
          esikOrani: HesaplamaMotoru.enAzTesvikPuani / 100,
          dolgu: dolgu,
          iz: renk.outlineVariant.withValues(alpha: 0.55),
          esik: renk.onSurfaceVariant,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Bicim.puan(puan),
                style: TextStyle(
                  fontSize: cap * 0.235,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: -0.8,
                  color: dolgu,
                ),
              ),
              Text(
                '/ 100 puan',
                style: TextStyle(
                  fontSize: cap * 0.088,
                  color: renk.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HalkaBoyayici extends CustomPainter {
  final double oran;
  final double esikOrani;
  final Color dolgu;
  final Color iz;
  final Color esik;

  _HalkaBoyayici({
    required this.oran,
    required this.esikOrani,
    required this.dolgu,
    required this.iz,
    required this.esik,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const kalinlik = 9.0;
    final merkez = Offset(size.width / 2, size.height / 2);
    final yaricap = (size.width - kalinlik) / 2;
    final cerceve = Rect.fromCircle(center: merkez, radius: yaricap);

    // Halkanın açık ucu altta; -220° ile +260° arası 280° tarar.
    const baslangic = 140 * math.pi / 180;
    const tarama = 260 * math.pi / 180;

    final izKalemi = Paint()
      ..color = iz
      ..style = PaintingStyle.stroke
      ..strokeWidth = kalinlik
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(cerceve, baslangic, tarama, false, izKalemi);

    if (oran > 0) {
      final dolguKalemi = Paint()
        ..color = dolgu
        ..style = PaintingStyle.stroke
        ..strokeWidth = kalinlik
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(cerceve, baslangic, tarama * oran, false, dolguKalemi);
    }

    // Otuz puanlık eşik işareti.
    final aci = baslangic + tarama * esikOrani;
    final ic = merkez +
        Offset(math.cos(aci), math.sin(aci)) * (yaricap - kalinlik / 2 - 1);
    final dis = merkez +
        Offset(math.cos(aci), math.sin(aci)) * (yaricap + kalinlik / 2 + 1);
    canvas.drawLine(
      ic,
      dis,
      Paint()
        ..color = esik
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HalkaBoyayici eski) =>
      eski.oran != oran ||
      eski.dolgu != dolgu ||
      eski.iz != iz ||
      eski.esik != esik;
}

/// Bir faaliyet türünün tavanına göre doluluk çubuğu.
class TavanCubugu extends StatelessWidget {
  final double puan;
  final double tavan;
  final Color renk;

  const TavanCubugu({
    super.key,
    required this.puan,
    required this.tavan,
    required this.renk,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: tavan == 0 ? 0 : (puan / tavan).clamp(0.0, 1.0),
        minHeight: 5,
        color: renk,
        backgroundColor: renk.withValues(alpha: 0.18),
      ),
    );
  }
}
