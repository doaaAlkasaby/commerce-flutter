import 'package:flutter/material.dart';

class SizeConfig {
  static void init(BuildContext context) {
    // Initialization helper if needed
  }
}

extension ResponsiveExtension on num {
  // Responsive scaling based on a standard mobile width of 375 and height of 812
  double w(BuildContext context) =>
      (this / 375.0) * MediaQuery.sizeOf(context).width;
  double h(BuildContext context) =>
      (this / 812.0) * MediaQuery.sizeOf(context).height;
  double sp(BuildContext context) =>
      (this / 375.0) * MediaQuery.sizeOf(context).width;
}
