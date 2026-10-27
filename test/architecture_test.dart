import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard architectural dependencies without relying on a third-party linter.
void main() {
  final directives = RegExp(r'''(?:import|export|part)\s+['"]([^'"]+)['"]''');
  String? localTarget(File file, String uri) {
    if (uri.startsWith('package:tradeflow_mobile/')) {
      return uri.substring('package:tradeflow_mobile/'.length).split('/').first;
    }
    if (uri.contains(':')) return null;
    final target = file.absolute.uri
        .resolve(uri)
        .toFilePath()
        .replaceAll('\\', '/');
    final root = Directory('lib').absolute.path.replaceAll('\\', '/');
    return target.startsWith('$root/')
        ? target.substring(root.length + 1).split('/').first
        : null;
  }

  for (final layer in ['domain', 'application', 'data', 'ui']) {
    test('$layer keeps its allowed dependency direction', () {
      final violations = <String>[];
      for (final file
          in Directory('lib/$layer')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        for (final match in directives.allMatches(file.readAsStringSync())) {
          final uri = match.group(1)!;
          final target = localTarget(file, uri);
          final forbidden = switch (layer) {
            'domain' => ['application', 'data', 'ui'],
            'application' => ['data', 'ui'],
            'data' => ['application', 'ui'],
            _ => ['data'],
          };
          if (forbidden.contains(target) ||
              (layer == 'domain' &&
                  (uri.startsWith('package:flutter/') ||
                      uri == 'dart:io' ||
                      uri == 'dart:html')) ||
              (layer == 'application' &&
                  uri.startsWith('package:flutter/') &&
                  uri != 'package:flutter/foundation.dart')) {
            violations.add('${file.path} -> $uri');
          }
        }
      }
      expect(
        violations,
        isEmpty,
        reason:
            'Composition is owned by main.dart; repositories are domain ports.',
      );
    });
  }
  test('test fixtures are independent of test entry points', () {
    final violations = <String>[];
    for (final file
        in Directory('test')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))) {
      for (final match in directives.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        if (!uri.contains(':') && uri.endsWith('_test.dart')) {
          violations.add('${file.path} -> $uri');
        }
      }
    }
    expect(
      violations,
      isEmpty,
      reason: 'Reusable fixtures belong to test/support/.',
    );
  });
}
