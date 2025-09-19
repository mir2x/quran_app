// features/sura/view/widgets/sura_app_bar.dart
import 'package:flutter/material.dart';
import 'package:quran_app/features/sura/view/widgets/search_page.dart';

class SuraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const SuraAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      actions: [
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