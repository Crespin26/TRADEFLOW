import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import '../domain/models.dart';
import '../domain/trade_store.dart';
import 'forms.dart';

const ink = Color(0xFF142C38);
const teal = Color(0xFF007F73);
const canvas = Color(0xFFF4F7F8);
String money(int value) =>
    '${NumberFormat.decimalPattern('fr').format(value)} F CFA';
String dateLabel(DateTime date) =>
    DateFormat('dd/MM/yyyy · HH:mm', 'fr').format(date.toLocal());

class TradeFlowApp extends StatelessWidget {
  const TradeFlowApp({super.key, required this.store});
  final TradeStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TradeFlow',
    debugShowCheckedModeBanner: false,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: teal,
        primary: teal,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: canvas,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    ),
    home: ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        if (store.loadError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(store.loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: store.busy ? null : store.load,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        if (!store.loaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return TradeShell(store: store);
      },
    ),
  );
}

class TradeShell extends StatefulWidget {
  const TradeShell({super.key, required this.store});
  final TradeStore store;
  @override
  State<TradeShell> createState() => _TradeShellState();
}

class _TradeShellState extends State<TradeShell> {
  int page = 0;
  String query = '';
  ContactKind? kind;
  OrderStatus? status;
  final search = TextEditingController();
  TradeStore get store => widget.store;
  TradeData get data => store.data;
  static const titles = [
    'Vue d’ensemble',
    'Produits & stocks',
    'Commandes',
    'Partenaires',
    'Mouvements',
  ];
  static const labels = [
    'Accueil',
    'Produits',
    'Commandes',
    'Contacts',
    'Historique',
  ];
  static const icons = [
    Icons.space_dashboard_outlined,
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
    Icons.people_outline,
    Icons.receipt_long_outlined,
  ];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void selectPage(int value) => setState(() {
    page = value;
    query = '';
    search.clear();
  });
  bool matches(String text) =>
      text.toLowerCase().contains(query.toLowerCase().trim());
  Future<void> action(Future<void> Function() callback) async {
    try {
      await callback();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final low = data.products.where((p) => p.lowStock).toList();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.swap_calls_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'TradeFlow',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -.7),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Alertes de stock',
            onPressed: () => showAlerts(context, low),
            icon: Badge(
              isLabelVisible: low.isNotEmpty,
              label: Text('${low.length}'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: page,
              onDestinationSelected: selectPage,
              labelType: NavigationRailLabelType.all,
              backgroundColor: canvas,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationRailDestination(
                    icon: Icon(icons[i]),
                    label: Text(labels[i]),
                  ),
              ],
            ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1160),
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 20,
                    16,
                    wide ? 32 : 20,
                    100,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                page == 0
                                    ? 'VOTRE ESPACE COMMERCIAL'
                                    : 'GESTION COMMERCIALE',
                                style: const TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 1.8,
                                  fontWeight: FontWeight.w700,
                                  color: teal,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                titles[page],
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: ink,
                                  letterSpacing: -.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (store.busy)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(
                          Icons.phone_android_rounded,
                          size: 14,
                          color: Colors.blueGrey,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Prototype local · XOF · Firebase non connecté',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (page > 0) ...[
                      TextField(
                        controller: search,
                        onChanged: (v) => setState(() => query = v),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher…',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ...switch (page) {
                      0 => dashboard(low),
                      1 => products(),
                      2 => orders(),
                      3 => contacts(),
                      _ => movements(),
                    },
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: page,
              onDestinationSelected: selectPage,
              destinations: [
                for (var i = 0; i < labels.length; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: labels[i]),
              ],
            ),
      floatingActionButton: page == 4
          ? null
          : FloatingActionButton.extended(
              onPressed: store.busy
                  ? null
                  : () => switch (page) {
                      1 => productForm(context, store),
                      3 => contactForm(context, store),
                      _ => orderForm(context, store),
                    },
              icon: const Icon(Icons.add),
              label: Text(switch (page) {
                1 => 'Nouveau produit',
                3 => 'Nouveau contact',
                _ => 'Nouvelle commande',
              }),
            ),
    );
  }

  List<Widget> dashboard(List<Product> low) {
    final open = data.orders
        .where(
          (o) =>
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.shipped,
        )
        .length;
    final delivered = data.orders
        .where((o) => o.status == OrderStatus.delivered)
        .fold(0, (s, o) => s + o.total);
    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF113C45), Color(0xFF007F73)],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.public_rounded,
              color: Color(0xFF8FE3C9),
              size: 36,
            ),
            const SizedBox(height: 20),
            const Text(
              'Votre commerce,\nen mouvement.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Stocks, commandes et partenaires.\nUne seule vue pour garder le cap.',
              style: TextStyle(color: Color(0xFFD1EAE5), height: 1.6),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => selectPage(2),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Voir les commandes'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 700 ? 4 : 2;
          final items = [
            (
              'Références produits',
              '${data.products.length}',
              Icons.inventory_2_outlined,
              teal,
            ),
            (
              'Commandes en cours',
              '$open',
              Icons.local_shipping_outlined,
              const Color(0xFF4672C4),
            ),
            (
              'Alertes de stock',
              '${low.length}',
              Icons.warning_amber_rounded,
              const Color(0xFFB96E14),
            ),
            ('Valeur livrée', money(delivered), Icons.task_alt_rounded, teal),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in items)
                SizedBox(
                  width: (constraints.maxWidth - (cols - 1) * 12) / cols,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(item.$3, color: item.$4),
                          const SizedBox(height: 16),
                          Text(
                            item.$2,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.$1,
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 24),
      if (data.products.isEmpty &&
          data.contacts.isEmpty &&
          data.orders.isEmpty) ...[
        panel(
          Icons.waving_hand_outlined,
          'Bienvenue dans TradeFlow',
          'Commencez par ajouter un produit et un client, puis créez votre première commande.',
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: store.busy ? null : () => action(store.loadDemo),
          icon: const Icon(Icons.science_outlined),
          label: const Text('Charger des exemples fictifs'),
        ),
      ],
      if (low.isNotEmpty) ...[
        section('À réapprovisionner', '${low.length} alerte(s)'),
        for (final p in low)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB96E14),
              ),
              title: Text(p.name),
              subtitle: Text(
                '${p.quantity} disponible(s) · seuil : ${p.threshold}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => stockForm(context, store, p),
            ),
          ),
        const SizedBox(height: 20),
      ],
      section('Dernières commandes', '${data.orders.length} au total'),
      if (data.orders.isEmpty)
        panel(
          Icons.local_shipping_outlined,
          'Votre prochaine expédition commence ici',
          'Les commandes apparaîtront après leur création.',
        ),
      for (final o in data.orders.take(3)) orderCard(o),
    ];
  }

  List<Widget> products() {
    final items = data.products
        .where((p) => matches('${p.name} ${p.sku}'))
        .toList();
    return [
      Text(
        '${items.length} produit(s) · Prix unitaires en XOF',
        style: const TextStyle(color: Colors.blueGrey),
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        panel(
          Icons.inventory_2_outlined,
          'Aucun produit à afficher',
          'Ajoutez un produit ou modifiez votre recherche.',
        ),
      for (final p in items)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.sku,
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ajuster le stock',
                      onPressed: store.busy
                          ? null
                          : () => stockForm(context, store, p),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(
                      money(p.price),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    pill(
                      '${p.quantity} en stock',
                      p.lowStock ? const Color(0xFFB96E14) : teal,
                    ),
                    Text(
                      'Seuil : ${p.threshold}',
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> orders() {
    final items = data.orders
        .where(
          (o) =>
              (status == null || status == o.status) &&
              matches(
                '${o.id} ${o.customerName} ${o.productName} ${o.destination}',
              ),
        )
        .toList();
    return [
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Toutes'),
            selected: status == null,
            onSelected: (_) => setState(() => status = null),
          ),
          for (final s in OrderStatus.values)
            ChoiceChip(
              label: Text(s.label),
              selected: status == s,
              onSelected: (_) => setState(() => status = s),
            ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        panel(
          Icons.local_shipping_outlined,
          'Aucune commande à afficher',
          'Ajoutez un produit et un client pour créer une commande.',
        ),
      for (final o in items) orderCard(o),
    ];
  }

  Widget orderCard(TradeOrder o) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  o.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: ink,
                  ),
                ),
              ),
              pill(
                o.status.label,
                o.status == OrderStatus.cancelled ? Colors.blueGrey : teal,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('${o.quantity} × ${o.productName}'),
          const SizedBox(height: 6),
          Text(o.destination, style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 12),
          Text(
            money(o.total),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateLabel(o.createdAt),
            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
          const SizedBox(height: 4),
          SelectableText(
            o.id,
            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
          ),
          if (o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.shipped) ...[
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: store.busy
                      ? null
                      : () => action(
                          () => store.changeOrderStatus(
                            o.id,
                            o.status == OrderStatus.confirmed
                                ? OrderStatus.shipped
                                : OrderStatus.delivered,
                          ),
                        ),
                  icon: Icon(
                    o.status == OrderStatus.confirmed
                        ? Icons.local_shipping_outlined
                        : Icons.task_alt,
                  ),
                  label: Text(
                    o.status == OrderStatus.confirmed
                        ? 'Expédier'
                        : 'Marquer livrée',
                  ),
                ),
                if (o.status == OrderStatus.confirmed)
                  TextButton(
                    onPressed: store.busy
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Annuler la commande ?'),
                                content: const Text(
                                  'Les quantités seront remises en stock.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Conserver'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Annuler la commande'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await action(
                                () => store.changeOrderStatus(
                                  o.id,
                                  OrderStatus.cancelled,
                                ),
                              );
                            }
                          },
                    child: const Text('Annuler'),
                  ),
              ],
            ),
          ],
        ],
      ),
    ),
  );

  List<Widget> contacts() {
    final items = data.contacts
        .where(
          (c) =>
              (kind == null || kind == c.kind) &&
              matches('${c.name} ${c.country} ${c.email} ${c.phone}'),
        )
        .toList();
    return [
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('Tous'),
            selected: kind == null,
            onSelected: (_) => setState(() => kind = null),
          ),
          ChoiceChip(
            label: const Text('Clients'),
            selected: kind == ContactKind.client,
            onSelected: (_) => setState(() => kind = ContactKind.client),
          ),
          ChoiceChip(
            label: const Text('Fournisseurs'),
            selected: kind == ContactKind.supplier,
            onSelected: (_) => setState(() => kind = ContactKind.supplier),
          ),
        ],
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        panel(
          Icons.people_outline,
          'Aucun partenaire à afficher',
          'Centralisez ici vos clients et fournisseurs.',
        ),
      for (final c in items)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: teal.withValues(alpha: .08),
                      child: Icon(
                        c.kind == ContactKind.client
                            ? Icons.person_outline
                            : Icons.business_outlined,
                        color: teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        c.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                pill(
                  c.kind == ContactKind.client ? 'Client' : 'Fournisseur',
                  teal,
                ),
                const SizedBox(height: 8),
                Text(c.country),
                if (c.email.isNotEmpty) SelectableText(c.email),
                if (c.phone.isNotEmpty) SelectableText(c.phone),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> movements() {
    final items = data.movements
        .where((m) => matches('${m.productName} ${m.reason}'))
        .toList();
    return [
      const Text(
        'Entrées et sorties de stock · historique local',
        style: TextStyle(color: Colors.blueGrey),
      ),
      const SizedBox(height: 12),
      if (items.isEmpty)
        panel(
          Icons.receipt_long_outlined,
          'Aucun mouvement à afficher',
          'Les stocks initiaux, ajustements et commandes alimentent cet historique.',
        ),
      for (final m in items)
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              m.delta > 0 ? Icons.south_west : Icons.north_east,
              color: m.delta > 0 ? teal : const Color(0xFFB96E14),
            ),
            title: Text(
              m.productName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${m.reason}\n${dateLabel(m.createdAt)}'),
            isThreeLine: true,
            trailing: Text(
              '${m.delta > 0 ? '+' : ''}${m.delta}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ),
    ];
  }

  void showAlerts(BuildContext context, List<Product> low) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .65,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  const Text(
                    'Alertes de stock',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Alertes calculées sur cet appareil. Les notifications push ne sont pas encore activées.',
                  ),
                  const SizedBox(height: 16),
                  if (low.isEmpty)
                    const Text(
                      'Tous vos stocks sont au-dessus des seuils définis.',
                    ),
                  for (final p in low)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.warning_amber,
                        color: Color(0xFFB96E14),
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.quantity} disponible(s) · seuil : ${p.threshold}',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}

Widget pill(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  decoration: BoxDecoration(
    color: color.withValues(alpha: .09),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    label,
    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700),
  ),
);
Widget section(String title, String detail) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 16,
    runSpacing: 4,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 19,
          color: ink,
        ),
      ),
      Text(
        detail,
        style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
      ),
    ],
  ),
);
Widget panel(IconData icon, String title, String description) => Card(
  margin: EdgeInsets.zero,
  child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Icon(icon, color: teal, size: 36),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.blueGrey, height: 1.5),
        ),
      ],
    ),
  ),
);
