import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';



class BookmarkNavigationView extends ConsumerWidget {
  const BookmarkNavigationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bookmarkProvider);
    final suraNames = ref.watch(suraNamesProvider);

    return DefaultTabController(
      length: 2,
      child: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // Include error details in the message for debugging
        error: (e, s) => Center(child: Text('Error loading bookmarks: ${e.toString()}\n$s')),
        data: (bookmarks) {
          final ayahBookmarks = bookmarks
              .where((b) => b.type == 'ayah')
              .toList();
          final pageBookmarks = bookmarks
              .where((b) => b.type == 'page')
              .toList();

          return Column(
            children: [
              Container(
                color: Colors.lightGreen,
                child: const TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.white,
                  tabs: [
                    Tab(text: 'আয়াত'),
                    Tab(text: 'পৃষ্ঠা'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Ayah Bookmarks List
                    ListView.builder(
                      itemCount: ayahBookmarks.length,
                      itemBuilder: (_, i) {
                        final b = ayahBookmarks[i];
                        // Safely access nullable fields for display
                        final suraName = (b.sura != null && b.sura! > 0 && b.sura! <= suraNames.length)
                            ? suraNames[b.sura! - 1]
                            : 'Unknown Sura';
                        // Use null-aware operators or provide default text
                        final titleText = b.sura != null && b.ayah != null && b.para != null && b.page != null
                            ? 'সূরা ${b.sura} ($suraName): আয়াত ${b.ayah} (পারা ${b.para}, পৃষ্ঠা ${b.page})'
                            : 'Bookmark ID: ${b.identifier} (Data incomplete)'; // Fallback for incomplete data

                        return ListTile(
                          title: Text(titleText),
                          subtitle: Text(
                            'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                          ),
                          onTap: () {
                            // Navigation logic for Ayah bookmark
                            // Check if essential fields are available before navigating
                            if (b.sura != null && b.ayah != null && b.page != null) {
                              try {
                                final sura = b.sura!;
                                final ayah = b.ayah!;
                                final targetPage = b.page!; // Use stored page directly

                                ref.read(navigateToPageCommandProvider.notifier).state = targetPage;
                                // Highlight the ayah after navigation
                                ref.read(selectedAyahProvider.notifier).selectByNavigation(sura, ayah); // Use navigation source
                                Navigator.of(context).pop(); // Close drawer

                              } catch (e) {
                                debugPrint('Error during ayah bookmark navigation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not navigate to bookmark')),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bookmark data incomplete. Cannot navigate.')),
                              );
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => ref
                                .read(bookmarkProvider.notifier)
                                .remove(b.identifier),
                          ),
                        );
                      },
                    ),
                    // Page Bookmarks List
                    ListView.builder(
                      itemCount: pageBookmarks.length,
                      itemBuilder: (_, i) {
                        final b = pageBookmarks[i];
                        // Safely access nullable fields for display
                        final suraName = (b.sura != null && b.sura! > 0 && b.sura! <= suraNames.length)
                            ? suraNames[b.sura! - 1]
                            : 'Unknown Sura';
                        // Use null-aware operators or provide default text
                        final titleText = b.page != null && b.sura != null && b.para != null
                            ? 'পৃষ্ঠা ${b.page} (সূরা ${b.sura}, পারা ${b.para})' // Format page bookmark title
                            : 'Bookmark ID: ${b.identifier} (Data incomplete)'; // Fallback for incomplete data


                        return ListTile(
                          title: Text(titleText),
                          subtitle: Text(
                            'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                          ),
                          onTap: () {
                            // Navigation logic for Page bookmark
                            // Check if essential fields are available before navigating
                            if (b.page != null) {
                              try {
                                final page = b.page!;
                                ref.read(navigateToPageCommandProvider.notifier).state = page;
                                ref.read(selectedAyahProvider.notifier).clear(); // Clear ayah highlight when navigating by page
                                Navigator.of(context).pop(); // Close drawer
                              } catch (e) {
                                debugPrint('Error during page bookmark navigation: $e');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not navigate to bookmark')),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bookmark data incomplete. Cannot navigate.')),
                              );
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => ref
                                .read(bookmarkProvider.notifier)
                                .remove(b.identifier),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}