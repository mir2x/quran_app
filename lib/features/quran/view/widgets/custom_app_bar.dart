import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget{
  const CustomAppBar({super.key});

  @override
  build(BuildContext context) {
    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text(
        'কুরআন মজীদ',
        style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 22),
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.nightlight_outlined), onPressed: () {}),
        IconButton(icon: const Icon(Icons.g_translate), onPressed: () {}),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}