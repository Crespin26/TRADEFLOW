class CatalogPhoto {
  const CatalogPhoto({
    required this.asset,
    required this.description,
    required this.author,
    required this.source,
    required this.sourceUrl,
    required this.licenseUrl,
  });
  final String asset, description, author, source, sourceUrl, licenseUrl;
}

const catalogPhotos = <String, CatalogPhoto>{
  "rice": CatalogPhoto(
    asset: "assets/images/catalog/rice.jpg",
    description: "Grains de riz blanc",
    author: "Daniela Paola Alchapar",
    source: "Unsplash",
    sourceUrl: "https://unsplash.com/photos/a-pile-of-white-cotton-QTURkOqRFUQ",
    licenseUrl: "https://unsplash.com/license",
  ),
  "oil": CatalogPhoto(
    asset: "assets/images/catalog/oil.jpg",
    description: "Huile végétale dans une bouteille en verre",
    author: "Vladimir Gladkov",
    source: "Pexels",
    sourceUrl:
        "https://www.pexels.com/photo/olive-oil-in-a-glass-bottle-6213754/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
  "cocoa": CatalogPhoto(
    asset: "assets/images/catalog/cocoa.jpg",
    description: "Fèves de cacao séchées",
    author: "Loannes Marc",
    source: "Pexels",
    sourceUrl:
        "https://www.pexels.com/photo/close-up-shot-of-cocoa-beans-4157754/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
  "fabric": CatalogPhoto(
    asset: "assets/images/catalog/fabric.jpg",
    description: "Texture de tissu bleu",
    author: "Mo Squito",
    source: "Pexels",
    sourceUrl: "https://www.pexels.com/photo/close-up-of-a-blue-textured-fabric-13876082/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
  "workwear": CatalogPhoto(
    asset: "assets/images/catalog/workwear.jpg",
    description: "Veste suspendue sur un cintre",
    author: "Ali Babajahdi",
    source: "Pexels",
    sourceUrl: "https://www.pexels.com/photo/jacket-on-hanger-16341730/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
  "solar": CatalogPhoto(
    asset: "assets/images/catalog/solar.jpg",
    description: "Panneaux solaires photovoltaïques",
    author: "Mark Stebnicki",
    source: "Pexels",
    sourceUrl:
        "https://www.pexels.com/photo/close-up-of-solar-panels-15751136/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
  "chair": CatalogPhoto(
    asset: "assets/images/catalog/chair.jpg",
    description: "Chaise de bureau dans un espace de travail",
    author: "Mike Murray",
    source: "Pexels",
    sourceUrl: "https://www.pexels.com/photo/photo-of-a-black-office-chair-in-an-office-6446321/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
  "cartons": CatalogPhoto(
    asset: "assets/images/catalog/cartons.jpg",
    description: "Boîtes en carton sur une surface jaune",
    author: "Ron Lach",
    source: "Pexels",
    sourceUrl: "https://www.pexels.com/photo/brown-cardboard-boxes-on-yellow-surface-9594420/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
  "warehouse": CatalogPhoto(
    asset: "assets/images/catalog/warehouse.jpg",
    description: "Entrepôt de marchandises et cartons",
    author: "Freek Wolsink",
    source: "Pexels",
    sourceUrl: "https://www.pexels.com/photo/industrial-warehouse-with-stacked-cardboard-boxes-34221998/",
    licenseUrl: "https://www.pexels.com/license/",
  ),
};
