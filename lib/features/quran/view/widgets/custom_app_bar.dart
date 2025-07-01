import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../sura/view/sura_page.dart';
import '../../viewmodel/ayah_highlight_viewmodel.dart';



class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Text(
        'কুরআন মজীদ',
        style: TextStyle(fontFamily: 'SolaimanLipi', fontSize: 22.sp),
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(icon: const Icon(Icons.nightlight_outlined), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.g_translate),
          onPressed: () {
            final int suraNumber = ref.watch(currentSuraProvider);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SurahPage(suraNumber: suraNumber),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}