import 'dart:io';
import 'package:flutter/material.dart';
import 'download_manager.dart';

class DownloadProvider extends ChangeNotifier {
  final DownloadManager _manager = DownloadManager();
  Map<String, dynamic>? _videoInfo;
  String? _currentTask;
  double _progress = 0.0;
  String _status = 'Idle';
  Map<String, dynamic>? _selectedFormat;
  bool _downloadAsRaw = true;
  String? _downloadsDir;

  Map<String, dynamic>? get videoInfo => _videoInfo;
  String? get currentTask => _currentTask;
  double get progress => _progress;
  String get status => _status;
  Map<String, dynamic>? get selectedFormat => _selectedFormat;
  bool get downloadAsRaw => _downloadAsRaw;
  String? get downloadsDir => _downloadsDir;

  Future<void> initializeDownloadsDir() async {
    _downloadsDir = '/storage/emulated/0/Download';
    final dir = Directory(_downloadsDir!);
    if (!await dir.exists()) await dir.create(recursive: true);
    debugPrint('Downloads dir: $_downloadsDir');
  }

  Future<void> fetchVideoInfo(String url) async {
    _status = 'Fetching';
    notifyListeners();
    try {
      _videoInfo = await _manager.fetchVideoInfo(url);
      _setDefaultFormat();
      _status = 'Ready';
    } catch (e) {
      _status = 'Failed: $e';
    }
    notifyListeners();
  }

  void listenToDownloadEvents() {
    _manager.getDownloadEvents().listen(
      (event) {
        if (_currentTask != null && event['taskId'] == _currentTask) {
          _handleEvent(event);
        }
      },
      onError: (e) => _reset('Failed: $e'),
    );
  }

  Future<void> startDownload(String url) async {
    if (_selectedFormat == null || _downloadsDir == null) {
      _status = 'Invalid selection';
      notifyListeners();
      return;
    }
    _status = 'Preparing';
    notifyListeners();
    try {
      final format = Map<String, dynamic>.from(_selectedFormat!);
      format['downloadAsRaw'] = _downloadAsRaw;
      _currentTask =
          await _manager.startDownload(format, _downloadsDir!, url, false);
      _status = 'Downloading';
    } catch (e) {
      _status = 'Failed: $e';
    }
    notifyListeners();
  }

  Future<void> cancelDownload() async {
    if (_currentTask != null) {
      await _manager.cancelDownload(_currentTask!);
      _reset('Canceled');
    }
  }

  void selectFormat(Map<String, dynamic>? format) {
    _selectedFormat = format;
    _downloadAsRaw =
        format?['needsConversion'] as bool? ?? false ? false : true;
    notifyListeners();
  }

  void toggleDownloadAsRaw(bool? value) {
    if (value != null) {
      _downloadAsRaw = value;
      notifyListeners();
    }
  }

  void _setDefaultFormat() {
    final combined = _videoInfo?['rawVideoWithSoundFormats'] as List<dynamic>?;
    if (combined != null && combined.isNotEmpty) {
      _selectedFormat = combined.first as Map<String, dynamic>;
      _downloadAsRaw =
          _selectedFormat!['needsConversion'] as bool? ?? false ? false : true;
    }
  }

  void _handleEvent(Map<String, dynamic> event) {
    if (event['type'] == 'progress') {
      final downloaded = (event['downloaded'] as num).toDouble();
      final total = (event['total'] as num).toDouble();
      _progress = total > 0 ? downloaded / total : 0.0;
      _status = 'Downloading';
    } else if (event['type'] == 'state') {
      _status = event['stateName'] as String;
      if (_status == 'Completed' ||
          _status == 'Canceled' ||
          _status == 'Failed') {
        _reset(_status);
      }
    }
    notifyListeners();
  }

  void _reset(String finalStatus) {
    _status = finalStatus;
    _currentTask = null;
    _progress = 0.0;
    notifyListeners();
  }
}
