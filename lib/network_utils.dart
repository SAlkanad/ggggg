import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'error_handler.dart';

class NetworkUtils {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  static bool _hasConnection = true;
  static final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  // Stream to listen to network changes
  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool get hasConnection => _hasConnection;

  /// Initialize network monitoring
  static Future<void> initialize() async {
    try {
      // Check initial connectivity state
      await checkInternetConnection();

      // Start monitoring connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          print('❌ Connectivity monitoring error: $error');
        },
      );

      print('✅ Network monitoring initialized');
    } catch (e) {
      print('❌ Failed to initialize network monitoring: $e');
    }
  }

  /// Dispose network monitoring
  static void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _connectionController.close();
  }

  /// Check internet connection with actual network test
  static Future<bool> checkInternetConnection() async {
    try {
      // First check connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        _updateConnectionStatus(false);
        return false;
      }

      // Test actual internet connectivity
      final hasInternet = await _testInternetAccess();
      _updateConnectionStatus(hasInternet);
      return hasInternet;

    } catch (e) {
      print('❌ Network check error: $e');
      _updateConnectionStatus(false);
      return false;
    }
  }

  /// Test actual internet access by pinging reliable servers
  static Future<bool> _testInternetAccess() async {
    try {
      // Test multiple reliable hosts
      final hosts = [
        'google.com',
        'firebase.google.com',
        'cloudflare.com',
        '8.8.8.8', // Google DNS
      ];

      for (String host in hosts) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(Duration(seconds: 5));

          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            return true;
          }
        } catch (e) {
          // Try next host
          continue;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Handle connectivity changes
  static void _onConnectivityChanged(ConnectivityResult result) async {
    print('📶 Connectivity changed: $result');

    if (result == ConnectivityResult.none) {
      _updateConnectionStatus(false);
    } else {
      // Delay to allow network to stabilize
      await Future.delayed(Duration(seconds: 2));
      await checkInternetConnection();
    }
  }

  /// Update connection status and notify listeners
  static void _updateConnectionStatus(bool hasConnection) {
    if (_hasConnection != hasConnection) {
      _hasConnection = hasConnection;
      _connectionController.add(hasConnection);

      print(hasConnection ? '✅ Internet connected' : '❌ Internet disconnected');
    }
  }

  /// Get current connectivity type
  static Future<ConnectivityResult> getConnectivityType() async {
    try {
      return await _connectivity.checkConnectivity();
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  /// Get connectivity type as Arabic string
  static Future<String> getConnectivityTypeText() async {
    final type = await getConnectivityType();
    switch (type) {
      case ConnectivityResult.wifi:
        return 'واي فاي';
      case ConnectivityResult.mobile:
        return 'بيانات الجوال';
      case ConnectivityResult.ethernet:
        return 'إيثرنت';
      case ConnectivityResult.bluetooth:
        return 'بلوتوث';
      case ConnectivityResult.vpn:
        return 'في بي إن';
      case ConnectivityResult.other:
        return 'اتصال آخر';
      case ConnectivityResult.none:
      default:
        return 'غير متصل';
    }
  }

  /// Show no internet snackbar
  static void showNoInternetSnackBar(BuildContext context, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'لا يوجد اتصال بالإنترنت',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'تحقق من اتصالك وحاول مرة أخرى',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: duration ?? Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: () {
            checkInternetConnection();
          },
        ),
      ),
    );
  }

  /// Show connection restored snackbar
  static void showConnectionRestoredSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('تم استعادة الاتصال بالإنترنت'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Build no internet widget
  static Widget buildNoInternetWidget({
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              customMessage ?? 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            if (onRetry != null) ...[
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(Icons.refresh),
                label: Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            TextButton.icon(
              onPressed: () async {
                try {
                  await _openNetworkSettings();
                } catch (e) {
                  print('Cannot open network settings: $e');
                }
              },
              icon: Icon(Icons.settings, size: 18),
              label: Text('إعدادات الشبكة'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open device network settings
  static Future<void> _openNetworkSettings() async {
    try {
      if (Platform.isAndroid) {
        await const MethodChannel('flutter/platform')
            .invokeMethod('SystemNavigator.routeUpdated');
      }
    } catch (e) {
      // Settings opening not supported
    }
  }

  /// Execute network-dependent operation with automatic retry
  static Future<T?> executeWithNetworkCheck<T>(
      Future<T> Function() operation, {
        BuildContext? context,
        int maxRetries = 3,
        Duration retryDelay = const Duration(seconds: 2),
        bool showSnackBar = true,
      }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        // Check network connection
        final hasInternet = await checkInternetConnection();

        if (!hasInternet) {
          if (context != null && showSnackBar) {
            showNoInternetSnackBar(context);
          }
          return null;
        }

        // Execute operation
        return await operation();

      } catch (e) {
        attempts++;

        if (attempts >= maxRetries) {
          if (context != null) {
            ErrorHandler.showErrorSnackBar(context, e);
          }
          rethrow;
        }

        // Wait before retry
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }
}

/// Network monitoring mixin for widgets
mixin NetworkMonitorMixin<T extends StatefulWidget> on State<T> {
  StreamSubscription<bool>? _networkSubscription;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _startNetworkMonitoring();
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    super.dispose();
  }

  void _startNetworkMonitoring() {
    _networkSubscription = NetworkUtils.connectionStream.listen((hasConnection) {
      if (mounted) {
        if (!hasConnection) {
          _wasOffline = true;
          onNetworkDisconnected();
        } else if (_wasOffline) {
          _wasOffline = false;
          onNetworkReconnected();
        }
      }
    });
  }

  /// Override this method to handle network disconnection
  void onNetworkDisconnected() {
    if (mounted) {
      NetworkUtils.showNoInternetSnackBar(context);
    }
  }

  /// Override this method to handle network reconnection
  void onNetworkReconnected() {
    if (mounted) {
      NetworkUtils.showConnectionRestoredSnackBar(context);
      onNetworkRestored();
    }
  }

  /// Override this method to refresh data when network is restored
  void onNetworkRestored() {
    // Override in subclasses to refresh data
  }
}

/// Wrapper widget for network-dependent operations
class NetworkWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRetry;
  final String? customMessage;
  final bool showOfflineMessage;

  const NetworkWrapper({
    Key? key,
    required this.child,
    this.onRetry,
    this.customMessage,
    this.showOfflineMessage = true,
  }) : super(key: key);

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> with NetworkMonitorMixin {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    setState(() => _isChecking = true);
    await NetworkUtils.checkInternetConnection();
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'جاري فحص الاتصال...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (!NetworkUtils.hasConnection && widget.showOfflineMessage) {
      return NetworkUtils.buildNoInternetWidget(
        onRetry: () async {
          await _checkInitialConnection();
          if (NetworkUtils.hasConnection && widget.onRetry != null) {
            await widget.onRetry!();
          }
        },
        customMessage: widget.customMessage,
      );
    }

    return widget.child;
  }

  @override
  void onNetworkDisconnected() {
    if (widget.showOfflineMessage) {
      super.onNetworkDisconnected();
    }
  }

  @override
  void onNetworkRestored() async {
    super.onNetworkRestored();
    if (widget.onRetry != null) {
      await widget.onRetry!();
    }
  }
}

/// Network-aware Future Builder
class NetworkFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final AsyncWidgetBuilder<T> builder;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext, Object)? errorBuilder;

  const NetworkFutureBuilder({
    Key? key,
    required this.future,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
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