import 'package:flutter/material.dart';
import 'package:trigger/trigger.dart';

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

class TriggerScope extends InheritedWidget {
  final Map<Type, Trigger> tgMap = {};
  // final Widget? child; // เก็บไว้รองรับ const
  final Widget Function(BuildContext context)? builder; // แก้ปัญหา Namespace

  TriggerScope({
    super.key,
    required List<Trigger> triggers,
    Widget? child,
    this.builder,
  }) : assert(
         child != null || builder != null,
         'ต้องส่งอย่างใดอย่างหนึ่ง (child หรือ builder)',
       ),
       super(
         // ถ้ามี builder ให้ครอบด้วย Builder เพื่อสร้าง Context ใหม่ทันที
         child: builder != null
             ? Builder(builder: (context) => builder(context))
             : child!,
       ) {
    for (var t in triggers) {
      assert(!tgMap.containsKey(t.runtimeType));
      tgMap[t.runtimeType] = t;
    }
  }
  static U? of<U extends Trigger>(BuildContext context) {
    // 2. หาถังกลาง TriggerScope
    final scope = context.dependOnInheritedWidgetOfExactType<TriggerScope>();
    if (scope == null) return null;
    return scope.tgMap[U] as U?;
  }

  @override
  bool updateShouldNotify(covariant TriggerScope oldWidget) {
    // return oldWidget != tgMap;
    return false;
  }
}

class TriggerWidget<U extends Trigger> extends StatefulWidget {
  TriggerWidget({
    super.key,
    U? trigger,
    required TriggerFields<U> listenTo,
    required Widget Function(BuildContext context, U trigger) builder,
  }) : _trigger = trigger,
       _listenTo = listenTo.getList(),
       _builder = builder;

  final List<String> _listenTo;
  final Widget Function(BuildContext context, U trigger) _builder;
  final U? _trigger;

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

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   final newTrigger =
  //       widget._trigger ?? TriggerScope.of<U>(context) ?? Trigger.of<U>();

  //   if (_trigger != newTrigger) {
  //     if (_trigger != null) {
  //       _trigger!.stopListeningAll(this);
  //     }

  //     _trigger = newTrigger;

  //     for (final key in listenTo) {
  //       // ignore: invalid_use_of_protected_member
  //       trigger.listenTo(key, this);
  //     }
  //   }
  // }

  // @override
  // void didUpdateWidget(TriggerWidget<U> oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   // ถ้า List ของการฟังเปลี่ยนไป ให้เคลียร์ของเก่าแล้วลงทะเบียนใหม่
  //   if (oldWidget._listenTo != widget._listenTo) {
  //     trigger.stopListeningAll(this); // เคลียร์ตัวเก่า
  //     for (final key in widget._listenTo) {
  //       // ignore: invalid_use_of_protected_member
  //       trigger.listenTo(key, this); // ลงทะเบียนตัวใหม่
  //     }
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveAndSubscribe();
  }

  @override
  void didUpdateWidget(TriggerWidget<U> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 1. ถ้า listenTo เปลี่ยน ต้องล้างและจองใหม่เสมอ
    // 2. ถ้า widget._trigger เปลี่ยน (เช่น ส่งค่าใหม่เข้ามาตรงๆ) _resolveAndSubscribe จะจัดการให้
    if (oldWidget._listenTo != widget._listenTo ||
        oldWidget._trigger != widget._trigger) {
      _resolveAndSubscribe();
    }
  }
}
