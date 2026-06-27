import 'package:flutter/widgets.dart';
import 'package:gap/gap.dart';

extension ExtensionNum on num {
  /// SizedBox spacer — width
  Widget get W => Gap(double.parse('$this'));

  /// SizedBox spacer — height
  Widget get H => Gap(double.parse('$this'));
}
