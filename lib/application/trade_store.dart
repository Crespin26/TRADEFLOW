import 'package:flutter/foundation.dart';

import '../domain/repositories.dart';
import '../domain/models.dart';
import '../domain/snapshot_validation.dart';
import '../domain/business_documents.dart';
import '../domain/catalog_photos.dart';
import '../domain/public_catalog.dart' show normalizeCatalogText;

import 'demo_data.dart';

part 'catalog_operations.dart';
part 'stock_operations.dart';
part 'partner_operations.dart';
part 'sales_operations.dart';
part 'commercial_support.dart';
part 'quote_operations.dart';
part 'purchase_operations.dart';
part 'fulfilment_operations.dart';
part 'document_operations.dart';

class TradeStore extends ChangeNotifier {
  TradeStore(TradeRepository repository) : _repository = repository;
  final TradeRepository _repository;
  TradeData _data = TradeData();
  TradeData get data => _data;
  bool _busy = false;
  bool get busy => _busy;
  bool _loaded = false;
  bool get loaded => _loaded;
  String? _loadError;
  String? get loadError => _loadError;
  int _sequence = 0;
  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    _loadError = null;
    notifyListeners();
    try {
      final next = await _repository.load();
      validateTradeData(next);
      _data = next;
      _loaded = true;
    } catch (_) {
      // Preserve the original saved data; never replace unreadable data silently.
      _loadError = 'Impossible de lire les données locales. Réessayez sans effacer le stockage.';
      _loaded = false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _commit(TradeData next) async {
    if (!_loaded) throw StateError('Les données ne sont pas chargées.');
    if (_busy) throw StateError('Une sauvegarde est déjà en cours.');
    validateTradeData(next);
    _busy = true;
    notifyListeners();
    try {
      // Publish the new state only after the complete snapshot has been saved.
      await _repository.save(next);
      _data = next;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _checkText(String text, String label) {
    if (text.trim().isEmpty) throw ArgumentError('$label est obligatoire.');
  }

  Future<void> loadDemo() async {
    if (_data.products.isNotEmpty ||
        _data.contacts.isNotEmpty ||
        _data.orders.isNotEmpty ||
        _data.movements.isNotEmpty ||
        _data.inventories.isNotEmpty ||
        _data.quotes.isNotEmpty ||
        _data.purchases.isNotEmpty ||
        _data.commercialEvents.isNotEmpty ||
        _data.deliveryPlans.isNotEmpty ||
        _data.issuedDocuments.isNotEmpty) {
      throw StateError('Les exemples sont réservés à un espace vide.');
    }
    await _commit(buildDemoData(_data, id: _id, now: DateTime.now()));
  }
}
