import 'dart:async';
import 'package:flutter/material.dart';

class AutoRefreshWrapper extends StatefulWidget {
  const AutoRefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.interval = const Duration(seconds: 15),
  });

  final Widget child;
  final Future<void> Function() onRefresh;
  final Duration interval;

  @override
  State<AutoRefreshWrapper> createState() => _AutoRefreshWrapperState();
}

class _AutoRefreshWrapperState extends State<AutoRefreshWrapper>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_refreshing || !mounted) return;
    _refreshing = true;
    try {
      await widget.onRefresh();
    } catch (_) {
    } finally {
      if (mounted) {
        _refreshing = false;
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}