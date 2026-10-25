import 'package:flutter/material.dart';

import '../design_system/components.dart';
import '../design_system/theme.dart';
import 'shopping_scope.dart';

enum _AuthMode { login, register, reset }

class DemoAuthPage extends StatefulWidget {
  const DemoAuthPage({super.key});
  @override
  State<DemoAuthPage> createState() => _DemoAuthPageState();
}

class _DemoAuthPageState extends State<DemoAuthPage> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      password = TextEditingController(),
      confirm = TextEditingController();
  _AuthMode mode = _AuthMode.login;
  bool resetShown = false;
  @override
  void dispose() {
    for (final c in [name, email, password, confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    if (mode == _AuthMode.reset) {
      setState(() => resetShown = true);
      return;
    }
    ShoppingScope.of(context).signInDemo(
      email.text,
      name: name.text,
      registration: mode == _AuthMode.register,
    );
    password.clear();
    confirm.clear();
    if (mode == _AuthMode.login) {
      Navigator.pop(context, true);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ShoppingScope.of(context);
    final verification = session.signedIn && !session.verified;
    return Scaffold(
      appBar: AppBar(title: const Text('Accès client · Démonstration')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const FlowBadge('Simulation uniquement'),
                const SizedBox(height: 16),
                const Text(
                  'Utilisez des informations fictives. Aucun compte réel n’est créé, aucun e-mail n’est envoyé et aucun mot de passe n’est conservé.',
                ),
                const SizedBox(height: 24),
                if (verification) ...[
                  Text(
                    'Vérifiez votre adresse e-mail',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text(session.email!),
                  const SizedBox(height: 16),
                  const Text(
                    'Dans le service final, un lien de vérification sera envoyé. Ici, vous pouvez simuler sa validation.',
                  ),
                  const SizedBox(height: 24),
                  FlowButton(
                    label: 'Simuler la vérification',
                    onPressed: () {
                      session.verifyDemo();
                      Navigator.pop(context, true);
                    },
                  ),
                  TextButton(
                    onPressed: () {
                      session.signOut();
                      setState(() => mode = _AuthMode.login);
                    },
                    child: const Text('Utiliser une autre adresse'),
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in [
                        (_AuthMode.login, 'Connexion'),
                        (_AuthMode.register, 'Inscription'),
                        (_AuthMode.reset, 'Mot de passe oublié'),
                      ])
                        ChoiceChip(
                          label: Text(entry.$2),
                          selected: mode == entry.$1,
                          onSelected: (_) => setState(() {
                            mode = entry.$1;
                            resetShown = false;
                            password.clear();
                            confirm.clear();
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (resetShown)
                    FlowStateView(
                      title: 'Demande simulée',
                      description:
                          'Le parcours de récupération pour ${email.text.trim()} a été testé. Aucun message n’a été envoyé.',
                      icon: Icons.mark_email_read_outlined,
                      actionLabel: 'Retour à la connexion',
                      onAction: () => setState(() {
                        mode = _AuthMode.login;
                        resetShown = false;
                      }),
                    )
                  else
                    Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (mode == _AuthMode.register) ...[
                            FlowField(
                              controller: name,
                              label: 'Nom complet',
                              maxLength: 100,
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'Renseignez votre nom.'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          FlowField(
                            controller: email,
                            label: 'Adresse e-mail',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                    .hasMatch(value?.trim() ?? '')
                                ? null
                                : 'Saisissez une adresse e-mail valide.',
                          ),
                          if (mode != _AuthMode.reset) ...[
                            const SizedBox(height: 16),
                            FlowField(
                              controller: password,
                              label: 'Mot de passe fictif',
                              obscureText: true,
                              validator: (value) => (value?.length ?? 0) < 8
                                  ? 'Utilisez au moins 8 caractères pour cet exemple.'
                                  : null,
                            ),
                          ],
                          if (mode == _AuthMode.register) ...[
                            const SizedBox(height: 16),
                            FlowField(
                              controller: confirm,
                              label: 'Confirmer le mot de passe',
                              obscureText: true,
                              validator: (value) => value != password.text
                                  ? 'Les mots de passe ne correspondent pas.'
                                  : null,
                            ),
                          ],
                          const SizedBox(height: 24),
                          FlowButton(
                            label: switch (mode) {
                              _AuthMode.login => 'Simuler la connexion',
                              _AuthMode.register => 'Simuler l’inscription',
                              _AuthMode.reset => 'Simuler la récupération',
                            },
                            onPressed: submit,
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 32),
                const Text(
                  'Votre panier reste conservé pendant ce parcours.',
                  style: TextStyle(color: FlowColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
