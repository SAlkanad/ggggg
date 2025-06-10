import 'package:flutter/material.dart';
import '../models/client_model.dart';
import '../services/database_service.dart';
import '../core/utils/status_calculator.dart';

class ClientController extends ChangeNotifier {
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  ClientStatus? _statusFilter;

  List<ClientModel> get clients => _filteredClients;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  ClientStatus? get statusFilter => _statusFilter;

  Future<void> loadClients(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        _clients = await DatabaseService.getAllClients();
      } else {
        _clients = await DatabaseService.getClientsByUser(userId);
      }
      
      // Get admin settings for status calculation
      final settings = await DatabaseService.getAdminSettings();
      final statusSettings = settings['clientStatusSettings'] ?? {};
      final greenDays = statusSettings['greenDays'] ?? 30;
      final yellowDays = statusSettings['yellowDays'] ?? 30;
      final redDays = statusSettings['redDays'] ?? 1;
      
      // Update status for all clients
      for (int i = 0; i < _clients.length; i++) {
        final updatedClient = _clients[i].copyWith(
          status: StatusCalculator.calculateStatus(
            _clients[i].entryDate,
            greenDays: greenDays,
            yellowDays: yellowDays,
            redDays: redDays,
          ),
          daysRemaining: StatusCalculator.calculateDaysRemaining(_clients[i].entryDate),
        );
        _clients[i] = updatedClient;
      }

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> refreshClients(String userId, {bool isAdmin = false}) async {
    await loadClients(userId, isAdmin: isAdmin);
  }

  void searchClients(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByStatus(ClientStatus? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredClients = _clients.where((client) {
      bool matchesSearch = _searchQuery.isEmpty || client.matchesSearch(_searchQuery);
      bool matchesStatus = _statusFilter == null || client.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Future<void> updateClientStatus(String clientId, ClientStatus status) async {
    try {
      await DatabaseService.updateClientStatus(clientId, status);
      
      // Update local data
      final index = _clients.indexWhere((client) => client.id == clientId);
      if (index != -1) {
        _clients[index] = _clients[index].copyWith(
          status: status,
          hasExited: status == ClientStatus.white,
          exitDate: status == ClientStatus.white ? DateTime.now() : null,
        );
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await DatabaseService.deleteClient(clientId);
      _clients.removeWhere((client) => client.id == clientId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> addClient(ClientModel client) async {
    try {
      _clients.insert(0, client);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> updateClient(ClientModel client) async {
    try {
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  List<ClientModel> getClientsByStatus(ClientStatus status) {
    return _clients.where((client) => client.status == status).toList();
  }

  List<ClientModel> getExpiringClients(int days) {
    return _clients.where((client) => 
      client.daysRemaining <= days && 
      client.daysRemaining >= 0 && 
      !client.hasExited
    ).toList();
  }

  int getClientsCount() => _clients.length;
  
  int getActiveClientsCount() => _clients.where((c) => !c.hasExited).length;
  
  int getExitedClientsCount() => _clients.where((c) => c.hasExited).length;

  int getFilteredCount() => _filteredClients.length;

  List<ClientModel> getGreenClients() => getClientsByStatus(ClientStatus.green);
  List<ClientModel> getYellowClients() => getClientsByStatus(ClientStatus.yellow);
  List<ClientModel> getRedClients() => getClientsByStatus(ClientStatus.red);
  List<ClientModel> getExitedClients() => getClientsByStatus(ClientStatus.white);
}