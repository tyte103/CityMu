import 'dart:developer' as developer;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Service managing Android Foreground Task to prevent OS termination
/// while generating ambient music in the background.
class ForegroundService {
  ForegroundService._internal();
  static final ForegroundService instance = ForegroundService._internal();

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Initializes foreground task configuration.
  void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'citymu_audio_channel',
        channelName: 'CityMu Spatial Lo-Fi Service',
        channelDescription: 'Maintains low-latency spatial audio engine and sensor monitoring in background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Starts the foreground service.
  Future<bool> startService({String statusText = 'Harmonizing urban soundscape...'}) async {
    if (_isRunning) return true;

    try {
      final reqResult = await FlutterForegroundTask.requestNotificationPermission();
      if (reqResult == NotificationPermission.denied) {
        developer.log('Notification permission denied for foreground task.', name: 'ForegroundService');
      }

      final startResult = await FlutterForegroundTask.startService(
        notificationTitle: 'CityMu Ambient Engine',
        notificationText: statusText,
        callback: _taskCallback,
      );

      _isRunning = startResult is ServiceRequestSuccess;
      return _isRunning;
    } catch (e) {
      developer.log('Failed to start foreground task: $e', name: 'ForegroundService');
      return false;
    }
  }

  /// Updates notification text with live metrics.
  Future<void> updateNotification({required String text}) async {
    if (!_isRunning) return;
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: 'CityMu Ambient Engine',
        notificationText: text,
      );
    } catch (e) {
      developer.log('Error updating notification: $e', name: 'ForegroundService');
    }
  }

  /// Stops foreground service.
  Future<void> stopService() async {
    if (!_isRunning) return;
    try {
      await FlutterForegroundTask.stopService();
      _isRunning = false;
    } catch (e) {
      developer.log('Error stopping foreground task: $e', name: 'ForegroundService');
    }
  }
}

@pragma('vm:entry-point')
void _taskCallback() {
  FlutterForegroundTask.setTaskHandler(_CityMuTaskHandler());
}

class _CityMuTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
