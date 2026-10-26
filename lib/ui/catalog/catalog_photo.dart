import 'package:flutter/material.dart';

import '../../domain/catalog_photos.dart';
import '../design_system/components.dart';
import '../design_system/theme.dart';

class CatalogPhotoView extends StatelessWidget {
  const CatalogPhotoView({
    super.key,
    required this.photo,
    this.height = 190,
    this.fit = BoxFit.cover,
    this.showCaption = true,
  });
  final CatalogPhoto? photo;
  final double height;
  final BoxFit fit;
  final bool showCaption;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: photo == null
        ? const _MissingPhoto()
        : Stack(
            fit: StackFit.expand,
            children: [
              photoImage(photo!, fit: fit),
              if (showCaption)
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      photo!.isLocal
                          ? 'Photo du produit'
                          : 'Photo illustrative',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
  );
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();
  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: FlowColors.background,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, color: FlowColors.muted),
          SizedBox(height: 8),
          Text('Photo indisponible', style: TextStyle(color: FlowColors.muted)),
        ],
      ),
    ),
  );
}

class PhotoViewerPage extends StatelessWidget {
  const PhotoViewerPage({super.key, required this.photo});
  final CatalogPhoto photo;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Photographie')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Container(
              color: const Color(0xFF13262F),
              alignment: Alignment.center,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: photoImage(photo, fit: BoxFit.contain),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  photo.description,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('Photo : ${photo.author} · ${photo.source}'),
                const SizedBox(height: 6),
                if (!photo.isLocal)
                  const Text(
                    'Photographie illustrative, sans garantie sur le modèle, l’origine ou le conditionnement de la référence fictive.',
                    style: TextStyle(fontSize: 12, color: FlowColors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class PhotoCreditsPage extends StatelessWidget {
  const PhotoCreditsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Crédits photographiques')),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const FlowBadge('Photographies intégrées à l’application'),
              const SizedBox(height: 16),
              const Text(
                'Photos provenant de Pexels et Unsplash, utilisées pour illustrer le catalogue de démonstration. Elles ne représentent pas les stocks réels d’une entreprise.',
              ),
              const SizedBox(height: 24),
              for (final photo in catalogPhotos.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CatalogPhotoView(
                          photo: photo,
                          height: 160,
                          showCaption: false,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                photo.description,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text('${photo.author} · ${photo.source}'),
                              const SizedBox(height: 8),
                              SelectableText(photo.sourceUrl),
                              const SizedBox(height: 8),
                              SelectableText(photo.licenseUrl),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget photoImage(CatalogPhoto photo, {BoxFit fit = BoxFit.cover}) =>
    photo.bytes != null
    ? Image.memory(
        photo.bytes!,
        fit: fit,
        semanticLabel: photo.description,
        errorBuilder: (_, error, stack) => const _MissingPhoto(),
      )
    : Image.asset(
        photo.asset,
        fit: fit,
        semanticLabel: photo.description,
        errorBuilder: (_, error, stack) => const _MissingPhoto(),
      );
