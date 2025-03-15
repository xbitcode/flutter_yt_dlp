import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'download_manager.dart';
import 'ui/download_screen.dart';
import 'download_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<DownloadManager>(
          create: (_) => DownloadManager(),
        ),
        ChangeNotifierProvider<DownloadProvider>(
          create: (_) => DownloadProvider(),
        ),
      ],
      child: const MaterialApp(
        home: DownloadScreen(),
      ),
    );
  }
}
