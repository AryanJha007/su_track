import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class LoadingButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry? padding;
  final OutlinedBorder? shape;
  
  const LoadingButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.child,
    this.backgroundColor = Colors.red,
    this.padding,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
          shape: shape ?? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
          ? Center(
              child: Image.asset(
                'assets/images/loading.gif',
                height: 40,
                width: 40,
                color: themeProvider.lionColor,
              ),
            )
          : this.child,
      ),
    );
  }
}
