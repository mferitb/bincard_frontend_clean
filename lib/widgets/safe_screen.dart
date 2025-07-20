import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A screen wrapper that prevents users from refreshing the page or going back
/// accidentally. This is particularly useful for authentication screens where
/// you want to ensure the user completes the flow.
class SafeScreen extends StatelessWidget {
  final Widget child;
  final bool canPop;
  final String? warningMessage;

  const SafeScreen({
    Key? key,
    required this.child,
    this.canPop = false,
    this.warningMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If canPop is true, allow normal back button behavior
        if (canPop) return true;

        // Otherwise, show a warning message if provided
        if (warningMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(warningMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        // Prevent back navigation
        return false;
      },
      child: child,
    );
  }
}

/// Use this function to navigate between screens while maintaining the SafeScreen protection.
/// This is specifically for navigation within the auth flow where we want to prevent
/// accidental back navigation or refreshing.
void safeNavigate(BuildContext context, String routeName, {Object? arguments}) {
  // Find the root navigator to handle the navigation
  Navigator.of(context, rootNavigator: true).pushReplacementNamed(
    routeName,
    arguments: arguments,
  );
}
