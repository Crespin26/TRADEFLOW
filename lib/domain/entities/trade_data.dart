import '../business_documents.dart';
import '../commercial_models.dart';
import '../fulfilment_models.dart';
import 'product.dart';
import 'partner.dart';
import 'order.dart';
import 'stock.dart';

class TradeData {
  TradeData({
    List<Product> products = const [],
    this.company = const CompanyProfile(),
    this.catalogEnabled = false,
    List<String> categories = const [
      'Sans catégorie',
      'Agroalimentaire',
      'Textile',
      'Équipement',
    ],
    List<String> units = const [
      'pièce',
      'sac',
      'bidon',
      'carton',
      'kg',
      'litre',
    ],
    List<Contact> contacts = const [],
    List<TradeOrder> orders = const [],
    List<StockMovement> movements = const [],
    List<StockInventory> inventories = const [],
    List<TradeQuote> quotes = const [],
    List<PurchaseOrder> purchases = const [],
    List<CommercialEvent> commercialEvents = const [],
    List<DeliveryPlan> deliveryPlans = const [],
    List<BusinessDocument> issuedDocuments = const [],
  }) : categories = List.unmodifiable(categories),
       units = List.unmodifiable(units),
       products = List.unmodifiable(products),
       contacts = List.unmodifiable(contacts),
       orders = List.unmodifiable(orders),
       movements = List.unmodifiable(movements),
       inventories = List.unmodifiable(inventories),
       quotes = List.unmodifiable(quotes),
       purchases = List.unmodifiable(purchases),
       commercialEvents = List.unmodifiable(commercialEvents),
       deliveryPlans = List.unmodifiable(deliveryPlans),
       issuedDocuments = List.unmodifiable(issuedDocuments);
  final CompanyProfile company;
  final bool catalogEnabled;
  final List<String> categories, units;
  final List<Product> products;
  final List<Contact> contacts;
  final List<TradeOrder> orders;
  final List<StockMovement> movements;
  final List<StockInventory> inventories;
  final List<TradeQuote> quotes;
  final List<PurchaseOrder> purchases;
  final List<CommercialEvent> commercialEvents;
  final List<DeliveryPlan> deliveryPlans;
  final List<BusinessDocument> issuedDocuments;
  TradeData copyWith({
    CompanyProfile? company,
    bool? catalogEnabled,
    List<String>? categories,
    List<String>? units,
    List<Product>? products,
    List<Contact>? contacts,
    List<TradeOrder>? orders,
    List<StockMovement>? movements,
    List<StockInventory>? inventories,
    List<TradeQuote>? quotes,
    List<PurchaseOrder>? purchases,
    List<CommercialEvent>? commercialEvents,
    List<DeliveryPlan>? deliveryPlans,
    List<BusinessDocument>? issuedDocuments,
  }) => TradeData(
    company: company ?? this.company,
    catalogEnabled: catalogEnabled ?? this.catalogEnabled,
    categories: categories ?? this.categories,
    units: units ?? this.units,
    products: products ?? this.products,
    contacts: contacts ?? this.contacts,
    orders: orders ?? this.orders,
    movements: movements ?? this.movements,
    inventories: inventories ?? this.inventories,
    quotes: quotes ?? this.quotes,
    purchases: purchases ?? this.purchases,
    commercialEvents: commercialEvents ?? this.commercialEvents,
    deliveryPlans: deliveryPlans ?? this.deliveryPlans,
    issuedDocuments: issuedDocuments ?? this.issuedDocuments,
  );
  Map<String, dynamic> toJson() => {
    'version': 2,
    'company': company.toJson(),
    'catalogEnabled': catalogEnabled,
    'categories': categories,
    'units': units,
    'products': products.map((e) => e.toJson()).toList(),
    'contacts': contacts.map((e) => e.toJson()).toList(),
    'orders': orders.map((e) => e.toJson()).toList(),
    'movements': movements.map((e) => e.toJson()).toList(),
    'inventories': inventories.map((e) => e.toJson()).toList(),
    'quotes': quotes.map((e) => e.toJson()).toList(),
    'purchases': purchases.map((e) => e.toJson()).toList(),
    'commercialEvents': commercialEvents.map((e) => e.toJson()).toList(),
    'deliveryPlans': deliveryPlans.map((e) => e.toJson()).toList(),
    'issuedDocuments': issuedDocuments.map((e) => e.toJson()).toList(),
  };
  factory TradeData.fromJson(Map<String, dynamic> j) {
    if (j['version'] != 1 && j['version'] != 2) {
      throw const FormatException('Version de sauvegarde non prise en charge.');
    }
    return TradeData(
      company: j['company'] == null
          ? const CompanyProfile()
          : CompanyProfile.fromJson(j['company'] as Map<String, dynamic>),
      catalogEnabled: j['catalogEnabled'] as bool? ?? false,
      categories:
          (j['categories'] as List?)?.cast<String>() ??
          const ['Sans catégorie', 'Agroalimentaire', 'Textile', 'Équipement'],
      units:
          (j['units'] as List?)?.cast<String>() ??
          const ['pièce', 'sac', 'bidon', 'carton', 'kg', 'litre'],
      products: (j['products'] as List)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      contacts: (j['contacts'] as List)
          .map((e) => Contact.fromJson(e as Map<String, dynamic>))
          .toList(),
      orders: (j['orders'] as List)
          .map((e) => TradeOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      issuedDocuments: (j['issuedDocuments'] as List? ?? [])
          .map((e) => BusinessDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryPlans: (j['deliveryPlans'] as List? ?? [])
          .map((e) => DeliveryPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      quotes: (j['quotes'] as List? ?? [])
          .map((e) => TradeQuote.fromJson(e as Map<String, dynamic>))
          .toList(),
      purchases: (j['purchases'] as List? ?? [])
          .map((e) => PurchaseOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      commercialEvents: (j['commercialEvents'] as List? ?? [])
          .map((e) => CommercialEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      inventories: (j['inventories'] as List? ?? [])
          .map((e) => StockInventory.fromJson(e as Map<String, dynamic>))
          .toList(),
      movements: (j['movements'] as List)
          .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
