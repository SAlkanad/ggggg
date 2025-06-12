import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'error_handler.dart';
import 'models.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _hasConnection = true;
  static final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  static DateTime? _lastNetworkCheck;
  static const Duration _networkCheckInterval = Duration(seconds: 30);

  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool get hasConnection => _hasConnection;

  static Future<void> initialize() async {
    try {
      await checkInternetConnection();
      _startConnectivityMonitoring();
      await _clearNetworkCache();
      print('✅ Network monitoring initialized');
    } catch (e) {
      print('❌ Failed to initialize network monitoring: $e');
    }
  }

  static void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        print('❌ Connectivity monitoring error: $error');
        ErrorHandler.logError('Network monitoring', error);
      },
    );
  }

  static Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasInternet = await checkInternetConnection();

    if (!hasInternet && _hasConnection) {
      await _clearApplicationCacheOnDisconnect();
    } else if (hasInternet && !_hasConnection) {
      await _syncDataOnReconnect();
    }
  }

  static Future<bool> checkInternetConnection() async {
    final now = DateTime.now();
    if (_lastNetworkCheck != null &&
        now.difference(_lastNetworkCheck!) < _networkCheckInterval) {
      return _hasConnection;
    }

    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      if (connectivityResults.contains(ConnectivityResult.none)) {
        _updateConnectionStatus(false);
        return false;
      }

      final hasInternet = await _testInternetAccess();
      _updateConnectionStatus(hasInternet);
      _lastNetworkCheck = now;
      return hasInternet;

    } catch (e) {
      print('❌ Network check error: $e');
      _updateConnectionStatus(false);
      return false;
    }
  }

  static Future<bool> _testInternetAccess() async {
    try {
      final hosts = [
        'google.com',
        'firebase.google.com',
        'cloudflare.com',
        '8.8.8.8',
      ];

      for (String host in hosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(
            Duration(seconds: 5),
          );

          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (e) {
          continue;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  static void _updateConnectionStatus(bool hasConnection) {
    if (_hasConnection != hasConnection) {
      _hasConnection = hasConnection;
      _connectionController.add(hasConnection);
      print('📶 Network status changed: ${hasConnection ? 'Connected' : 'Disconnected'}');
    }
  }

  static Future<void> _clearNetworkCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final networkCacheKeys = prefs.getKeys().where((key) =>
      key.startsWith('network_') ||
          key.startsWith('api_cache_') ||
          key.startsWith('last_sync_')
      ).toList();

      for (final key in networkCacheKeys) {
        await prefs.remove(key);
      }

      CacheManager.clear();
      print('✅ Network cache cleared');
    } catch (e) {
      print('⚠️ Failed to clear network cache: $e');
    }
  }

  static Future<void> _clearApplicationCacheOnDisconnect() async {
    try {
      await ErrorHandler.clearApplicationCache();
      CacheManager.clear();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('last_disconnect_cache_cleared', true);
      await prefs.setInt('last_disconnect_time', DateTime.now().millisecondsSinceEpoch);

      print('✅ Application cache cleared on network disconnect');
    } catch (e) {
      print('❌ Failed to clear cache on disconnect: $e');
    }
  }

  static Future<void> _syncDataOnReconnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastDisconnectTime = prefs.getInt('last_disconnect_time');

      if (lastDisconnectTime != null) {
        final disconnectDuration = DateTime.now().millisecondsSinceEpoch - lastDisconnectTime;

        if (disconnectDuration > 300000) {
          await ErrorHandler.clearApplicationCache();
          CacheManager.clear();
        }
      }

      await prefs.remove('last_disconnect_cache_cleared');
      await prefs.remove('last_disconnect_time');

      print('✅ Data sync completed on reconnect');
    } catch (e) {
      print('❌ Failed to sync data on reconnect: $e');
    }
  }

  static Future<void> forceClearAllCaches() async {
    try {
      CacheManager.clear();
      await ErrorHandler.clearApplicationCache();
      await _clearNetworkCache();

      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();

      for (final key in allKeys) {
        if (key.startsWith('cache_') ||
            key.startsWith('temp_') ||
            key.startsWith('last_') ||
            key.startsWith('sync_') ||
            key.startsWith('api_')) {
          await prefs.remove(key);
        }
      }

      print('✅ All caches forcefully cleared');
    } catch (e) {
      print('❌ Failed to force clear caches: $e');
      throw Exception('فشل في مسح جميع ذاكرة التخزين المؤقت');
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    if (!_connectionController.isClosed) {
      _connectionController.close();
    }
    print('✅ Network monitoring disposed');
  }

  static Future<T> executeWithRetry<T>(
      Future<T> Function() operation, {
        int maxRetries = 3,
        Duration retryDelay = const Duration(seconds: 2),
        bool clearCacheOnRetry = true,
      }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        if (attempts > 0 && clearCacheOnRetry) {
          await forceClearAllCaches();
        }

        final hasConnection = await checkInternetConnection();
        if (!hasConnection) {
          throw Exception('لا يوجد اتصال بالإنترنت');
        }

        return await operation();

      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        print('⚠️ Operation failed (attempt $attempts/$maxRetries): $e');
        await Future.delayed(retryDelay * attempts);
      }
    }

    throw Exception('فشل في تنفيذ العملية بعد $maxRetries محاولات');
  }
}

