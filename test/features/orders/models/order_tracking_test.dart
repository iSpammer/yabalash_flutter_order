import 'package:flutter_test/flutter_test.dart';
import 'package:yabalash_fe_flutter/features/orders/models/order_model.dart';

void main() {
  group('Order Tracking Model Tests', () {
    test('should parse dispatcher status with int type field', () {
      final json = {
        'dispatcher_status_option_id': 3,
        'type': 1, // This comes as int from API
        'status_data': {
          'icon': 'icon_url',
          'driver_status': 'On the way',
        },
      };

      final status = DispatcherStatusModel.fromJson(json);

      expect(status.dispatcherStatusOptionId, equals(3));
      expect(status.type, equals('1')); // Should be converted to string
      expect(status.statusData?.driverStatus, equals('On the way'));
    });

    test('should parse dispatcher status with string type field', () {
      final json = {
        'dispatcher_status_option_id': '5',
        'type': '2',
        'status_data': {
          'icon': 'icon_url',
          'driver_status': 'Delivered',
        },
      };

      final status = DispatcherStatusModel.fromJson(json);

      expect(status.dispatcherStatusOptionId, equals(5));
      expect(status.type, equals('2'));
      expect(status.statusData?.driverStatus, equals('Delivered'));
    });

    test('should parse vendor detail with tracking info', () {
      final json = {
        'id': 123,
        'vendor_id': 456,
        'vendor_name': 'Test Restaurant',
        'logo': {'image_s3_url': 'https://example.com/logo.png'},
        'dispatch_traking_url': 'https://tracking.example.com/order/123',
        'dispatcher_status_option_id': '4',
        'vendor_dispatcher_status': [
          {
            'dispatcher_status_option_id': 1,
            'type': 1,
            'status_data': {'driver_status': 'Order Accepted'},
          },
          {
            'dispatcher_status_option_id': 2,
            'type': '2',
            'status_data': {'driver_status': 'Driver Assigned'},
          },
        ],
        'vendor_dispatcher_status_count': '6',
        'dispatcher_status_icons': ['icon1.png', 'icon2.png'],
        'order_status': {
          'current_status': {
            'id': 4,
            'title': 'Out for delivery',
          },
        },
      };

      final vendorDetail = OrderVendorDetailModel.fromJson(json);

      expect(vendorDetail.id, equals(123));
      expect(vendorDetail.vendorId, equals(456));
      expect(vendorDetail.vendorName, equals('Test Restaurant'));
      expect(vendorDetail.logo, equals('https://example.com/logo.png'));
      expect(vendorDetail.dispatchTrakingUrl, equals('https://tracking.example.com/order/123'));
      expect(vendorDetail.dispatcherStatusOptionId, equals(4));
      expect(vendorDetail.vendorDispatcherStatus?.length, equals(2));
      expect(vendorDetail.vendorDispatcherStatusCount, equals(6));
      expect(vendorDetail.dispatcherStatusIcons?.length, equals(2));
      expect(vendorDetail.orderStatus?.currentStatus?.title, equals('Out for delivery'));
    });

    test('should handle missing optional fields', () {
      final json = {
        'id': 123,
        'vendor_id': 456,
        'vendor_name': null,
        'logo': null,
        'dispatch_traking_url': null,
        'dispatcher_status_option_id': null,
        'vendor_dispatcher_status': null,
        'vendor_dispatcher_status_count': null,
        'dispatcher_status_icons': null,
        'order_status': null,
      };

      final vendorDetail = OrderVendorDetailModel.fromJson(json);

      expect(vendorDetail.id, equals(123));
      expect(vendorDetail.vendorId, equals(456));
      expect(vendorDetail.vendorName, isNull);
      expect(vendorDetail.logo, isNull);
      expect(vendorDetail.dispatchTrakingUrl, isNull);
      expect(vendorDetail.dispatcherStatusOptionId, isNull);
      expect(vendorDetail.vendorDispatcherStatus, isNull);
      expect(vendorDetail.vendorDispatcherStatusCount, equals(6)); // Default value
      expect(vendorDetail.dispatcherStatusIcons, isNull);
      expect(vendorDetail.orderStatus, isNull);
    });

    test('should parse complete order with tracking info', () {
      final json = {
        'id': 1001,
        'user_id': 123,
        'order_status_option_id': 4,
        'status_name': 'Out for delivery',
        'total_amount': '125.50',
        'created_at': '2024-01-15 10:30:00',
        'order_number': 'ORD-1001',
        'vendors': [
          {
            'id': 1,
            'vendor_id': 10,
            'vendor_name': 'Pizza Palace',
            'dispatch_traking_url': 'https://track.example.com/1001',
            'dispatcher_status_option_id': 5,
            'vendor_dispatcher_status_count': 6,
            'vendor_dispatcher_status': [
              {
                'dispatcher_status_option_id': 5,
                'type': '1',
                'status_data': {
                  'driver_status': 'Order picked up',
                },
              },
            ],
          },
        ],
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, equals(1001));
      expect(order.statusId, equals(4));
      expect(order.status, equals('Out for delivery'));
      expect(order.totalAmount, equals(125.50));
      expect(order.vendors?.length, equals(1));
      
      final vendor = order.vendors!.first;
      expect(vendor.vendorName, equals('Pizza Palace'));
      expect(vendor.dispatchTrakingUrl, equals('https://track.example.com/1001'));
      expect(vendor.dispatcherStatusOptionId, equals(5));
      
      // Test convenience methods
      expect(order.primaryVendor, isNotNull);
      expect(order.currentDispatcherStatus, equals(5));
      expect(order.trackingUrl, equals('https://track.example.com/1001'));
      expect(order.hasTrackingUrl, isTrue);
    });
  });
}