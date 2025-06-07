import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/widgets/custom_text_field.dart';

class CardInputWidget extends StatefulWidget {
  final Function(Map<String, String>) onCardDetailsChanged;

  const CardInputWidget({
    Key? key,
    required this.onCardDetailsChanged,
  }) : super(key: key);

  @override
  State<CardInputWidget> createState() => _CardInputWidgetState();
}

class _CardInputWidgetState extends State<CardInputWidget> {
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String? _cardType;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(_onCardDetailsChanged);
    _cardHolderController.addListener(_onCardDetailsChanged);
    _expiryController.addListener(_onCardDetailsChanged);
    _cvvController.addListener(_onCardDetailsChanged);
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _onCardDetailsChanged() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text.split('/');
    
    _cardType = _detectCardType(cardNumber);
    
    widget.onCardDetailsChanged({
      'cardNumber': cardNumber,
      'cardHolderName': _cardHolderController.text,
      'expiryMonth': expiry.isNotEmpty ? expiry[0] : '',
      'expiryYear': expiry.length > 1 ? expiry[1] : '',
      'cvv': _cvvController.text,
    });
  }

  String? _detectCardType(String cardNumber) {
    if (cardNumber.isEmpty) return null;
    
    // Visa
    if (RegExp(r'^4').hasMatch(cardNumber)) return 'visa';
    
    // Mastercard
    if (RegExp(r'^5[1-5]').hasMatch(cardNumber) ||
        RegExp(r'^2[2-7]').hasMatch(cardNumber)) return 'mastercard';
    
    // American Express
    if (RegExp(r'^3[47]').hasMatch(cardNumber)) return 'amex';
    
    // Discover
    if (RegExp(r'^6(?:011|5)').hasMatch(cardNumber)) return 'discover';
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Card Details',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_cardType != null) ...[
                _getCardIcon(_cardType!),
                SizedBox(width: 8.w),
              ],
            ],
          ),
          SizedBox(height: 16.h),
          
          // Card Number
          CustomTextField(
            controller: _cardNumberController,
            hintText: 'Card Number',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            prefixIcon: Icons.credit_card,
          ),
          SizedBox(height: 12.h),
          
          // Card Holder Name
          CustomTextField(
            controller: _cardHolderController,
            hintText: 'Card Holder Name',
            textCapitalization: TextCapitalization.words,
            prefixIcon: Icons.person,
          ),
          SizedBox(height: 12.h),
          
          // Expiry and CVV Row
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _expiryController,
                  hintText: 'MM/YY',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryDateFormatter(),
                  ],
                  prefixIcon: Icons.date_range,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: CustomTextField(
                  controller: _cvvController,
                  hintText: 'CVV',
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  prefixIcon: Icons.lock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getCardIcon(String cardType) {
    IconData iconData;
    Color color;
    
    switch (cardType) {
      case 'visa':
        iconData = Icons.credit_card;
        color = Colors.blue;
        break;
      case 'mastercard':
        iconData = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'amex':
        iconData = Icons.credit_card;
        color = Colors.green;
        break;
      default:
        iconData = Icons.credit_card;
        color = Colors.grey;
    }
    
    return Icon(
      iconData,
      size: 24.sp,
      color: color,
    );
  }
}

// Custom formatter for card number (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

// Custom formatter for expiry date (MM/YY)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    
    if (text.isEmpty) {
      return newValue;
    }
    
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && text.length > 2) {
        buffer.write('/');
      }
    }
    
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}