abstract class NetworkAwareWidget extends StatefulWidget {
  const NetworkAwareWidget({Key? key}) : super(key: key);
}

abstract class NetworkAwareState<T extends NetworkAwareWidget> extends State<T> {
  late StreamSubscription<bool> _networkSubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = NetworkUtils.hasConnection;
    _networkSubscription = NetworkUtils.connectionStream.listen(_onNetworkChanged);
  }

  @override
  void dispose() {
    _networkSubscription.cancel();
    super.dispose();
  }

  void _onNetworkChanged(bool isConnected) {
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
        onNetworkRestored();
      } else {
        onNetworkDisconnected();
      }
    }
  }

  void onNetworkDisconnected() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('انقطع الاتصال بالإنترنت'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void onNetworkRestored() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('تم استعادة الاتصال بالإنترنت'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  bool get isConnected => _isConnected;

  Widget buildNetworkAwareBody();

  @override
  Widget build(BuildContext context) {
    return buildNetworkAwareBody();
  }
}

class NetworkWrapper extends StatefulWidget {
  final Widget child;
  final bool showOfflineMessage;
  final Future<void> Function()? onRetry;
  final String? customMessage;

  const NetworkWrapper({
    Key? key,
    required this.child,
    this.showOfflineMessage = true,
    this.onRetry,
    this.customMessage,
  }) : super(key: key);

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  late StreamSubscription<bool> _networkSubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isConnected = NetworkUtils.hasConnection;
    _networkSubscription = NetworkUtils.connectionStream.listen(_onNetworkChanged);
  }

  @override
  void dispose() {
    _networkSubscription.cancel();
    super.dispose();
  }

  void _onNetworkChanged(bool isConnected) {
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });

      if (isConnected) {
        onNetworkRestored();
      } else {
        onNetworkDisconnected();
      }
    }
  }

  void onNetworkDisconnected() {
    if (widget.showOfflineMessage && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('انقطع الاتصال بالإنترنت'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void onNetworkRestored() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('تم استعادة الاتصال بالإنترنت'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      if (widget.onRetry != null) {
        await widget.onRetry!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected && widget.showOfflineMessage) {
      return _buildOfflineWidget();
    }
    return widget.child;
  }

  Widget _buildOfflineWidget() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 100,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                widget.customMessage ?? 'لا يوجد اتصال بالإنترنت',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  await NetworkUtils.checkInternetConnection();
                  if (widget.onRetry != null) {
                    await widget.onRetry!();
                  }
                },
                icon: Icon(Icons.refresh),
                label: Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  await NetworkUtils.forceClearAllCaches();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم مسح جميع ذاكرة التخزين المؤقت')),
                    );
                  }
                },
                child: Text('مسح ذاكرة التخزين المؤقت'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NetworkFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final AsyncWidgetBuilder<T> builder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext, Object)? errorBuilder;
  final bool clearCacheOnError;

  const NetworkFutureBuilder({
    Key? key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.clearCacheOnError = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NetworkWrapper(
      child: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return loadingBuilder?.call(context) ??
                Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            if (clearCacheOnError) {
              NetworkUtils.forceClearAllCaches().catchError((e) {
                print('Failed to clear cache on error: $e');
              });
            }

            return errorBuilder?.call(context, snapshot.error!) ??
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        ErrorHandler.getArabicErrorMessage(snapshot.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          await NetworkUtils.forceClearAllCaches();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم مسح ذاكرة التخزين المؤقت')),
                          );
                        },
                        child: Text('مسح ذاكرة التخزين المؤقت'),
                      ),
                    ],
                  ),
                );
          }

          return builder(context, snapshot);
        },
      ),
    );
  }
}