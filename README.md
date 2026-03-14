# Flutter Trigger 🚀

[![Pub Version](https://img.shields.io/badge/pub-v1.0.0-blue.svg)](https://pub.dev/packages/flutter_trigger)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-%E2%9C%93-02569B.svg?style=flat&logo=flutter)](https://flutter.dev)

A powerful, high-performance bridge package that connects the **Trigger** state management system with Flutter. `flutter_trigger` provides a suite of widgets and mixins designed to make your Flutter UI reactive, clean, and efficient.

---

## ✨ Features

- 🏗️ **TriggerScope**: Elegant dependency injection and lifecycle management for your Triggers.
- ⚡ **TriggerWidget**: Fine-grained reactive builders that listen only to what matters.
- 🧩 **TriggerStateMixin**: Seamlessly integrate Trigger listening into any `StatefulWidget`.
- 🔍 **TriggerContextX**: Easy access to Triggers anywhere in your widget tree via `context`.
- 🛠️ **SelfTriggerWidget**: Lightweight, key-based state updates for specific UI nodes.
- 🚀 **Performance Optimized**: Built-in protection against unnecessary rebuilds using `SchedulerBinding`.

---

## 📦 Installation

Add `flutter_trigger` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_trigger:
    git:
      url: https://github.com/your-username/flutter_trigger.git # Or your local path
```

---

## 🚀 Getting Started

### 1. Define your Trigger

```dart
class CounterTrigger extends Trigger {
  int count = 0;

  void increment() {
    count++;
    notify('count'); // Notify listeners of 'count' changes
  }
}
```

### 2. Provide the Trigger

Use `TriggerScope` to provide your Triggers to the widget tree.

```dart
TriggerScope(
  triggers: [CounterTrigger()],
  child: MyApp(),
)
```

### 3. Consume the State

#### Using `TriggerWidget` (Recommended)

Listen to specific fields and rebuild only when they change.

```dart
TriggerWidget<CounterTrigger>(
  listenTo: TriggerFields(['count']),
  builder: (context, trigger) {
    return Text('Count: ${trigger.count}');
  },
)
```

#### Using `TriggerContextX`

Access your Trigger instance directly from `BuildContext`.

```dart
final trigger = context.trigger<CounterTrigger>();
trigger?.increment();
```

---

## 🛠️ Advanced Usage

### TriggerStateMixin

For complex widgets where you need more control over the lifecycle or multiple listeners.

```dart
class MyComplexWidget extends StatefulWidget {
  @override
  State<MyComplexWidget> createState() => _MyComplexWidgetState();
}

class _MyComplexWidgetState extends State<MyComplexWidget> 
    with TriggerStateMixin<MyComplexWidget, CounterTrigger> {
  
  @override
  TriggerFields<CounterTrigger> get listenTo => TriggerFields(['count']);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: ${trigger.count}'),
        ElevatedButton(
          onPressed: () => trigger.increment(),
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### SelfTriggerWidget

Perfect for high-frequency updates or localized state without creating a full `Trigger` class.

```dart
SelfTriggerWidget<int>(
  skey: 'unique_key',
  initData: 0,
  builder: (context, data) {
    return Text('Data: $data');
  },
)

// To update from anywhere:
SelfTriggerRegistry.find<int>('unique_key').update(newValue);
```

---

## 💡 Best Practices

1. **Keep Listeners Focused**: Use `TriggerFields` to listen only to the specific properties that affect your widget to minimize rebuilds.
2. **Scoping**: Use `TriggerScope` at the lowest possible level in the tree to manage resources effectively.
3. **Auto-Dispose**: `TriggerScope` automatically disposes of non-singleton Triggers by default. You can disable this with `autoDispose: false` if needed.

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

---

<p align="center">Made with ❤️ for the Flutter Community</p>
