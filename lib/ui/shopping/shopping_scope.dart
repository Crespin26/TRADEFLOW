import 'package:flutter/material.dart';

import '../../domain/shopping_session.dart';

class ShoppingScope extends InheritedNotifier<ShoppingSession> {
  const ShoppingScope({
    super.key,
    required ShoppingSession session,
    required super.child,
  }) : super(notifier: session);
  static ShoppingSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShoppingScope>()!.notifier!;
}

class ShoppingHost extends StatefulWidget {
  const ShoppingHost({super.key, this.session, required this.child});
  final ShoppingSession? session;
  final Widget child;
  @override
  State<ShoppingHost> createState() => _ShoppingHostState();
}

class _ShoppingHostState extends State<ShoppingHost> {
  late final ShoppingSession session = widget.session ?? ShoppingSession();
  @override
  void dispose() {
    if (widget.session == null) session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ShoppingScope(session: session, child: widget.child);
}
