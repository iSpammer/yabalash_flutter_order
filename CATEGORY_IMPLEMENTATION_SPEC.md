# Category Section Implementation Specification

## Overview
Implement a comprehensive category browsing experience that matches the React Native app functionality with advanced filtering, sorting, and product display capabilities.

## Requirements

### 1. Category Screen UI Components
- **App Bar Section**:
  - Category banner image as background
  - Back button overlay
  - Share button overlay
  - Category title overlay
  
- **Filter/Sort Section**:
  - Sort dropdown with options:
    - A to Z (alphabetical ascending)
    - Z to A (alphabetical descending)
    - Cost: Low to High
    - Cost: High to Low
    - Popularity
    - Rating
  - Price range filter slider (₹0 - ₹500)
  
- **Product List**:
  - Enhanced product cards with:
    - Product name
    - Vendor name as subtitle
    - Star rating display
    - Price before/after discounts
    - HTML product description (parsed)
    - Add to cart functionality

### 2. API Integration Requirements
- **Category Details API**: `/category/{categoryId}`
  - Category banner, name, description
  - Category metadata
  
- **Category Products API**: `/category/{categoryId}/products`
  - Product list with pagination
  - Filter parameters (price range, sort)
  - Product details including vendor info
  
- **Share Functionality**:
  - Generate shareable category URL
  - Category description and image

### 3. State Management
- **CategoryProvider**:
  - Category details loading
  - Products loading with pagination
  - Filter/sort state management
  - Price range state
  - Loading and error states

### 4. Enhanced Product Card
- **Required Fields**:
  - Product image
  - Product name (main title)
  - Vendor/Restaurant name (subtitle)
  - Rating stars with number
  - Original price (crossed out if discounted)
  - Final price (highlighted)
  - HTML description (parsed and truncated)
  - Add to cart button
  
- **Reuse Existing Components**:
  - Leverage search product card design
  - Enhance with vendor information
  - Improve HTML parsing display
  - Add proper stock status

### 5. Navigation Integration
- **Route Structure**: `/category/{categoryId}`
- **Deep Linking**: Support category sharing URLs
- **Back Navigation**: Return to previous screen
- **Product Navigation**: Tap to open product details

## Technical Architecture

### Models
- `CategoryModel`: Category details and metadata
- `CategoryProductsResponse`: API response structure
- Enhanced `ProductModel`: Include vendor details

### Services
- `CategoryService`: API calls for category data
- Integration with existing `ApiService`

### Providers
- `CategoryProvider`: State management
- Integration with existing provider pattern

### Widgets
- `CategoryScreen`: Main category browsing screen
- `CategoryAppBar`: Custom app bar with banner
- `CategoryFilters`: Sort and filter controls
- `EnhancedProductCard`: Improved product display
- `PriceRangeSlider`: Price filtering component

### Dependencies
- `flutter_rating_bar`: Rating display
- `share_plus`: Category sharing
- `cached_network_image`: Banner images
- Existing HTML parsing utilities

## Implementation Plan

### Phase 1: Core Structure
1. Create CategoryModel and API response models
2. Implement CategoryService with API integration
3. Build CategoryProvider for state management
4. Create basic CategoryScreen layout

### Phase 2: UI Components
1. Build CategoryAppBar with banner and controls
2. Implement filter/sort dropdown
3. Add price range slider
4. Create enhanced product card widget

### Phase 3: Functionality
1. Add sorting logic (A-Z, price, rating, popularity)
2. Implement price range filtering
3. Add share category functionality
4. Handle pagination for product loading

### Phase 4: Integration
1. Update app router with category route
2. Connect navigation from dashboard/search
3. Test API integration thoroughly
4. Verify React Native parity

## API Endpoints Expected

```
GET /category/{categoryId}
Response: {
  "id": number,
  "name": string,
  "description": string,
  "banner_image": string,
  "product_count": number,
  "meta": object
}

GET /category/{categoryId}/products?page=1&limit=20&sort=price&order=asc&min_price=0&max_price=500
Response: {
  "data": {
    "products": [ProductModel],
    "pagination": {
      "current_page": number,
      "total_pages": number,
      "total_items": number
    }
  }
}
```

## Success Criteria
- ✅ Category banner displays properly
- ✅ All sorting options work correctly
- ✅ Price range filter functions
- ✅ Product cards show all required information
- ✅ HTML descriptions are parsed and displayed
- ✅ Share functionality works
- ✅ Navigation flows correctly
- ✅ API integration matches React Native app
- ✅ Performance is optimized with pagination
- ✅ Error handling covers edge cases