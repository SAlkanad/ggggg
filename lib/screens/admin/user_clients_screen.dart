import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/client_model.dart';
import '../../controllers/user_controller.dart';
import '../../core/widgets/client_card.dart';

class UserClientsScreen extends StatefulWidget {
  final UserModel user;

  const UserClientsScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<UserClientsScreen> createState() => _UserClientsScreenState();
}

class _UserClientsScreenState extends State<UserClientsScreen> {
  List<ClientModel> _clients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserClients();
  }

  Future<void> _loadUserClients() async {
    setState(() => _isLoading = true);
    
    try {
      final userController = Provider.of<UserController>(context, listen: false);
      _clients = await userController.getUserClients(widget.user.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب العملاء: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('عملاء ${widget.user.name}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('لا توجد عملاء لهذا المستخدم', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _clients.length,
                  itemBuilder: (context, index) {
                    final client = _clients[index];
                    return ClientCard(
                      client: client,
                      // No edit/delete actions for admin viewing user clients
                    );
                  },
                ),
    );
  }
}
