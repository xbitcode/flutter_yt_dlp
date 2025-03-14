import 'package:flutter/material.dart';
import 'download_manager.dart';
import 'ui/download_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final _downloadManager = DownloadManager();

  @override
  void initState() {
    super.initState();
    _downloadManager
        .fetchThumbnail("https://youtu.be/l2Uoid2eqII?si=W9xgTB9bfRK5ss6V");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DownloadScreen(downloadManager: _downloadManager),
    );
  }
}
