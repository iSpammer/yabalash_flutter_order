#!/usr/bin/env python3
"""
YaBalash REAL Driver Location Tracking - Working Solution
This script demonstrates how to get actual real-time driver GPS coordinates
"""

import requests
import json
import time
import re
from datetime import datetime

class YaBalashRealTimeTracking:
    def __init__(self):
        self.api_base = "https://yabalash.com/api/v1"
        self.dispatch_base = "https://dispatch.yabalash.com"
        self.code = "2b5f69"
        self.auth_token = None
    
    def login(self, email, password):
        """Login to get auth token"""
        response = requests.post(
            f"{self.api_base}/auth/login",
            headers={"Content-Type": "application/json", "code": self.code},
            json={"email": email, "password": password, "device_type": "web", "device_token": "test"}
        )
        
        if response.status_code == 200:
            self.auth_token = response.json()["data"]["auth_token"]
            return True
        return False
    
    def get_order_tracking_url(self, order_number):
        """Get the dispatch tracking URL for an order"""
        headers = {
            "Authorization": self.auth_token,
            "Accept": "application/json",
            "code": self.code
        }
        
        # Get orders list
        response = requests.get(f"{self.api_base}/orders?limit=50", headers=headers)
        orders = response.json()["data"]["data"]
        
        # Find the order
        for order in orders:
            if order["order_number"] == str(order_number):
                return order.get("dispatch_traking_url"), order
        
        return None, None
    
    def get_driver_location(self, tracking_url):
        """Get real-time driver location from dispatch tracking URL"""
        if not tracking_url:
            return None
        
        # Convert tracking URL to API endpoint
        # From: https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT
        # To: https://dispatch.yabalash.com/order-details/tracking/976d51/nS7ueT
        api_url = tracking_url.replace('/order/tracking/', '/order-details/tracking/')
        
        try:
            response = requests.get(api_url)
            if response.status_code == 200:
                data = response.json()
                return data.get("agent_location"), data.get("tasks", [])
        except:
            pass
        
        return None, []
    
    def track_driver_realtime(self, order_number, interval=5):
        """Track driver location in real-time"""
        print(f"\n🚗 Starting Real-Time Driver Tracking for Order #{order_number}")
        print("=" * 60)
        
        # Get tracking URL
        tracking_url, order_info = self.get_order_tracking_url(order_number)
        
        if not tracking_url:
            print(f"❌ No tracking URL found for order #{order_number}")
            return
        
        print(f"✅ Found tracking URL: {tracking_url}")
        print(f"📦 Restaurant: {order_info.get('vendor', {}).get('name', 'N/A')}")
        print(f"💰 Order Amount: {order_info.get('payable_amount', 'N/A')}")
        print("\n" + "=" * 60)
        
        previous_location = None
        
        while True:
            try:
                # Get current driver location
                agent_location, tasks = self.get_driver_location(tracking_url)
                
                print(f"\n🕒 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
                
                if agent_location:
                    lat = float(agent_location.get("lat", 0))
                    lng = float(agent_location.get("long", 0))
                    
                    print(f"\n📍 DRIVER LOCATION:")
                    print(f"   Latitude: {lat}")
                    print(f"   Longitude: {lng}")
                    print(f"   Last Update: {agent_location.get('updated_at')}")
                    print(f"   Battery: {agent_location.get('battery_level')}%")
                    print(f"   Device: {agent_location.get('device_type')}")
                    
                    # Check if location changed
                    if previous_location:
                        prev_lat = float(previous_location.get("lat", 0))
                        prev_lng = float(previous_location.get("long", 0))
                        
                        if lat != prev_lat or lng != prev_lng:
                            print(f"   📍 DRIVER MOVED!")
                            # Calculate approximate distance (simplified)
                            distance = ((lat - prev_lat)**2 + (lng - prev_lng)**2)**0.5 * 111  # km
                            print(f"   Distance moved: ~{distance:.2f} km")
                    
                    # Google Maps URL
                    maps_url = f"https://www.google.com/maps?q={lat},{lng}"
                    print(f"\n   🗺️  View on Google Maps: {maps_url}")
                    
                    previous_location = agent_location
                else:
                    print("⏳ No driver location available yet (driver not assigned)")
                
                # Show task status
                if tasks:
                    print(f"\n📋 Delivery Tasks:")
                    for i, task in enumerate(tasks):
                        status_map = {
                            "1": "Pending",
                            "2": "Assigned", 
                            "3": "In Progress",
                            "4": "Completed",
                            "5": "Failed"
                        }
                        status = status_map.get(task.get("task_status"), "Unknown")
                        task_type = "Pickup" if task.get("task_type_id") == 1 else "Delivery"
                        print(f"   {i+1}. {task_type} - Status: {status}")
                        print(f"      Address: {task.get('address', 'N/A')[:50]}...")
                
                print("\n" + "-" * 60)
                print(f"Updating in {interval} seconds... (Press Ctrl+C to stop)")
                
                time.sleep(interval)
                
            except KeyboardInterrupt:
                print("\n\n⏹️  Tracking stopped.")
                break
            except Exception as e:
                print(f"\n❌ Error: {str(e)}")
                time.sleep(interval)

def main():
    print("=" * 60)
    print("YaBalash REAL-TIME Driver Location Tracking")
    print("=" * 60)
    
    tracker = YaBalashRealTimeTracking()
    
    # Login
    print("\n🔐 Logging in...")
    if tracker.login("admin@yabalash.com", "admin@panel24"):
        print("✅ Login successful!")
    else:
        print("❌ Login failed!")
        return
    
    # Get available orders with tracking
    print("\n📋 Finding orders with driver tracking...")
    headers = {
        "Authorization": tracker.auth_token,
        "Accept": "application/json",
        "code": tracker.code
    }
    
    response = requests.get(f"{tracker.api_base}/orders?limit=20", headers=headers)
    print(f"Response status: {response.status_code}")
    if response.status_code == 200:
        try:
            data = response.json()
            print(f"Response keys: {data.keys() if isinstance(data, dict) else 'Not a dict'}")
            
            # Handle different response structures
            if "data" in data:
                if isinstance(data["data"], dict) and "data" in data["data"]:
                    orders = data["data"]["data"]
                elif isinstance(data["data"], list):
                    orders = data["data"]
                else:
                    orders = []
            else:
                orders = []
            
            print(f"Found {len(orders)} total orders")
            
            # Filter orders with tracking URLs
            tracked_orders = [o for o in orders if o.get("dispatch_traking_url")]
            
            if tracked_orders:
                print(f"\n✅ Found {len(tracked_orders)} orders with tracking:")
                for order in tracked_orders[:5]:  # Show first 5
                    vendor_name = order.get('vendor', {}).get('name', 'Unknown') if isinstance(order.get('vendor'), dict) else 'Unknown'
                    status = order.get('order_status', {}).get('current_status', {}).get('title', 'Unknown')
                    print(f"   Order #{order['order_number']} - {vendor_name} - Status: {status}")
                    print(f"   Tracking: {order['dispatch_traking_url']}")
                
                # Track the first order
                first_order = tracked_orders[0]['order_number']
                print(f"\n🎯 Starting tracking for Order #{first_order}")
                tracker.track_driver_realtime(first_order, interval=4)
            else:
                print("❌ No orders with tracking URLs found")
        except Exception as e:
            print(f"❌ Error parsing response: {e}")
            print(f"Response content: {response.text[:500]}")
    else:
        print(f"❌ Failed to get orders: {response.status_code}")
        print(f"Response: {response.text[:500]}")

if __name__ == "__main__":
    main()