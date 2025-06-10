import 'package:flutter/material.dart';
import '../admin/client_form_screen.dart';
import '../../models/client_model.dart';

class UserClientFormScreen extends StatelessWidget {
  final ClientModel? client;

  const UserClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClientFormScreen(client: client);
  }
}
