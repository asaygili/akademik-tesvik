// lib/pdf_rapor.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'hesaplama_motoru.dart';

class PdfRapor {
  static Future<void> olusturVeGoster({
    required String alan,
    required String unvan,
    required double enYuksekBrut,
    required List<Map<String, dynamic>> faaliyetler,
    required Map<String, double> sonuclar,
    required double toplamPuan,
    required double odeme,
  }) async {
    final pdf = pw.Document();

    // Türkçe karakter için font
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final Map<String, String> kategoriAdlari = {
      'proje': '1. Proje',
      'arastirma': '2. Araştırma',
      'yayin': '3. Yayın',
      'tasarim': '4. Tasarım',
      'sergi': '5. Sergi',
      'patent': '6. Patent',
      'atif': '7. Atıf',
      'teblig': '8. Tebliğ',
      'odul': '9. Ödül',
    };

    final Map<String, String> turAdlari = {
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

    final now = DateTime.now();
    final tarihStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    // Kategoriye göre faaliyetleri grupla
    final Map<String, List<Map<String, dynamic>>> gruplar = {};
    for (var f in faaliyetler) {
      String kat = f['kategori'];
      gruplar.putIfAbsent(kat, () => []);
      gruplar[kat]!.add(f);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'AKADEMİK TEŞVİK PUAN RAPORU',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 16,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text(
                  tarihStr,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.blue900, thickness: 1.5),
            pw.SizedBox(height: 4),
          ],
        ),
        build: (context) => [
          // ── Kişisel Bilgiler ──
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Kişisel Bilgiler',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 12,
                        color: PdfColors.blue900)),
                pw.SizedBox(height: 6),
                _pdfSatir(font, fontBold, 'Kadro Unvanı', unvan),
                _pdfSatir(font, fontBold, 'Bilim Alanı', _alanAdi(alan)),
                _pdfSatir(font, fontBold, 'En Yüksek Brüt Aylık',
                    '₺${enYuksekBrut.toStringAsFixed(2)}'),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          // ── Faaliyetler ──
          pw.Text('Faaliyetler',
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 13,
                  color: PdfColors.blue900)),
          pw.SizedBox(height: 8),

          // Kategori sırasına göre
          ...['proje', 'arastirma', 'yayin', 'tasarim', 'sergi',
              'patent', 'atif', 'teblig', 'odul']
              .where((k) => gruplar.containsKey(k))
              .map((kat) {
            final liste = gruplar[kat]!;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  color: PdfColors.blue100,
                  child: pw.Text(
                    kategoriAdlari[kat] ?? kat,
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: PdfColors.blue900),
                  ),
                ),
                pw.Table(
                  border: pw.TableBorder.all(
                      color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Başlık satırı
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        _thCell(fontBold, 'Faaliyet Türü'),
                        _thCell(fontBold, 'Detay'),
                        _thCell(fontBold, 'Hesaplama'),
                      ],
                    ),
                    // Veri satırları
                    ...liste.map((f) {
                      String aciklama =
                          HesaplamaMotoru.puanAciklamasi(
                              f: f, alan: alan);
                      String detay = _faaliyetDetayPdf(f);
                      return pw.TableRow(
                        children: [
                          _tdCell(font,
                              turAdlari[f['tur']] ?? f['tur'] ?? ''),
                          _tdCell(font, detay),
                          _tdCell(font, aciklama),
                        ],
                      );
                    }),
                  ],
                ),
                pw.SizedBox(height: 10),
              ],
            );
          }),

          pw.SizedBox(height: 8),

          // ── Sonuç Tablosu ──
          pw.Text('Puan Özeti',
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 13,
                  color: PdfColors.blue900)),
          pw.SizedBox(height: 6),
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _thCell(fontBold, 'Faaliyet Türü'),
                  _thCell(fontBold, 'Tavan'),
                  _thCell(fontBold, 'Puan'),
                ],
              ),
              ...[
                ['proje', '1. Proje', '20'],
                ['arastirma', '2. Araştırma', '15'],
                ['yayin', '3. Yayın', '30'],
                ['tasarim', '4. Tasarım', '15'],
                ['sergi', '5. Sergi', '15'],
                ['patent', '6. Patent', '30'],
                ['atif', '7. Atıf', '30'],
                ['teblig', '8. Tebliğ', '20'],
                ['odul', '9. Ödül', '20'],
              ].map((r) {
                double puan = sonuclar[r[0]] ?? 0;
                bool varMi = puan > 0;
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: varMi ? PdfColors.green50 : null,
                  ),
                  children: [
                    _tdCell(font, r[1]),
                    _tdCell(font, r[2]),
                    _tdCell(
                        varMi ? fontBold : font,
                        puan.toStringAsFixed(2),
                        color: varMi
                            ? PdfColors.green800
                            : PdfColors.grey500),
                  ],
                );
              }),
            ],
          ),

          pw.SizedBox(height: 12),

          // ── Toplam ve Ödeme ──
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: toplamPuan >= 30
                  ? PdfColors.green50
                  : PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: toplamPuan >= 30
                    ? PdfColors.green300
                    : PdfColors.red300,
              ),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOPLAM AKADEMİK TEŞVİK PUANI',
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 12)),
                    pw.Text(
                      '${toplamPuan.toStringAsFixed(2)} / 100',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 14,
                        color: toplamPuan >= 30
                            ? PdfColors.green800
                            : PdfColors.red800,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('AYLIK ÖDEME TUTARI',
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 12)),
                    pw.Text(
                      '₺${odeme.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 14,
                          color: PdfColors.blue800),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('YILLIK TOPLAM ÖDEME',
                        style:
                            pw.TextStyle(font: font, fontSize: 10)),
                    pw.Text(
                      '₺${(odeme * 12).toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 11,
                          color: PdfColors.blue800),
                    ),
                  ],
                ),
                if (toplamPuan < 30) ...[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '⚠ Yönetmelik m.10/3: Akademik teşvik ödeneğinin '
                    'ödenebilmesi için akademik teşvik puanının en az otuz '
                    'olması gerekir; bu nedenle ödeme tutarı 0 olarak '
                    'gösterilmiştir.',
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                        color: PdfColors.red700),
                  ),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // ── Formül Notu ──
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            color: PdfColors.grey100,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Hesaplama Formülü',
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 9,
                        color: PdfColors.grey700)),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Akademik Teşvik Ödemesi = En Yüksek Devlet Memuru Brüt Aylığı × Unvan Oranı × (Teşvik Puanı / 100)\n'
                  'En Yüksek Devlet Memuru Brüt Aylığı (m.3/ç) = 9.500 gösterge × memur aylık katsayısı  |  Ödeme için en az 30 teşvik puanı gerekir (m.10/3)\n'
                  'k: Kişi katsayısı  |  p: Dergi çeyrek katsayısı (Q1=1.0, Q2=0.8, Q3=0.5, Q4=0.25, AHCI=0.5)  |  r: Proje rol katsayısı (Yürütücü=1.0, Araştırmacı=0.5)\n'
                  'Unvan oranları: Profesör %100, Doçent %90, Dr. Öğr. Üyesi %80, Araştırma/Öğretim Görevlisi %70',
                  style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: PdfColors.grey700),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 8),
          pw.Text(
            'Bu rapor Akademik Teşvik Hesaplama uygulaması tarafından '
            '${tarihStr} tarihinde oluşturulmuştur. '
            'Resmi başvurularda ilgili komisyon kararları geçerlidir.',
            style: pw.TextStyle(
                font: font,
                fontSize: 7,
                color: PdfColors.grey500),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Akademik_Tesvik_Raporu_$tarihStr.pdf',
    );
  }

  static String _alanAdi(String alan) {
    switch (alan) {
      case 'A1': return 'A1 – Fen/Mühendislik/Sağlık/Ziraat/Eğitim';
      case 'A2': return 'A2 – Sosyal/Hukuk/İlahiyat/Filoloji/Spor';
      case 'A3': return 'A3 – Mimarlık/Planlama/Tasarım';
      case 'A4': return 'A4 – Güzel Sanatlar';
      default:   return alan;
    }
  }

  static String _faaliyetDetayPdf(Map<String, dynamic> f) {
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
    return parcalar.isEmpty ? '-' : parcalar.join(', ');
  }

  static pw.Widget _pdfSatir(
      pw.Font font, pw.Font fontBold, String etiket, String deger) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 160,
            child: pw.Text(etiket,
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfColors.grey700)),
          ),
          pw.Text(deger,
              style: pw.TextStyle(font: font, fontSize: 10)),
        ],
      ),
    );
  }

  static pw.Widget _thCell(pw.Font fontBold, String metin) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(metin,
          style: pw.TextStyle(
              font: fontBold,
              fontSize: 9,
              color: PdfColors.grey800)),
    );
  }

  static pw.Widget _tdCell(pw.Font font, String metin,
      {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(metin,
          style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: color ?? PdfColors.grey900)),
    );
  }
}