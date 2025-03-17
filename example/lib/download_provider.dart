// File: example\lib\download_provider.dart
import 'package:flutter/material.dart';
import 'download_manager.dart';
import 'dart:io';

class DownloadProvider extends ChangeNotifier {
  final DownloadManager _downloadManager;
  Map<String, dynamic>? _videoInfo;
  String? _currentTask;
  double _progress = 0.0;
  String _status = 'Idle';
  Map<String, dynamic>? _selectedFormat;
  bool _downloadAsRaw = true;
  String? _downloadsDir;

  DownloadProvider() : _downloadManager = DownloadManager();

  Map<String, dynamic>? get videoInfo => _videoInfo;
  String? get currentTask => _currentTask;
  double get progress => _progress;
  String get status => _status;
  Map<String, dynamic>? get selectedFormat => _selectedFormat;
  bool get downloadAsRaw => _downloadAsRaw;
  String? get downloadsDir => _downloadsDir;

  Future<void> initializeDownloadsDir() async {
    try {
      _downloadsDir = '/storage/emulated/0/Download';
      final dir = Directory(_downloadsDir!);
      if (!await dir.exists()) await dir.create(recursive: true);
      debugPrint('Downloads directory initialized: $_downloadsDir');
    } catch (e) {
      debugPrint('Error initializing downloads dir: $e');
      _status = 'Failed to locate Download folder';
      notifyListeners();
    }
  }

  Future<void> fetchVideoInfo(String url) async {
    _status = 'Fetching';
    notifyListeners();
    try {
      _videoInfo =
          await _downloadManager.fetchVideoInfo(url); // Fixed method name
      _setDefaultFormat();
      _status = 'Ready';
    } catch (e) {
      debugPrint('Failed to fetch video info: $e');
      _status = 'Failed';
    } finally {
      notifyListeners();
    }
  }

  void listenToDownloadEvents() {
    _downloadManager.getDownloadEvents().listen(
      (event) {
        if (_currentTask == null || event['taskId'] != _currentTask) return;
        _handleDownloadEvent(event);
      },
      onError: (e) {
        debugPrint('Error in download events: $e');
        _resetDownloadState('Failed');
      },
    );
  }

  Future<void> startDownload(String url) async {
    if (_selectedFormat == null || _downloadsDir == null) {
      _status = 'Invalid selection or directory';
      notifyListeners();
      return;
    }
    _status = 'Preparing';
    notifyListeners();
    try {
      Map<String, dynamic> format = Map<String, dynamic>.from(_selectedFormat!);
      if (format['type'] == 'merge') {
        format = {
          'type': 'merge',
          'video': format['video'],
          'audio': format['audio'],
          'formatId': format['formatId'],
          'ext': 'mp4',
          'resolution': format['resolution'],
          'size': format['size'],
        };
      }
      format['downloadAsRaw'] = _downloadAsRaw;
      _currentTask = await _downloadManager.startDownload(
        format,
        _downloadsDir!,
        url,
        true,
      );
      _status = 'Downloading';
    } catch (e) {
      debugPrint('Failed to start download: $e');
      _status = 'Failed';
    } finally {
      notifyListeners();
    }
  }

  Future<void> cancelDownload() async {
    if (_currentTask != null) {
      await _downloadManager.cancelDownload(_currentTask!);
      _resetDownloadState('Canceled');
    }
  }

  void updateSelectedFormat(Map<String, dynamic>? format) {
    _selectedFormat = format;
    _downloadAsRaw = format != null &&
            format['needsConversion'] != null &&
            format['needsConversion'] as bool
        ? false
        : true;
    notifyListeners();
  }

  void toggleDownloadAsRaw(bool? value) {
    if (value != null) {
      _downloadAsRaw = value;
      notifyListeners();
    }
  }

  void _setDefaultFormat() {
    final combinedFormats =
        _videoInfo?['rawVideoWithSoundFormats'] as List<dynamic>?;
    if (combinedFormats != null && combinedFormats.isNotEmpty) {
      _selectedFormat = combinedFormats[0] as Map<String, dynamic>;
      _downloadAsRaw =
          _selectedFormat!['needsConversion'] as bool? ?? false ? false : true;
    }
  }

  void _handleDownloadEvent(Map<String, dynamic> event) {
    debugPrint('Handling event: $event');
    if (event['type'] == 'progress') {
      final downloaded = (event['downloaded'] as num?)?.toDouble() ?? 0.0;
      final total = (event['total'] as num?)?.toDouble() ?? 0.0;
      _progress = total > 0 ? downloaded / total : 0.0;
      _status = 'Downloading';
    } else if (event['type'] == 'state') {
      _status = event['stateName'] as String? ??
          _getStatusFromState(event['state'] as int? ?? 0);
      if (_status == 'Completed' ||
          _status == 'Canceled' ||
          _status == 'Failed') {
        _resetDownloadState(_status);
      }
    }
    notifyListeners();
  }

  void _resetDownloadState(String finalStatus) {
    _status = finalStatus;
    _currentTask = null;
    _progress = 0.0;
    notifyListeners();
  }

  String _getStatusFromState(int state) {
    const states = [
      'Preparing',
      'Downloading',
      'Merging',
      'Converting',
      'Completed',
      'Canceled',
      'Failed'
    ];
    return states[state.clamp(0, states.length - 1)];
  }
}
