import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String? orderNumber;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    this.orderNumber,
  }) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _currentUrl = url;
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _currentUrl = url;
              _isLoading = false;
            });
            _checkPaymentStatus(url);
            
            // Inject JavaScript to intercept cancel button clicks
            _injectCancelButtonHandler();
          },
          onWebResourceError: (WebResourceError error) {
            _showError('Payment failed: ${error.description}');
          },
          onNavigationRequest: (NavigationRequest request) {
            
            // Handle our custom app:// scheme
            if (request.url.startsWith('app://')) {
              if (request.url == 'app://payment.cancelled') {
                _handlePaymentCancel();
              } else if (request.url == 'app://reinject') {
                // Re-inject the script when DOM changes
                Future.delayed(const Duration(milliseconds: 100), () {
                  _injectCancelButtonHandler();
                });
              }
              return NavigationDecision.prevent;
            }
            
            // Check if navigating to success or failure URL
            _checkPaymentStatus(request.url);
            
            // Prevent navigation to certain URLs that indicate cancellation
            final uri = Uri.parse(request.url);
            
            // Check if this is a cancel action from TotalPay
            if (_isCancelUrl(uri) || 
                uri.queryParameters['action'] == 'cancel' ||
                uri.queryParameters['cancelled'] == 'true') {
              // Handle cancellation and prevent navigation
              _handlePaymentCancel();
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    final uri = Uri.parse(url);
    
    // Check for common success/failure patterns
    if (_isSuccessUrl(uri)) {
      _handlePaymentSuccess();
    } else if (_isFailureUrl(uri)) {
      _handlePaymentFailure();
    } else if (_isCancelUrl(uri)) {
      _handlePaymentCancel();
    }
  }

  void _injectCancelButtonHandler() {
    // Inject JavaScript to intercept cancel button clicks
    final script = '''
      // Wait a bit for dynamic content to load
      setTimeout(() => {
        // Look for cancel buttons and intercept clicks
        const cancelButtons = document.querySelectorAll('button, a, input[type="button"], input[type="submit"], [role="button"]');
        console.log('Found ' + cancelButtons.length + ' buttons');
        
        cancelButtons.forEach(button => {
          const text = (button.textContent || button.innerText || '').toLowerCase();
          const value = (button.value || '').toLowerCase();
          const href = (button.href || '').toLowerCase();
          
          if (text.includes('cancel') || value.includes('cancel') || 
              href.includes('cancel') || href.includes('abort') ||
              button.classList.toString().toLowerCase().includes('cancel')) {
            
            console.log('Found cancel button:', text || value);
            
            // Clone and replace to remove existing listeners
            const newButton = button.cloneNode(true);
            button.parentNode.replaceChild(newButton, button);
            
            newButton.addEventListener('click', function(e) {
              console.log('Cancel button clicked');
              e.preventDefault();
              e.stopPropagation();
              // Send message to Flutter
              window.location.href = 'app://payment.cancelled';
              return false;
            }, true);
          }
        });
        
        // Also check if page has standard cancel/back links
        document.addEventListener('click', function(e) {
          const target = e.target;
          if (target && target.tagName) {
            const text = (target.textContent || target.innerText || '').toLowerCase();
            const href = (target.href || '').toLowerCase();
            
            if (text.includes('cancel') || text.includes('back to merchant') || 
                href.includes('cancel') || href.includes('/cart')) {
              e.preventDefault();
              e.stopPropagation();
              window.location.href = 'app://payment.cancelled';
            }
          }
        }, true);
      }, 500);
    ''';
    
    _controller.runJavaScript(script).catchError((error) {
      // Silently handle JavaScript injection errors
    });
  }

  bool _isSuccessUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    final query = uri.queryParameters;
    
    return path.contains('success') ||
           path.contains('complete') ||
           path.contains('thank') ||
           query['status'] == '200' ||
           query['status'] == 'success' ||
           query['payment_status'] == 'success' ||
           query['result'] == 'success';
  }

  bool _isFailureUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    final query = uri.queryParameters;
    
    return path.contains('fail') ||
           path.contains('error') ||
           query['status'] == '0' ||
           query['status'] == 'failed' ||
           query['payment_status'] == 'failed' ||
           query['result'] == 'failed';
  }

  bool _isCancelUrl(Uri uri) {
    final path = uri.path.toLowerCase();
    final query = uri.queryParameters;
    
    return path.contains('cancel') ||
           path.contains('/cart') || // TotalPay might redirect to cart on cancel
           query['status'] == 'cancelled' ||
           query['payment_status'] == 'cancelled' ||
           query['result'] == 'cancel' ||
           query['action'] == 'cancel' ||
           query['cancelled'] == '1' ||
           query['cancelled'] == 'true';
  }

  void _handlePaymentSuccess() async {
    // Clear cart after successful payment
    final cartProvider = context.read<CartProvider>();
    await cartProvider.clearCart();
    
    if (!mounted) return;
    
    // Navigate to order success
    context.go('/order/success', extra: {
      'orderNumber': widget.orderNumber,
      'fromPayment': true,
    });
  }

  void _handlePaymentFailure() {
    _showError('Payment failed. Please try again.');
  }

  void _handlePaymentCancel() {
    // Go back to payment screen
    context.pop();
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    
    // Delay before going back
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Cancel Payment?'),
                  content: const Text('Are you sure you want to cancel this payment?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Continue Payment'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}