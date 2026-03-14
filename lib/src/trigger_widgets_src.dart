part of '../trigger_widgets.dart';

mixin TriggerStateMixin<T extends StatefulWidget, U extends Trigger> on State<T>
    implements Updateable {
  U? _currentTrigger;

  // ดึง Trigger จากแหล่งต่างๆ ตามลำดับความสำคัญ
  U get trigger => TriggerScope.of<U>(context) ?? Trigger.of<U>();

  // บังคับให้ผู้ใช้ระบุว่าจะฟัง field ไหน
  TriggerFields<U> get listenTo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleSubscription();
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handleSubscription();
  }

  void _handleSubscription() {
    final newTrigger = trigger;

    // ถ้ามีการเปลี่ยน instance ของ Trigger ให้ย้ายการฟังมาที่ตัวใหม่
    if (_currentTrigger != newTrigger) {
      _currentTrigger?.stopListeningAll(this);
      _currentTrigger = newTrigger;

      for (final key in listenTo.getList()) {
        _currentTrigger!.listenTo(key, this);
      }
    }
  }

  @override
  void dispose() {
    _currentTrigger?.stopListeningAll(this); // คืนทรัพยากรเสมอ
    super.dispose();
  }

  @override
  void update() {
    if (!mounted) return;

    final scheduler = SchedulerBinding.instance;

    // ถ้า Flutter กำลังอยู่ในขั้นตอนวาดหน้าจอ (Persistent/Post-Frame)
    if (scheduler.schedulerPhase != SchedulerPhase.idle) {
      scheduler.addPostFrameCallback((_) {
        if (mounted) setState(() {}); // เช็ค mounted อีกครั้งเพื่อความชัวร์
      });
    } else {
      setState(() {});
    }
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
  const TriggerWidget({
    super.key,
    this.debugLabel,
    this.trigger,
    required this.listenTo,
    required this.builder,
  });

  final TriggerFields<U> listenTo;
  final Widget Function(BuildContext context, U trigger) builder;
  final U? trigger; // รองรับการส่ง trigger เข้ามาตรงๆ (Manual Injection)
  final String? debugLabel;

  @override
  State<TriggerWidget<U>> createState() => _TriggerWidgetState<U>();
}

class _TriggerWidgetState<U extends Trigger> extends State<TriggerWidget<U>>
    with TriggerStateMixin<TriggerWidget<U>, U> {
  @override
  TriggerFields<U> get listenTo => widget.listenTo;

  @override
  U get trigger => widget.trigger ?? super.trigger;

  @override
  Widget build(BuildContext context) => widget.builder(context, trigger);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final label = widget.debugLabel != null ? '[${widget.debugLabel}]' : '';
    return 'TriggerWidget$label';
  }
}
