import 'dart:async';
import '../models/client_model.dart';
import '../core/utils/status_calculator.dart';
import 'database_service.dart';

class StatusUpdateService {
  static Timer? _timer;
  static bool _isRunning = false;
  
  static void startAutoStatusUpdate() {
    if (_isRunning) return;
    
    _isRunning = true;
    print('🔄 Starting auto status update service...');
    
    // Run immediately once
    _updateAllClientStatuses();
    
    // Then run every 6 hours
    _timer = Timer.periodic(Duration(hours: 6), (timer) {
      _updateAllClientStatuses();
    });
  }
  
  static void stopAutoStatusUpdate() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    print('⏹️ Auto status update service stopped');
  }
  
  static Future<void> _updateAllClientStatuses() async {
    try {
      print('🔄 Running auto status update...');
      
      final clients = await DatabaseService.getAllClients();
      final settings = await DatabaseService.getAdminSettings();
      
      final statusSettings = settings['clientStatusSettings'] ?? {};
      final greenDays = statusSettings['greenDays'] ?? 30;
      final yellowDays = statusSettings['yellowDays'] ?? 30;
      final redDays = statusSettings['redDays'] ?? 1;
      
      int updatedCount = 0;
      
      for (final client in clients) {
        if (!client.hasExited) {
          final currentDaysRemaining = StatusCalculator.calculateDaysRemaining(client.entryDate);
          final newStatus = StatusCalculator.calculateStatus(
            client.entryDate,
            greenDays: greenDays,
            yellowDays: yellowDays,
            redDays: redDays,
          );
          
          // Update if status changed or days remaining changed significantly
          if (newStatus != client.status || 
              (currentDaysRemaining - client.daysRemaining).abs() > 0) {
            
            await DatabaseService.updateClientWithStatus(
              client.id, 
              newStatus, 
              currentDaysRemaining
            );
            updatedCount++;
          }
        }
      }
      
      print('✅ Auto status update completed. Updated $updatedCount clients.');
      
    } catch (e) {
      print('❌ Auto status update error: $e');
    }
  }
  
  static Future<void> forceUpdateAllStatuses() async {
    print('🔄 Force updating all client statuses...');
    await _updateAllClientStatuses();
  }
}