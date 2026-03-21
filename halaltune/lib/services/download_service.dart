import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';

enum DownloadStatus { notDownloaded, downloading, downloaded, error }

class DownloadService extends ChangeNotifier {
  static final DownloadService _i = DownloadService._();
  factory DownloadService() => _i;
  DownloadService._();

  final Dio _dio = Dio();
  final Map<String, DownloadStatus> _status = {};
  final Map<String, double> _progress = {};
  final Map<String, String> _localPaths = {};
  final Map<String, CancelToken> _tokens = {};

  DownloadStatus statusOf(String id) => _status[id] ?? DownloadStatus.notDownloaded;
  double progressOf(String id) => _progress[id] ?? 0;
  String? localPath(String id) => _localPaths[id];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('dl_')).toList();
    for (final k in keys) {
      final id = k.substring(3);
      final path = prefs.getString(k)!;
      if (await File(path).exists()) {
        _localPaths[id] = path;
        _status[id] = DownloadStatus.downloaded;
      }
    }
    notifyListeners();
  }

  Future<void> download(Track track, {void Function(double)? onProgress}) async {
    if (_status[track.id] == DownloadStatus.downloading) return;
    if (_status[track.id] == DownloadStatus.downloaded) return;

    // Use app-internal docs dir — no storage permission needed
    final dir = await getApplicationDocumentsDirectory();
    final ext = track.url.contains('.mp3') ? 'mp3' : 'm4a';
    final safe = track.title.replaceAll(RegExp(r'[^\w\s\-]'), '').trim();
    final file = File('${dir.path}/downloads/${safe}_${track.id}.$ext');
    await file.parent.create(recursive: true);

    final token = CancelToken();
    _tokens[track.id] = token;
    _status[track.id] = DownloadStatus.downloading;
    _progress[track.id] = 0;
    notifyListeners();

    try {
      await _dio.download(
        track.url,
        file.path,
        cancelToken: token,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          _progress[track.id] = received / total;
          onProgress?.call(_progress[track.id]!);
          notifyListeners();
        },
      );
      _localPaths[track.id] = file.path;
      _status[track.id] = DownloadStatus.downloaded;
      _progress[track.id] = 1.0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dl_${track.id}', file.path);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        _status[track.id] = DownloadStatus.notDownloaded;
      } else {
        debugPrint('Download error: $e');
        _status[track.id] = DownloadStatus.error;
      }
      if (await file.exists()) await file.delete();
    } finally {
      _tokens.remove(track.id);
      notifyListeners();
    }
  }

  void cancel(String id) {
    _tokens[id]?.cancel('Cancelled');
    _tokens.remove(id);
    _status[id] = DownloadStatus.notDownloaded;
    _progress[id] = 0;
    notifyListeners();
  }

  Future<void> deleteDownload(String id) async {
    final path = _localPaths[id];
    if (path != null) {
      final f = File(path);
      if (await f.exists()) await f.delete();
      _localPaths.remove(id);
    }
    _status.remove(id);
    _progress.remove(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dl_$id');
    notifyListeners();
  }

  bool isDownloaded(String id) => _status[id] == DownloadStatus.downloaded;
}
