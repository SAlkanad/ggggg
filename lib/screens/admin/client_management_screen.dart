import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/widgets/client_card.dart';
import '../../core/widgets/notification_dropdown.dart';
import '../../models/client_model.dart';
import '../../services/image_service.dart';

class ClientManagementScreen extends StatefulWidget {
  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final _searchController = TextEditingController();
  ClientStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      Provider.of<ClientController>(context, listen: false)
          .loadClients(authController.currentUser!.id, isAdmin: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة العملاء'),
        actions: [
          NotificationDropdown(),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: _refreshClients,
          ),
        ],
      ),
      body: Consumer<ClientController>(
        builder: (context, clientController, child) {
          return Column(
            children: [
              _buildSearchAndFilter(clientController),
              _buildStatusSummary(clientController),
              Expanded(
                child: _buildClientsList(clientController),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(ClientController controller) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'البحث بالاسم أو رقم الهاتف...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        controller.searchClients('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              controller.searchClients(value);
            },
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('الكل', null, controller),
                SizedBox(width: 8),
                _buildFilterChip('آمن', ClientStatus.green, controller),
                SizedBox(width: 8),
                _buildFilterChip('تحذير', ClientStatus.yellow, controller),
                SizedBox(width: 8),
                _buildFilterChip('خطر', ClientStatus.red, controller),
                SizedBox(width: 8),
                _buildFilterChip('خرج', ClientStatus.white, controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ClientStatus? status, ClientController controller) {
    final isSelected = _selectedStatusFilter == status;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? status : null;
        });
        controller.filterByStatus(_selectedStatusFilter);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: _getStatusColor(status),
    );
  }

  Color _getStatusColor(ClientStatus? status) {
    if (status == null) return Colors.blue.shade200;
    switch (status) {
      case ClientStatus.green:
        return Colors.green.shade200;
      case ClientStatus.yellow:
        return Colors.orange.shade200;
      case ClientStatus.red:
        return Colors.red.shade200;
      case ClientStatus.white:
        return Colors.grey.shade300;
    }
  }

  Widget _buildStatusSummary(ClientController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCard('المجموع', controller.getClientsCount(), Colors.blue),
          _buildSummaryCard('نشط', controller.getActiveClientsCount(), Colors.green),
          _buildSummaryCard('خرج', controller.getExitedClientsCount(), Colors.grey),
          _buildSummaryCard('نتائج البحث', controller.getFilteredCount(), Colors.purple),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList(ClientController controller) {
    if (controller.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (controller.clients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              controller.searchQuery.isNotEmpty || controller.statusFilter != null
                  ? 'لا توجد نتائج مطابقة للبحث'
                  : 'لا توجد عملاء مسجلون',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (controller.searchQuery.isNotEmpty || controller.statusFilter != null) ...[
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _selectedStatusFilter = null);
                  controller.clearFilters();
                },
                child: Text('مسح الفلاتر'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: controller.clients.length,
      itemBuilder: (context, index) {
        final client = controller.clients[index];
        return ClientCard(
          client: client,
          onEdit: () => Navigator.pushNamed(
            context,
            '/admin/edit_client',
            arguments: client,
          ).then((result) {
            if (result == true) _refreshClients();
          }),
          onDelete: () => _deleteClient(controller, client.id),
          onStatusChange: (status) => _updateStatus(controller, client.id, status),
          onViewImages: () => _viewClientImages(client),
        );
      },
    );
  }

  Future<void> _refreshClients() async {
    final authController = Provider.of<AuthController>(context, listen: false);
    final clientController = Provider.of<ClientController>(context, listen: false);
    
    try {
      await clientController.refreshClients(authController.currentUser!.id, isAdmin: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث البيانات')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحديث: ${e.toString()}')),
      );
    }
  }

  void _deleteClient(ClientController controller, String clientId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف هذا العميل؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await controller.deleteClient(clientId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف العميل بنجاح')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف العميل: ${e.toString()}')),
        );
      }
    }
  }

  void _updateStatus(ClientController controller, String clientId, ClientStatus status) async {
    try {
      await controller.updateClientStatus(clientId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث حالة العميل')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديث الحالة: ${e.toString()}')),
      );
    }
  }

  void _viewClientImages(ClientModel client) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'صور العميل: ${client.clientName}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                if (client.visaImageUrl != null)
                  Expanded(
                    child: _buildImageCard(
                      'صورة التأشيرة',
                      client.visaImageUrl!,
                      'visa_${client.id}.jpg',
                    ),
                  ),
                if (client.visaImageUrl != null && client.passportImageUrl != null)
                  SizedBox(width: 16),
                if (client.passportImageUrl != null)
                  Expanded(
                    child: _buildImageCard(
                      'صورة الجواز/الإقامة',
                      client.passportImageUrl!,
                      'passport_${client.id}.jpg',
                    ),
                  ),
              ],
            ),
            if (client.visaImageUrl == null && client.passportImageUrl == null)
              Container(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد صور مرفقة لهذا العميل'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String title, String imageUrl, String fileName) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _viewFullImage(imageUrl, title),
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Icon(Icons.error, color: Colors.red),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _downloadImage(imageUrl, fileName),
          icon: Icon(Icons.download, size: 16),
          label: Text('تحميل'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  void _viewFullImage(String imageUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          backgroundColor: Colors.black,
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            backgroundDecoration: BoxDecoration(color: Colors.black),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.0,
          ),
        ),
      ),
    );
  }

  Future<void> _downloadImage(String imageUrl, String fileName) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('جاري تحميل الصورة...')),
      );

      final file = await ImageService.downloadImage(imageUrl, fileName);
      
      if (file != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم تحميل الصورة بنجاح')),
        );
      } else {
        throw Exception('فشل في تحميل الصورة');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الصورة: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}