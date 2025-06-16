import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme.dart';
import '../../../viewmodel/ayah_highlight_viewmodel.dart';

class BookmarkNavigationView extends ConsumerWidget {
  const BookmarkNavigationView({super.key});

  @override
  // ConsumerWidget's build method automatically provides WidgetRef ref
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the bookmarks provider
    final bookmarksAsync = ref.watch(bookmarkProvider);

    // DefaultTabController is for the nested tabs (Ayah/Page)
    return DefaultTabController(
      length: 2,
      // The child of DefaultTabController is the widget that contains the TabBar and TabBarView
      child: bookmarksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading bookmarks')),
        data: (bookmarks) {
          final ayahBookmarks = bookmarks
              .where((b) => b.type == 'ayah')
              .toList();
          final pageBookmarks = bookmarks
              .where((b) => b.type == 'page')
              .toList();

          // Return the Column containing the TabBar and TabBarView
          return Column(
            children: [
              Container(
                color: primaryColor.withOpacity(.1),
                child: const TabBar(
                  labelColor: primaryColor,
                  unselectedLabelColor: Colors.grey,
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
                        return ListTile(
                          title: Text(b.identifier), // Consider formatting like "Sura X: Ayah Y"
                          subtitle: Text(
                            'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                          ),
                          onTap: () {
                            try {
                              final parts = b.identifier.split('-');
                              if (parts.length == 3 && parts[0] == 'ayah') {
                                final sura = int.parse(parts[1]);
                                final ayah = int.parse(parts[2]);
                                // Need ayahPageMappingProvider to get the page
                                final ayahPageMapping = ref.read(ayahPageMappingProvider);
                                final targetPage = ayahPageMapping[(sura, ayah)];
                                if (targetPage != null) {
                                  ref.read(navigateToPageCommandProvider.notifier).state = targetPage;
                                  // Highlight the ayah after navigation
                                  ref.read(selectedAyahProvider.notifier).selectByNavigation(sura, ayah); // Use navigation source
                                  Navigator.of(context).pop(); // Close drawer
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Page not found for this Ayah bookmark')),
                                  );
                                }
                              } else if (parts.length == 2 && parts[0] == 'page') {
                                // This should be handled by the page bookmark list, but adding a fallback
                                final page = int.parse(parts[1]);
                                ref.read(navigateToPageCommandProvider.notifier).state = page;
                                ref.read(selectedAyahProvider.notifier).clear(); // Clear ayah highlight when navigating by page
                                Navigator.of(context).pop(); // Close drawer
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid bookmark format')),
                                );
                              }
                            } catch (e) {
                              debugPrint('Error navigating from bookmark: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not navigate to bookmark')),
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
                        final b = pageBookmarks[i]; // b.identifier should be 'page-X'
                        return ListTile(
                          title: Text('Page ${b.identifier.split('-')[1]}'),
                          subtitle: Text(
                            'Added: ${b.timestamp.toLocal().toString().split('.').first}',
                          ),
                          onTap: () {
                            try {
                              final parts = b.identifier.split('-');
                              if (parts.length == 2 && parts[0] == 'page') {
                                final page = int.parse(parts[1]);
                                ref.read(navigateToPageCommandProvider.notifier).state = page;
                                ref.read(selectedAyahProvider.notifier).clear(); // Clear ayah highlight when navigating by page
                                Navigator.of(context).pop(); // Close drawer
                              } else {
                                // This should be handled by the ayah bookmark list, but adding a fallback
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invalid bookmark format')),
                                );
                              }
                            } catch (e) {
                              debugPrint('Error navigating from page bookmark: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not navigate to bookmark')),
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
                )
              ),
            ],
          );
        },
      ), // bookmarksAsync.when ends here, this is the child
    ); // DefaultTabController ends here
  }
}