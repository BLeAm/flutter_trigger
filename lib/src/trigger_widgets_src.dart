part of '../trigger_widgets.dart';

mixin TriggerStateMixin<T extends StatefulWidget, U extends Trigger> on State<T>
    implements Updateable {
  U get trigger;
  List<String> get listenTo;

  @override
  void dispose() {
    trigger.stopListeningAll(this);
    super.dispose();
  }

  @override
  void update() {
    if (mounted) setState(() {});
  }
}

class TriggerScope extends StatefulWidget {
  final List<Trigger> triggers;
  final Widget? child;
  final Widget Function(BuildContext context)? builder;
  final bool autoDispose; // เพิ่ม option เผื่อบางคนไม่อยากให้ dispose อัตโนมัติ

  const TriggerScope({
    super.key,
    required this.triggers,
    this.child,
    this.builder,
    this.autoDispose = true, // default เป็น true เพื่อความปลอดภัย
  }) : assert(child != null || builder != null);

  @override
  State<TriggerScope> createState() => _TriggerScopeState();

  // Helper สำหรับดึงข้อมูล (เหมือนเดิม)
  static U? of<U extends Trigger>(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_InheritedTriggerScope>();
    return scope?.tgMap[U] as U?;
  }
}

class _TriggerScopeState extends State<TriggerScope> {
  late Map<Type, Trigger> _tgMap;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  void _initMap() {
    _tgMap = {};
    for (var t in widget.triggers) {
      _tgMap[t.runtimeType] = t;
    }
  }

  // ใน _TriggerScopeState
  @override
  void dispose() {
    if (widget.autoDispose) {
      for (var trigger in _tgMap.values) {
        // ทำลายเฉพาะตัวที่ถูก spawn ออกมา (ไม่ใช่ Singleton หลักของระบบ)
        if (!trigger.isSingleton) {
          trigger.dispose();
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedTriggerScope(
      tgMap: _tgMap,
      child: widget.builder != null
          ? Builder(builder: (context) => widget.builder!(context))
          : widget.child!,
    );
  }

  @override
  void didUpdateWidget(TriggerScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ถ้า list ของ triggers เปลี่ยน ให้ rebuild map ใหม่
    if (oldWidget.triggers != widget.triggers) {
      _initMap();
    }
  }
}

// แยก InheritedWidget ออกมาไว้ใช้ภายใน
class _InheritedTriggerScope extends InheritedWidget {
  final Map<Type, Trigger> tgMap;

  const _InheritedTriggerScope({required this.tgMap, required super.child});

  @override
  bool updateShouldNotify(covariant _InheritedTriggerScope oldWidget) {
    // ถ้า map เปลี่ยน (มีการสลับ instance) ให้แจ้งเตือนลูกๆ ที่ฟังอยู่
    return oldWidget.tgMap != tgMap;
  }
}

class TriggerWidget<U extends Trigger> extends StatefulWidget {
  TriggerWidget({
    super.key,
    this.debugLabel,
    U? trigger,
    required TriggerFields<U> listenTo,
    required Widget Function(BuildContext context, U trigger) builder,
  }) : _trigger = trigger,
       _listenTo = listenTo.getList(),
       _builder = builder;

  final List<String> _listenTo;
  final Widget Function(BuildContext context, U trigger) _builder;
  final U? _trigger;
  final String? debugLabel;

  @override
  State<TriggerWidget<U>> createState() => _TriggerWidgetState<U>();
}

class _TriggerWidgetState<U extends Trigger> extends State<TriggerWidget<U>>
    with TriggerStateMixin<TriggerWidget<U>, U> {
  U? _trigger;
  @override
  U get trigger => _trigger!;

  /// ฟังก์ชันช่วยในการ resolve หา trigger และจัดการ subscription
  void _resolveAndSubscribe() {
    final newTrigger =
        widget._trigger ?? TriggerScope.of<U>(context) ?? Trigger.of<U>();

    // ถ้า trigger เปลี่ยน instance (ไม่ว่าจะเปลี่ยนจาก widget หรือ scope)
    if (_trigger != newTrigger) {
      _trigger?.stopListeningAll(this);
      _trigger = newTrigger;

      for (final key in listenTo) {
        // ignore: invalid_use_of_protected_member
        _trigger!.listenTo(key, this);
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget._builder(context, trigger);

  @override
  List<String> get listenTo => widget._listenTo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAndSubscribe();
  }

  @override
  void didUpdateWidget(TriggerWidget<U> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ใช้ listEquals เพื่อเช็คว่า "ตัวแปรที่ฟัง" เปลี่ยนไปจริงๆ หรือไม่
    final listenToChanged = !listEquals(oldWidget._listenTo, widget._listenTo);
    final triggerInstanceChanged = oldWidget._trigger != widget._trigger;

    if (listenToChanged || triggerInstanceChanged) {
      _resolveAndSubscribe();
    }
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final label = widget.debugLabel != null ? '[${widget.debugLabel}]' : '';
    return 'TriggerWidget$label';
  }
}
