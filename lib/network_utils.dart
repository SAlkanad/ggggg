import 'dart:io';
import 'package:flutter/material.dart';

class NetworkUtils {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  static void showNoInternetSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('لا يوجد اتصال بالإنترنت'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  static Widget buildNoInternetWidget({VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'لا يوجد اتصال بالإنترنت',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'تحقق من اتصالك بالإنترنت وحاول مرة أخرى',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }
}

// Wrapper widget for network-dependent operations
class NetworkWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function()? onRetry;

  const NetworkWrapper({
    Key? key,
    required this.child,
    this.onRetry,
  }) : super(key: key);

  @override
  State<NetworkWrapper> createState() => _NetworkWrapperState();
}

class _NetworkWrapperState extends State<NetworkWrapper> {
  bool _hasConnection = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isChecking = true);
    final hasConnection = await NetworkUtils.hasInternetConnection();
    setState(() {
      _hasConnection = hasConnection;
      _isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Center(child: CircularProgressIndicator());
    }

    if (!_hasConnection) {
      return NetworkUtils.buildNoInternetWidget(
        onRetry: () async {
          await _checkConnection();
          if (_hasConnection && widget.onRetry != null) {
            await widget.onRetry!();
          }
        },
      );
    }

    return widget.child;
  }
}