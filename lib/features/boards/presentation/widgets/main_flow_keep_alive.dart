import 'package:flutter/material.dart';

/// Mantiene viva la página del [PageView] principal (scroll, estado local).
class MainFlowKeepAlive extends StatefulWidget {
  const MainFlowKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<MainFlowKeepAlive> createState() => _MainFlowKeepAliveState();
}

class _MainFlowKeepAliveState extends State<MainFlowKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
