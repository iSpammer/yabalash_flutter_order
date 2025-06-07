#!/usr/bin/env python3
"""
Test Yabalash Dispatch API directly
"""

import requests
import json
from datetime import datetime

def test_direct_dispatch_url():
    """Test a known dispatch tracking URL directly"""
    
    # Example tracking URL from the documentation
    tracking_url = "https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT"
    
    # Convert to API endpoint
    api_url = tracking_url.replace('/order/tracking/', '/order-details/tracking/')
    
    print("=" * 60)
    print("Testing Direct Dispatch API Access")
    print("=" * 60)
    print(f"\nOriginal URL: {tracking_url}")
    print(f"API URL: {api_url}")
    print("\nFetching driver location...")
    
    try:
        response = requests.get(api_url, timeout=10)
        print(f"\nStatus Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("\n✅ Success! Response structure:")
            print(f"Keys: {list(data.keys())}")
            
            if 'agent_location' in data:
                agent = data['agent_location']
                print("\n📍 Driver Location Found:")
                print(f"  Latitude: {agent.get('lat')}")
                print(f"  Longitude: {agent.get('long')}")
                print(f"  Last Update: {agent.get('updated_at')}")
                print(f"  Battery: {agent.get('battery_level')}%")
                print(f"  Device: {agent.get('device_type')}")
                print(f"  Active: {agent.get('is_active')}")
                
                # Google Maps link
                lat = agent.get('lat')
                lng = agent.get('long')
                if lat and lng:
                    print(f"\n🗺️  View on Google Maps: https://www.google.com/maps?q={lat},{lng}")
            else:
                print("\n❌ No agent_location in response")
                print(f"Available data: {json.dumps(data, indent=2)[:500]}...")
            
            if 'tasks' in data:
                print(f"\n📋 Found {len(data['tasks'])} delivery tasks")
                for i, task in enumerate(data['tasks'][:2]):
                    print(f"\nTask {i+1}:")
                    print(f"  Type: {'Pickup' if task.get('task_type_id') == 1 else 'Delivery'}")
                    print(f"  Status: {task.get('task_status')}")
                    print(f"  Address: {task.get('address', 'N/A')[:50]}...")
                    
        else:
            print(f"\n❌ Error: HTTP {response.status_code}")
            print(f"Response: {response.text[:200]}...")
            
    except requests.exceptions.Timeout:
        print("\n❌ Request timed out")
    except requests.exceptions.ConnectionError:
        print("\n❌ Connection error - check internet connection")
    except Exception as e:
        print(f"\n❌ Error: {type(e).__name__}: {str(e)}")

def test_multiple_urls():
    """Test multiple tracking URL patterns"""
    
    test_urls = [
        # Known working example from docs
        "https://dispatch.yabalash.com/order/tracking/976d51/nS7ueT",
        # Try some variations
        "https://dispatch.yabalash.com/order/tracking/2b5f69/test123",
        "https://dispatch.yabalash.com/order/tracking/123456/abc789",
    ]
    
    print("\n\n" + "=" * 60)
    print("Testing Multiple Tracking URLs")
    print("=" * 60)
    
    for url in test_urls:
        api_url = url.replace('/order/tracking/', '/order-details/tracking/')
        print(f"\nTesting: {api_url}")
        
        try:
            response = requests.get(api_url, timeout=5)
            if response.status_code == 200:
                data = response.json()
                if 'agent_location' in data:
                    print("✅ Has driver location")
                else:
                    print("⚠️  No driver location")
            else:
                print(f"❌ HTTP {response.status_code}")
        except:
            print("❌ Failed")

if __name__ == "__main__":
    test_direct_dispatch_url()
    test_multiple_urls()