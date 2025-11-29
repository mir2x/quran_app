// features/sura/view/widgets/sura_app_bar.dart
import 'package:flutter/material.dart';
import 'package:quran_app/features/sura/view/widgets/search_page.dart';

class SuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const SuraAppBar({super.key, required this.title, this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_book, color: Colors.white),
          onPressed: () {
            scaffoldKey?.currentState?.openDrawer();
          },
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchPage()),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
