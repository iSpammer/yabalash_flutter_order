import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';

class CustomCountryPicker extends StatelessWidget {
  final Function(CountryCode) onChanged;
  final String initialSelection;
  final List<String> favorite;
  final bool showCountryOnly;
  final bool showOnlyCountryWhenClosed;
  final bool alignLeft;
  final EdgeInsets padding;

  const CustomCountryPicker({
    Key? key,
    required this.onChanged,
    required this.initialSelection,
    this.favorite = const ['+91', 'IN'],
    this.showCountryOnly = false,
    this.showOnlyCountryWhenClosed = false,
    this.alignLeft = false,
    this.padding = EdgeInsets.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CountryCodePicker(
      onChanged: (country) {
        // Block Israel selection
        if (country.code == 'IL') {
          // Show Palestine instead
          onChanged(CountryCode(
            name: 'Palestine',
            code: 'PS',
            dialCode: '+970',
            flagUri: 'flags/ps.png',
          ));
          
          // Show a subtle message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Palestine selected'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          onChanged(country);
        }
      },
      initialSelection: initialSelection == 'IL' ? 'PS' : initialSelection,
      favorite: favorite,
      showCountryOnly: showCountryOnly,
      showOnlyCountryWhenClosed: showOnlyCountryWhenClosed,
      alignLeft: alignLeft,
      padding: padding,
      // Unfortunately, country_code_picker doesn't support excluding countries
      // So we handle it in the onChanged callback
    );
  }
}