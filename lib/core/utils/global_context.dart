import 'package:flutter/material.dart';

class GlobalContext {
  final GlobalKey<NavigatorState> globalNavigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext get context => globalNavigatorKey.currentContext!;
}
