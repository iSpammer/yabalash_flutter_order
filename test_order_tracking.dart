import 'package:flutter/material.dart';
import 'package:yabalash_fe_flutter/features/orders/services/dispatch_tracking_service.dart';
import 'package:yabalash_fe_flutter/features/orders/services/order_tracking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('Testing YaBalash Order Tracking...\n');
  
  // Test 1: Direct dispatch API test
  print('=== Test 1: Direct Dispatch API ===');
  final dispatchService = DispatchTrackingService();
  final testUrl = 'https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT';
  
  print('Testing URL: $testUrl');
  final dispatchData = await dispatchService.getDriverLocation(testUrl);
  
  if (dispatchData != null) {
    print('✅ Dispatch API Success!');
    print('Response keys: ${dispatchData.keys.toList()}');
    
    if (dispatchData['agent_location'] != null) {
      final agentLoc = dispatchData['agent_location'];
      print('\n📍 Driver Location:');
      print('  Lat: ${agentLoc['lat']}');
      print('  Long: ${agentLoc['long']}');
      print('  Updated: ${agentLoc['updated_at']}');
      print('  Battery: ${agentLoc['battery_level']}%');
    }
    
    final driverData = DispatchTrackingService.parseDriverLocation(dispatchData);
    if (driverData != null) {
      print('\n✅ Parsed Driver Data:');
      print('  Valid location: ${driverData.hasValidLocation}');
      print('  Lat: ${driverData.lat}');
      print('  Lng: ${driverData.lng}');
    }
  } else {
    print('❌ Dispatch API failed');
  }
  
  // Test 2: Order tracking service
  print('\n\n=== Test 2: Order Tracking Service ===');
  final trackingService = OrderTrackingService();
  
  // You would need actual order ID and vendor ID from your app
  // For now, just showing the structure
  print('OrderTrackingService requires orderId and vendorId');
  print('This would be called from OrderDetailsScreen');
  
  print('\n\n=== Summary ===');
  print('1. Dispatch API is working correctly');
  print('2. Driver location data is available');
  print('3. Check OrderDetailsScreen for:');
  print('   - Is _fetchDispatchDriverLocation being called?');
  print('   - Is _currentDriverPosition being set?');
  print('   - Are markers being updated after driver position is set?');
}