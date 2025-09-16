import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/core/utils/bengali_digit_extension.dart';

import 'package:quran_app/features/sura/view/sura_page.dart';

import '../../../../shared/quran_data.dart';
import '../../../quran/viewmodel/ayah_highlight_viewmodel.dart';
import '../../viewmodel/search_viewmodel.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'আরবি বা বাংলায় খুঁজুন...',
            hintStyle: TextStyle(fontFamily: 'SolaimanLipi', color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontFamily: 'SolaimanLipi', color: Colors.white, fontSize: 18),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
      ),
      body: searchResults.when(
        data: (ayahs) {
          if (searchQuery.isEmpty) {
            return const Center(
              child: Text('আয়াত বা অনুবাদ খুঁজতে টাইপ করুন।', style: TextStyle(fontFamily: 'SolaimanLipi')),
            );
          }
          if (ayahs.isEmpty) {
            return const Center(
              child: Text('কোন ফলাফল পাওয়া যায়নি।', style: TextStyle(fontFamily: 'SolaimanLipi')),
            );
          }
          return ListView.builder(
            itemCount: ayahs.length,
            itemBuilder: (context, index) {
              final ayah = ayahs[index];
              return ListTile(
                title: Text(
                  'সূরা ${ suraNames[ayah.sura - 1] ?? ayah.sura}: আয়াত ${ayah.ayah.toBengaliDigit()}',
                  style: const TextStyle(fontFamily: 'SolaimanLipi', fontWeight: FontWeight.bold),
                ),
                subtitle: HighlightedText(
                  text: ayah.arabicText,
                  query: searchQuery,
                  style: const TextStyle(fontFamily: 'Al Mushaf Quran', fontSize: 20, color: Colors.black),
                ),
                onTap: () {
                  // Navigate to the SurahPage and tell it to scroll to the specific ayah
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahPage(
                        suraNumber: ayah.sura,
                        initialScrollIndex: ayah.ayah - 1, // list is 0-indexed
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// Helper widget for highlighting text
class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while(start < text.length) {
      final startIndex = lowerText.indexOf(lowerQuery, start);
      if (startIndex == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }

      if (startIndex > start) {
        spans.add(TextSpan(text: text.substring(start, startIndex)));
      }

      final endIndex = startIndex + query.length;
      spans.add(TextSpan(
        text: text.substring(startIndex, endIndex),
        style: style.copyWith(backgroundColor: Colors.black),
      ));

      start = endIndex;
    }

    return RichText(
      // Apply textAlign and textDirection directly to RichText
      textAlign: TextAlign.start, // Or whatever you need
      textDirection: TextDirection.rtl, // Set this if your text is Arabic
      text: TextSpan(
        // The style for the children is defined here
          style: style,
          children: spans
      ),
    );
  }
}