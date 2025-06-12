import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'services.dart';
import 'settings_screens.dart';
import 'screens.dart';
import 'models.dart';
import 'core.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => LoginScreen(),
          settings: RouteSettings(name: '/'),
        );

      case '/admin_dashboard':
        return MaterialPageRoute(
          builder: (_) => AdminDashboard(),
          settings: RouteSettings(name: '/admin_dashboard'),
        );

      case '/user_dashboard':
        return MaterialPageRoute(
          builder: (_) => UserDashboard(),
          settings: RouteSettings(name: '/user_dashboard'),
        );

      case '/admin/add_client':
        return MaterialPageRoute(
          builder: (_) => ClientFormScreen(),
          settings: RouteSettings(name: '/admin/add_client'),
        );

      case '/admin/edit_client':
        final client = settings.arguments as ClientModel?;
        return MaterialPageRoute(
          builder: (_) => ClientFormScreen(client: client),
          settings: RouteSettings(name: '/admin/edit_client'),
        );

      case '/admin/manage_clients':
        return MaterialPageRoute(
          builder: (_) => ClientManagementScreen(),
          settings: RouteSettings(name: '/admin/manage_clients'),
        );

      case '/admin/manage_users':
        return MaterialPageRoute(
          builder: (_) => UserManagementScreen(),
          settings: RouteSettings(name: '/admin/manage_users'),
        );

      case '/admin/add_user':
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(),
          settings: RouteSettings(name: '/admin/add_user'),
        );

      case '/admin/edit_user':
        final user = settings.arguments as UserModel?;
        return MaterialPageRoute(
          builder: (_) => UserFormScreen(user: user),
          settings: RouteSettings(name: '/admin/edit_user'),
        );

      case '/admin/user_clients':
        final user = settings.arguments as UserModel;
        return MaterialPageRoute(
          builder: (_) => UserClientsScreen(user: user),
          settings: RouteSettings(name: '/admin/user_clients'),
        );

      case '/admin/notifications':
        return MaterialPageRoute(
          builder: (_) => AdminNotificationsScreen(),
          settings: RouteSettings(name: '/admin/notifications'),
        );

      case '/admin/settings':
        return MaterialPageRoute(
          builder: (_) => AdminSettingsScreen(),
          settings: RouteSettings(name: '/admin/settings'),
        );

      case '/user/add_client':
        return MaterialPageRoute(
          builder: (_) => UserClientFormScreen(),
          settings: RouteSettings(name: '/user/add_client'),
        );

      case '/user/edit_client':
        final client = settings.arguments as ClientModel?;
        return MaterialPageRoute(
          builder: (_) => UserClientFormScreen(client: client),
          settings: RouteSettings(name: '/user/edit_client'),
        );

      case '/user/manage_clients':
        return MaterialPageRoute(
          builder: (_) => UserClientManagementScreen(),
          settings: RouteSettings(name: '/user/manage_clients'),
        );

      case '/user/notifications':
        return MaterialPageRoute(
          builder: (_) => UserNotificationsScreen(),
          settings: RouteSettings(name: '/user/notifications'),
        );

      case '/user/settings':
        return MaterialPageRoute(
          builder: (_) => UserSettingsScreen(),
          settings: RouteSettings(name: '/user/settings'),
        );

      case '/view_images':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ImageViewer(
            imageUrls: args['imageUrls'] as List<String>,
            initialIndex: args['initialIndex'] as int? ?? 0,
            clientName: args['clientName'] as String?,
          ),
          settings: RouteSettings(name: '/view_images'),
        );

      case '/client_images':
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ClientImagesScreen(
            client: args['client'] as ClientModel,
            canEdit: args['canEdit'] as bool? ?? false,
          ),
          settings: RouteSettings(name: '/client_images'),
        );

      case '/biometric_setup':
        return MaterialPageRoute(
          builder: (_) => BiometricSetupScreen(),
          settings: RouteSettings(name: '/biometric_setup'),
        );

      case '/not_found':
        return MaterialPageRoute(
          builder: (_) => NotFoundScreen(),
          settings: RouteSettings(name: '/not_found'),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => NotFoundScreen(),
          settings: RouteSettings(name: '/not_found'),
        );
    }
  }

  static void pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void pop(BuildContext context, [Object? result]) {
    Navigator.pop(context, result);
  }

  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  static void pushAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      routeName, 
      (route) => false,
      arguments: arguments,
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحة غير موجودة'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red,
            ),
            SizedBox(height: 20),
            Text(
              'الصفحة المطلوبة غير موجودة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'تحقق من الرابط وحاول مرة أخرى',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: Text('العودة للصفحة الرئيسية'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientImagesScreen extends StatefulWidget {
  final ClientModel client;
  final bool canEdit;

  const ClientImagesScreen({
    Key? key,
    required this.client,
    this.canEdit = false,
  }) : super(key: key);

  @override
  State<ClientImagesScreen> createState() => _ClientImagesScreenState();
}

