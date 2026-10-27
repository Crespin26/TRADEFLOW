import 'models.dart';
import 'business_documents.dart';

List<BusinessDocument> businessDocuments(TradeData data) {
  final docs = <BusinessDocument>[];
  for (final q in data.quotes) {
    docs.add(
      BusinessDocument(
        kind: BusinessDocumentKind.quote,
        sourceId: q.id,
        revision: q.revision,
        date: q.createdAt,
        partner: q.customerName,
        product: q.productName,
        quantity: q.quantity,
        unit: q.unit,
        unitPrice: q.unitPrice,
        status: q.status.label,
        company: data.company,
        destination: q.destination,
        notes: q.notes,
        details: ['Validité : ${_date(q.expiresAt)} incluse'],
      ),
    );
  }
  for (final o in data.orders) {
    for (final kind in [
      BusinessDocumentKind.sale,
      if (o.status != OrderStatus.cancelled) BusinessDocumentKind.proforma,
    ]) {
      docs.add(
        BusinessDocument(
          kind: kind,
          sourceId: o.id,
          revision: o.revision,
          date: o.createdAt,
          partner: o.customerName,
          product: o.productName,
          quantity: o.quantity,
          unit: o.unit,
          unitPrice: o.unitPrice,
          status: o.status.label,
          company: data.company,
          destination: o.destination,
          details: [
            'Livré : ${o.deliveredQuantity}/${o.quantity}',
            'Retourné : ${o.returnedQuantity}',
            if (o.quoteId != null) 'Devis : ${o.quoteId}',
            if (kind == BusinessDocumentKind.proforma)
              'PRO FORMA — aucun paiement constaté par ce document.',
          ],
        ),
      );
    }
  }
  for (final p in data.purchases) {
    docs.add(
      BusinessDocument(
        kind: BusinessDocumentKind.purchase,
        sourceId: p.id,
        revision: p.revision,
        date: p.createdAt,
        partner: p.supplierName,
        product: p.productName,
        quantity: p.quantity,
        unit: p.unit,
        unitPrice: p.unitPrice,
        status: p.status.label,
        company: data.company,
        destination: p.destination,
        notes: p.notes,
        details: [
          'Reçu : ${p.receivedQuantity}/${p.quantity}',
          'Retourné : ${p.returnedQuantity}',
        ],
      ),
    );
  }
  for (final e in data.commercialEvents) {
    final kind = switch (e.kind) {
      CommercialEventKind.receipt => BusinessDocumentKind.receipt,
      CommercialEventKind.delivery => BusinessDocumentKind.delivery,
      CommercialEventKind.customerReturn => BusinessDocumentKind.customerReturn,
      CommercialEventKind.supplierReturn => BusinessDocumentKind.supplierReturn,
    };
    final order = data.orders.where((o) => o.id == e.documentId).firstOrNull;
    final purchase = data.purchases
        .where((p) => p.id == e.documentId)
        .firstOrNull;
    docs.add(
      BusinessDocument(
        kind: kind,
        sourceId: e.id,
        revision: 0,
        date: e.createdAt,
        partner: e.partnerName,
        product: e.productName,
        quantity: e.quantity,
        unit: e.unit,
        status: 'Enregistré',
        company: data.company,
        destination: order?.destination ?? purchase?.destination ?? '',
        notes: e.reason,
        details: [
          'Document source : ${e.documentId}',
          if (e.carrier.isNotEmpty) 'Transporteur : ${e.carrier}',
          if (e.trackingNumber.isNotEmpty) 'Suivi : ${e.trackingNumber}',
          if (e.kind == CommercialEventKind.customerReturn)
            e.restocked
                ? 'Réintégré au stock disponible'
                : 'Hors stock disponible',
        ],
      ),
    );
  }
  final archivedRefs = data.issuedDocuments.map((d) => d.reference).toSet();
  docs.removeWhere((d) => archivedRefs.contains(d.reference));
  docs.addAll(data.issuedDocuments);
  docs.sort((a, b) => b.date.compareTo(a.date));
  return List.unmodifiable(docs);
}

String _date(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
