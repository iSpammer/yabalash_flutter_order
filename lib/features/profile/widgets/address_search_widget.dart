import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/services/google_maps_service.dart';

/// Address search widget with Google Places autocomplete
/// Replicates the address search functionality from React Native app
class AddressSearchWidget extends StatefulWidget {
  final Function(GooglePlacePrediction) onPlaceSelected;
  final String? initialQuery;
  final String? hintText;

  const AddressSearchWidget({
    super.key,
    required this.onPlaceSelected,
    this.initialQuery,
    this.hintText,
  });

  @override
  State<AddressSearchWidget> createState() => _AddressSearchWidgetState();
}

class _AddressSearchWidgetState extends State<AddressSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<GooglePlacePrediction> _predictions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
    }
    
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final query = _controller.text.trim();
    
    if (query.length >= 3) {
      _searchPlaces(query);
    } else {
      setState(() {
        _predictions.clear();
        _showSuggestions = false;
      });
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Delay hiding suggestions to allow selection
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await GoogleMapsService.getPlaceAutocomplete(
        input: query,
      );

      if (response != null && response.predictions.isNotEmpty) {
        setState(() {
          _predictions = response.predictions;
          _showSuggestions = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _predictions.clear();
          _showSuggestions = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      setState(() {
        _predictions.clear();
        _showSuggestions = false;
        _isLoading = false;
      });
    }
  }

  void _onPlaceSelected(GooglePlacePrediction prediction) {
    _controller.text = prediction.description;
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
    widget.onPlaceSelected(prediction);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _focusNode.hasFocus 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey[300]!,
              width: _focusNode.hasFocus ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText ?? 'Search for an address...',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16.sp,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[500],
                size: 20.sp,
              ),
              suffixIcon: _isLoading
                  ? Container(
                      width: 20.w,
                      height: 20.w,
                      padding: EdgeInsets.all(12.w),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: Colors.grey[500],
                            size: 20.sp,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _predictions.clear();
                              _showSuggestions = false;
                            });
                          },
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 16.h,
              ),
            ),
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black87,
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        
        // Suggestions list
        if (_showSuggestions && _predictions.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Container(
            constraints: BoxConstraints(
              maxHeight: 300.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _predictions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey[200],
              ),
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey[600],
                    size: 20.sp,
                  ),
                  title: Text(
                    prediction.mainText ?? prediction.description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: prediction.secondaryText != null
                      ? Text(
                          prediction.secondaryText!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 4.h,
                  ),
                  onTap: () => _onPlaceSelected(prediction),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}