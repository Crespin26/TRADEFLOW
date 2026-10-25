import 'package:flutter/material.dart';

import 'demo_profile.dart';
import 'design_system/components.dart';
import 'design_system/theme.dart';
import 'foundation_gallery.dart';
import 'catalog/catalog_page.dart';
import 'catalog/public_home.dart';
import 'shopping/shopping_scope.dart';
import 'shopping/cart_page.dart';
import 'shopping/account_page.dart';
import 'customer/customer_home.dart';
import 'customer/customer_orders.dart';

class FoundationShell extends StatefulWidget {
  const FoundationShell({super.key, required this.managementBuilder});
  final WidgetBuilder managementBuilder;
  @override
  State<FoundationShell> createState() => _FoundationShellState();
}

class _FoundationShellState extends State<FoundationShell> {
  DemoProfile profile = DemoProfile.visitor;
  String selectedLabel = 'Accueil';
  bool followCustomerSession = true;
  DemoProfile displayedProfile(bool connected) =>
      followCustomerSession && connected ? DemoProfile.client : profile;
  String? catalogCategory;

  Future<void> chooseProfile() async {
    final activeProfile = displayedProfile(
      ShoppingScope.of(context).customerReady,
    );
    final choice = await showModalBottomSheet<DemoProfile>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: ListView(
            key: const ValueKey('demo-profiles-scroll'),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Text(
                'Explorer les profils',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Simulation d’interface uniquement. Aucun compte n’est connecté et aucune permission réelle n’est accordée.',
              ),
              const SizedBox(height: 16),
              for (final role in DemoProfile.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(role.icon),
                  title: Text(role.label),
                  subtitle: Text(role.description),
                  trailing: activeProfile == role
                      ? const Icon(
                          Icons.check_circle,
                          color: FlowColors.primary,
                        )
                      : null,
                  onTap: () => Navigator.pop(context, role),
                ),
            ],
          ),
        ),
      ),
    );
    if (choice != null && mounted) {
      setState(() {
        profile = choice;
        followCustomerSession = false;
        selectedLabel = destinationsFor(choice).first.label;
        catalogCategory = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopping = ShoppingScope.of(context);
    final activeProfile = displayedProfile(shopping.customerReady);
    final destinations = destinationsFor(activeProfile);
    final selected = destinations
        .indexWhere((d) => d.label == selectedLabel)
        .clamp(0, destinations.length - 1);
    final destination = destinations[selected];
    final wide = MediaQuery.sizeOf(context).width >= FlowLayout.railBreakpoint;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_calls_rounded, color: FlowColors.primary, size: 30),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'TradeFlow',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mon compte de démonstration',
            icon: Badge(
              isLabelVisible: shopping.unreadNoticeCount > 0,
              label: Text('${shopping.unreadNoticeCount}'),
              child: const Icon(Icons.person_outline),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const DemoAccountPage()),
            ),
          ),
          IconButton(
            tooltip: 'Guide des composants',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const FoundationGallery(),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Changer de profil de démonstration',
            onPressed: chooseProfile,
            icon: const Icon(Icons.switch_account_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: const Color(0xFFE5F2EF),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 18,
                    color: FlowColors.primary,
                  ),
                  Text(
                    'Démonstration · ${activeProfile.label}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    shopping.customerReady
                        ? 'Session client simulée'
                        : shopping.signedIn
                        ? 'Vérification simulée à terminer'
                        : 'Authentification non connectée',
                    style: TextStyle(color: FlowColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  if (wide)
                    NavigationRail(
                      extended: true,
                      minExtendedWidth: 200,
                      selectedIndex: selected,
                      onDestinationSelected: (i) =>
                          setState(() => selectedLabel = destinations[i].label),
                      destinations: [
                        for (final item in destinations)
                          NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ),
                      ],
                    ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: FlowLayout.contentWidth,
                        ),
                        child: ListView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          key: ValueKey('space-${destination.label}'),
                          padding: EdgeInsets.all(wide ? 32 : 20),
                          children: [
                            Text(
                              activeProfile.space.toUpperCase(),
                              style: const TextStyle(
                                color: FlowColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selected == 0 &&
                                      activeProfile == DemoProfile.visitor
                                  ? 'Le commerce,\nà portée de main.'
                                  : destination.label,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              destination.description,
                              style: const TextStyle(
                                color: FlowColors.muted,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (selected == 0 &&
                                activeProfile == DemoProfile.visitor)
                              PublicHome(
                                onCatalog: (category) => setState(() {
                                  catalogCategory = category;
                                  selectedLabel = 'Catalogue';
                                }),
                              )
                            else if (activeProfile == DemoProfile.client &&
                                selected == 0)
                              CustomerHome(
                                onBrowse: () =>
                                    setState(() => selectedLabel = 'Catalogue'),
                              )
                            else if (activeProfile == DemoProfile.client &&
                                destination.label == 'Commandes')
                              const CustomerOrdersContents()
                            else if (destination.label == 'Panier')
                              CartContents(
                                onBrowse: () => setState(() {
                                  selectedLabel = 'Catalogue';
                                }),
                              )
                            else if (destination.label == 'Profil')
                              const AccountContents()
                            else if (destination.label == 'Catalogue')
                              CatalogPage(
                                key: ValueKey(
                                  'catalog-${catalogCategory ?? "all"}',
                                ),
                                initialCategory: catalogCategory,
                              )
                            else if (selected == 0)
                              ...overview(destinations)
                            else if (activeProfile ==
                                    DemoProfile.administrator &&
                                selected == 1)
                              FlowStateView(
                                title: 'Prototype de gestion locale',
                                description: 'Retrouvez les produits, stocks, contacts et commandes déjà développés. Les opérations y sont enregistrées sur cet appareil.',
                                icon: Icons.business_center_outlined,
                                actionLabel: 'Ouvrir la gestion locale',
                                onAction: () => Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: widget.managementBuilder,
                                  ),
                                ),
                              )
                            else
                              FlowStateView(
                                title:
                                    '${destination.label} : interface à venir',
                                description:
                                    '${destination.description} Cette étape prépare la navigation ; le contenu détaillé sera construit dans les prochaines phases.',
                                icon: destination.icon,
                                actionLabel: 'Retour à l’accueil',
                                onAction: () => setState(
                                  () =>
                                      selectedLabel = destinations.first.label,
                                ),
                              ),
                            const SizedBox(height: 24),
                            const Text(
                              'Phase 4 · Espace client de démonstration',
                              style: TextStyle(
                                color: FlowColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) =>
                  setState(() => selectedLabel = destinations[i].label),
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: item.label == 'Panier'
                        ? Badge(
                            isLabelVisible: shopping.itemCount > 0,
                            label: Text('${shopping.itemCount}'),
                            child: Icon(item.icon),
                          )
                        : Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
    );
  }

  List<Widget> overview(List<DemoDestination> destinations) => [
    Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF113C45), FlowColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(profile.icon, color: const Color(0xFFA1E7D4), size: 36),
          const SizedBox(height: 20),
          Text(
            profile == DemoProfile.visitor
                ? 'Découvrez librement.\nCommandez à votre rythme.'
                : profile.space,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 25,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile == DemoProfile.visitor
                ? 'Le catalogue sera accessible sans compte. La connexion interviendra au moment de confirmer une action commerciale.'
                : '${profile.description}. Cet aperçu sert à valider les écrans et la navigation avant de connecter les services.',
            style: const TextStyle(color: Color(0xFFE0F4EE), height: 1.5),
          ),
        ],
      ),
    ),
    const SizedBox(height: 24),
    Text('Votre espace', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 12),
    LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 1; i < destinations.length; i++)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 16) / columns,
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        setState(() => selectedLabel = destinations[i].label),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(destinations[i].icon, color: FlowColors.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  destinations[i].label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  destinations[i].description,
                                  style: const TextStyle(
                                    color: FlowColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
    const SizedBox(height: 24),
    FlowButton(
      label: 'Explorer les composants',
      icon: Icons.palette_outlined,
      secondary: true,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const FoundationGallery()),
      ),
    ),
  ];
}
