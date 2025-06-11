import '../../domain/entities/quran_edition.dart';

final List<String> imageFilesCT = [
  "page-001.jpg",
  "page-002.jpg",
  "page-003.jpg",
  "page-004.jpg",
  "page-005.jpg",
  "page-006.jpg",
  "page-007.jpg",
  "page-008.jpg",
  "page-009.jpg",
  "page-010.jpg",
  "page-011.jpg",
];

final List<String> jsonFilesCT = [
  "page-001.json",
  "page-002.json",
  "page-003.json",
  "page-004.json",
  "page-005.json",
];

final List<String> imageFiles = ["page-001.jpg"];

final List<String> jsonFiles = ["page-001.json"];

final List<QuranEdition> quranEditionData = [
  QuranEdition(
    coverImagePath: 'assets/image/front_page/hafezi.jpg',
    title: 'হাফিজি কুরআন',
    assetPath: 'hafezi',
    imageWidth: 2090,
    imageHeight: 3280,
    imageFiles: imageFiles,
    jsonFiles: jsonFiles,),

  QuranEdition(
    coverImagePath: 'assets/image/front_page/colorful_tajweed.jpg',
    title: 'রঙিন\nতাজবীদ কুরআন',
    assetPath: 'colorful_tajweed',
    imageWidth: 1537,
    imageHeight: 2236,
    imageFiles: imageFilesCT,
    jsonFiles: jsonFilesCT,
  ),
  QuranEdition(
    coverImagePath: 'assets/image/front_page/hafezi-saudi.jpg',
    title: 'হাফিজি কুরআন\n(সৌদি প্রিন্ট)',
    assetPath: 'saudi_hafezi',
    imageWidth: 1455,
    imageHeight: 2125,
    imageFiles: imageFiles,
    jsonFiles: jsonFiles,),
  QuranEdition(
    coverImagePath: 'assets/image/front_page/imdadia_hafezi.jpg',
    title: 'হাফিজি কুরআন\n(এমদাদিয়া লাইব্রেরী)',
    assetPath: 'imdadia_hafezi',
    imageWidth: 648,
    imageHeight: 1011,
    imageFiles: imageFiles,
    jsonFiles: jsonFiles,
  ),
  QuranEdition(
    coverImagePath: 'assets/image/front_page/madani.jpg',
    title: 'মাদানী কুরআন\n(উসমানী প্রিন্ট)',
    assetPath: 'madani',
    imageWidth: 1361,
    imageHeight: 2430,
    imageFiles: imageFiles,
    jsonFiles: jsonFiles,
  ),
  QuranEdition(
    coverImagePath: 'assets/image/front_page/nurani.jpg',
    title: 'নূরানী কুরআন\n(এমদাদিয়া লাইব্রেরী)',
    assetPath: 'nurani',
    imageWidth: 1674,
    imageHeight: 2584,
    imageFiles: imageFiles,
    jsonFiles: jsonFiles,
  ),
  QuranEdition(
    coverImagePath: 'assets/image/front_page/colorful_hafezi.jpg',
    title: 'রঙিন হাফিজি',
    assetPath: 'colorful_hafezi',
    imageWidth: 1829,
    imageHeight: 2817,
    imageFiles: imageFiles,
    jsonFiles: jsonFiles,
  ),
];
