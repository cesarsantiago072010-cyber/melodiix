import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/glass_theme.dart';
import 'core/navigation/root_navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox<Map>('downloads');
  await Hive.openBox<Map>('library');

  runApp(const ProviderScope(child: MelodixApp()));
}

class MelodixApp extends StatelessWidget {
  const MelodixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Melodix',
      debugShowCheckedModeBanner: false,
      theme: GlassTheme.dark(),
      home: const RootNavigator(),
    );
  }
}
