import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow_mobile/domain/catalog_photos.dart';
import 'package:tradeflow_mobile/domain/public_catalog.dart';
import 'package:tradeflow_mobile/ui/catalog/catalog_photo.dart';

void main() {
  testWidgets(
    'all photographs are bundled, credited and decode without network',
    (tester) async {
      await tester.runAsync(() async {
        final credits = jsonDecode(
          await rootBundle.loadString('assets/images/catalog/credits.json'),
        ) as Map<String, dynamic>;
        final records = credits['photos'] as List;
        var total = 0;
        for (final entry in catalogPhotos.entries) {
          final photo = entry.value;
          final data = await rootBundle.load(photo.asset);
          total += data.lengthInBytes;
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            targetWidth: 64,
          );
          final frame = await codec.getNextFrame();
          expect(frame.image.width, greaterThan(0));
          frame.image.dispose();
          codec.dispose();
          final record = records.singleWhere(
            (r) => r['id'] == entry.key,
          ) as Map<String, dynamic>;
          expect(record['bytes'], data.lengthInBytes);
          expect(record['page'], photo.sourceUrl);
          expect(record['author'], photo.author);
        }
        expect(total, lessThan(2 * 1024 * 1024));
        expect(demoPublicProducts.every((p) => p.photo != null), isTrue);
      });
    },
  );
  testWidgets('unknown product imagery has an accessible fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CatalogPhotoView(photo: null))),
    );
    expect(find.text('Photo indisponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
