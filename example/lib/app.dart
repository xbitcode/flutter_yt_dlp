import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'download_manager.dart';
import 'download_provider.dart';
import 'ui/download_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => DownloadManager()),
        ChangeNotifierProvider(create: (_) => DownloadProvider()),
      ],
      child: const MaterialApp(home: DownloadScreen()),
    );
  }
}
