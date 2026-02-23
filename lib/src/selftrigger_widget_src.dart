import 'package:flutter/material.dart';

final class SelfTriggerWidgetController<T> {
  T _data;
  T get data => _data;
  late final ValueNotifier<T> _notifier = ValueNotifier<T>(_data);
  ValueNotifier<T> get notifier => _notifier;
  bool _disposed = false;

  SelfTriggerWidgetController({required T data}) : _data = data;

  void update(T data) {
    if (_disposed) return;
    _data = data;
    _notifier.value = data;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _notifier.dispose();
  }
}

final class SelfTriggerRegistry {
  static final Map<Object, SelfTriggerWidgetController> _controllers = {};
  static SelfTriggerWidgetController<T> find<T>(Object key) {
    final ctrl = _controllers[key];
    if (ctrl == null) {
      throw Exception('No SelfTriggerWidgetController found for key "$key"');
    }
    return ctrl as SelfTriggerWidgetController<T>;
  }

  static bool hasKey(String key) => _controllers.containsKey(key);

  static void register<T>(
    Object key,
    SelfTriggerWidgetController<T> controller,
  ) {
    assert(
      !_controllers.containsKey(key),
      'SelfTriggerWidget key "$key" is already registered',
    );
    _controllers[key] = controller;
  }

  static void unregister(Object key) {
    _controllers.remove(key);
  }
}

class SelfTriggerWidget<T> extends StatefulWidget {
  final Object _key;
  final T _initData;
  final Widget Function(BuildContext context, T data) _builder;
  const SelfTriggerWidget({
    super.key,
    required Object skey,
    required T initData,
    required Widget Function(BuildContext context, T data) builder,
  }) : _key = skey,
       _initData = initData,
       _builder = builder;

  @override
  State<SelfTriggerWidget<T>> createState() => _SelfTriggerWidgetState<T>();
}

class _SelfTriggerWidgetState<T> extends State<SelfTriggerWidget<T>> {
  late final _stwCtrl = SelfTriggerWidgetController<T>(data: widget._initData);

  @override
  void initState() {
    super.initState();
    SelfTriggerRegistry.register(widget._key, _stwCtrl);
  }

  @override
  void dispose() {
    SelfTriggerRegistry.unregister(widget._key);
    _stwCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: _stwCtrl.notifier,
      builder: (context, data, child) {
        return widget._builder(context, data);
      },
    );
  }
}
