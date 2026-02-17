import 'package:flutter/material.dart';
import 'package:flutter_trigger/trigger_widgets.dart';
import 'package:trigger/trigger.dart';

export 'src/selftrigger_widget_src.dart';
export 'src/trigger_widgets_src.dart';

extension TriggerContextX on BuildContext {
  /// ค้นหา Trigger จาก Scope ที่ใกล้ที่สุด หรือถ้าไม่เจอให้หาจาก Global Registry
  T? trigger<T extends Trigger>() {
    // 1. ค้นหาใน InheritedWidget (TriggerScope) ก่อนเสมอ
    // การใช้ dependOnInheritedWidgetOfExactType จะทำให้ Widget นี้
    // Rebuild อัตโนมัติถ้าตัวแปรใน TriggerScope เปลี่ยน (ถ้าคุณทำ Logic นั้นไว้)
    // หรือถ้าแค่ต้องการค่าเฉยๆ สามารถใช้ getInheritedWidgetOfExactType แทนได้
    final scope = dependOnInheritedWidgetOfExactType<TriggerScope>();

    if (scope != null) {
      final instance = scope.tgMap[T];
      if (instance != null) return instance as T;
    }

    // 2. ถ้าใน Scope ไม่มี ให้ถอยไปหาที่ Global Singleton Registry
    try {
      return Trigger.of<T>();
    } catch (_) {
      // กรณีหาไม่เจอเลยจริงๆ
      return null;
    }
  }
}