class _ClientImagesScreenState extends State<ClientImagesScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صور العميل - ${widget.client.clientName}'),
        actions: [
          if (widget.canEdit)
            IconButton(
              icon: Icon(Icons.add_photo_alternate),
              onPressed: _addImages,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : widget.client.imageUrls.isEmpty
              ? _buildEmptyState()
              : _buildImageGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'لا توجد صور للعميل',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          if (widget.canEdit) ...[
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _addImages,
              icon: Icon(Icons.add_photo_alternate),
              label: Text('إضافة صور'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: widget.client.imageUrls.length,
      itemBuilder: (context, index) {
        return _buildImageTile(index);
      },
    );
  }

  Widget _buildImageTile(int index) {
    final imageUrl = widget.client.imageUrls[index];
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _viewImage(index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.error,
                color: Colors.red,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.white, size: 20),
                      onPressed: () => _downloadImage(imageUrl),
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    if (widget.canEdit)
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteImage(index),
                        constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewImage(int index) {
    Navigator.pushNamed(
      context,
      '/view_images',
      arguments: {
        'imageUrls': widget.client.imageUrls,
        'initialIndex': index,
        'clientName': widget.client.clientName,
      },
    );
  }

  void _addImages() async {
    setState(() => _isLoading = true);
    try {
      final result = await ImageService.pickMultipleImages();
      if (result != null && result.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم إضافة ${result.length} صورة')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إضافة الصور')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _downloadImage(String imageUrl) async {
    try {
      await ImageService.downloadImage(imageUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحميل الصورة')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الصورة')),
      );
    }
  }

  void _deleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حذف الصورة'),
        content: Text('هل تريد حذف هذه الصورة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف الصورة')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف الصورة')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

class BiometricSetupScreen extends StatefulWidget {
  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _isChecking = true;
  bool _isAvailable = false;
  List<String> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await BiometricService.isBiometricAvailable();
      final types = await BiometricService.getAvailableBiometrics();
      
      setState(() {
        _isAvailable = isAvailable;
        _availableTypes = types.map((t) => t.toString()).toList();
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إعداد البصمة'),
      ),
      body: _isChecking
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    _isAvailable ? Icons.fingerprint : Icons.fingerprint_outlined,
                    size: 100,
                    color: _isAvailable ? Colors.green : Colors.grey,
                  ),
                  SizedBox(height: 20),
                  Text(
                    _isAvailable ? 'البصمة متاحة' : 'البصمة غير متاحة',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isAvailable ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (_isAvailable) ...[
                    Text(
                      'يمكنك استخدام البصمة لتسجيل الدخول السريع',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'الأنواع المتاحة:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ..._availableTypes.map((type) => Text('• $type')),
                  ] else ...[
                    Text(
                      'لا يمكن استخدام البصمة على هذا الجهاز',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  Spacer(),
                  if (_isAvailable)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('استخدام البصمة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('تخطي'),
                  ),
                ],
              ),
            ),
    );
  }
}