import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/business_documents.dart';

String documentMoney(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return '${buffer.toString()} XOF';
}

String documentDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Fonts are bundled: PDF creation never downloads fonts or company data.
Future<Uint8List> buildBusinessPdf(BusinessDocument doc) async {
  if (doc.company.name.isEmpty) {
    throw StateError('Renseignez l’entreprise avant d’exporter.');
  }
  final regular = await rootBundle.load('assets/fonts/DejaVuSans.ttf');
  final bold = await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf');
  final pdf = pw.Document(
    title: doc.kind.label,
    author: doc.company.name,
    subject: doc.reference,
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      theme: pw.ThemeData.withFont(
        base: pw.Font.ttf(regular),
        bold: pw.Font.ttf(bold),
      ),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 12),
        child: pw.Text(
          'TradeFlow · ${doc.reference} · ${context.pageNumber}/${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 7),
        ),
      ),
      build: (context) => [
        pw.Text(
          doc.company.name,
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        for (final value in [
          doc.company.address,
          doc.company.country,
          doc.company.email,
          doc.company.phone,
          if (doc.company.registration.isNotEmpty)
            'Registre / identifiant : ${doc.company.registration}',
        ])
          if (value.isNotEmpty) pw.Text(value),
        pw.SizedBox(height: 24),
        pw.Text(
          doc.kind.label.toUpperCase(),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Référence : ${doc.reference}'),
        pw.Text('Date du document source : ${documentDate(doc.date)}'),
        pw.Text('État : ${doc.status}'),
        pw.SizedBox(height: 20),
        pw.Text(
          'Partenaire : ${doc.partner}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        if (doc.destination.isNotEmpty)
          pw.Text('Destination : ${doc.destination}'),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellPadding: const pw.EdgeInsets.all(8),
          headers: [
            'Produit',
            'Quantité',
            'Unité',
            if (doc.unitPrice != null) 'Prix unitaire',
            if (doc.total != null) 'Total produits',
          ],
          data: [
            [
              doc.product,
              '${doc.quantity}',
              doc.unit,
              if (doc.unitPrice != null) documentMoney(doc.unitPrice!),
              if (doc.total != null) documentMoney(doc.total!),
            ],
          ],
        ),
        pw.SizedBox(height: 16),
        for (final detail in doc.details)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Text(detail),
          ),
        if (doc.notes.isNotEmpty) ...[
          pw.SizedBox(height: 12),
          pw.Text(
            'Conditions / motif',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(doc.notes),
        ],
        pw.SizedBox(height: 20),
        pw.Text(
          doc.unitPrice != null
              ? 'Montants des produits uniquement. Transport et taxes non calculés. Ce document ne constate aucun paiement.'
              : 'Document de suivi des marchandises. Aucun paiement constaté.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ),
  );
  return pdf.save();
}
