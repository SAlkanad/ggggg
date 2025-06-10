import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/client_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/widgets/client_card.dart';
import '../../models/client_model.dart';

class UserClientManagementScreen extends StatefulWidget {
  @override
  State<UserClientManagementScreen> createState() => _UserClientManagementScreenState();
}

class _UserClientManagementScreenState extends State<UserClientManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = Provider.of<AuthController>(context, listen: false);
      Provider.of<ClientController>(context, listen: false)
          .loadClients(authController.currentUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إدارة العملاء'),
      ),
      body: Consumer<ClientController>(
        builder: (context, clientController, child) {
          if (clientController.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (clientController.clients.isEmpty) {
            return Center(
              child: Text('لا توجد عملاء مسجلون'),
            );
          }

          return ListView.builder(
            itemCount: clientController.clients.length,
            itemBuilder: (context, index) {
              final client = clientController.clients[index];
              return ClientCard(
                client: client,
                onEdit: () => Navigator.pushNamed(
                  context,
                  '/user/edit_client',
                  arguments: client,
                ),
                onDelete: () => _deleteClient(clientController, client.id),
                onStatusChange: (status) => _updateStatus(clientController, client.id, status),
              );
            },
          );
        },
      ),
    );
  }

  void _deleteClient(ClientController controller, String clientId) async {
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
}
