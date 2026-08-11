import 'package:flutter/cupertino.dart';

enum ControlCenterItemType { module, shortcut }

enum MainModule { screenTime, schedule, habits, todo }

enum ControlShortcut {
  rank,
  focusMode,
  blockAppsAndSites,
  streak,
  notes,
}

enum DashboardWidget { focus, notes, winStreak, rank, blackoutButton }

enum SetupStep {
  emptyCenter,
  modulePicker,
  moduleConfirmation,
  shortcutPicker,
  shortcutConfirmation,
  dashboardIntro,
  themePicker,
  dashboardWidgets,
  finalPreview,
  permissions,
}

sealed class ControlCenterItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final ControlCenterItemType type;

  const ControlCenterItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
  });
}

class ControlCenterModuleItem extends ControlCenterItem {
  final MainModule module;

  const ControlCenterModuleItem._({
    required this.module,
    required super.id,
    required super.title,
    required super.subtitle,
    required super.icon,
  }) : super(type: ControlCenterItemType.module);

  factory ControlCenterModuleItem(MainModule module) {
    switch (module) {
      case MainModule.screenTime:
        return const ControlCenterModuleItem._(
          module: MainModule.screenTime,
          id: 'module_screen_time',
          title: 'Screen Time',
          subtitle: 'Contrôle les apps qui te prennent du temps.',
          icon: CupertinoIcons.shield_lefthalf_fill,
        );
      case MainModule.schedule:
        return const ControlCenterModuleItem._(
          module: MainModule.schedule,
          id: 'module_schedule',
          title: 'Schedule',
          subtitle: 'Planifie tes règles selon ton emploi du temps.',
          icon: CupertinoIcons.calendar,
        );
      case MainModule.habits:
        return const ControlCenterModuleItem._(
          module: MainModule.habits,
          id: 'module_habits',
          title: 'Habits',
          subtitle: 'Construis des routines et garde ton élan.',
          icon: CupertinoIcons.flame_fill,
        );
      case MainModule.todo:
        return const ControlCenterModuleItem._(
          module: MainModule.todo,
          id: 'module_todo',
          title: 'To-Do',
          subtitle: 'Transforme tes tâches en actions concrètes.',
          icon: CupertinoIcons.check_mark_circled,
        );
    }
  }
}

class ControlCenterShortcutItem extends ControlCenterItem {
  final ControlShortcut shortcut;

  const ControlCenterShortcutItem._({
    required this.shortcut,
    required super.id,
    required super.title,
    required super.subtitle,
    required super.icon,
  }) : super(type: ControlCenterItemType.shortcut);

  factory ControlCenterShortcutItem(ControlShortcut shortcut) {
    switch (shortcut) {
      case ControlShortcut.rank:
        return const ControlCenterShortcutItem._(
          shortcut: ControlShortcut.rank,
          id: 'shortcut_rank',
          title: 'Rank',
          subtitle: 'Ton classement et ton niveau de performance.',
          icon: CupertinoIcons.star_fill,
        );
      case ControlShortcut.focusMode:
        return const ControlCenterShortcutItem._(
          shortcut: ControlShortcut.focusMode,
          id: 'shortcut_focus_mode',
          title: 'Focus Mode',
          subtitle: 'Lance une session focus en un geste.',
          icon: CupertinoIcons.bolt_fill,
        );
      case ControlShortcut.blockAppsAndSites:
        return const ControlCenterShortcutItem._(
          shortcut: ControlShortcut.blockAppsAndSites,
          id: 'shortcut_block_apps_and_sites',
          title: 'Block apps and sites',
          subtitle: 'Bloque les apps et sites distrayants.',
          icon: CupertinoIcons.shield_fill,
        );
      case ControlShortcut.streak:
        return const ControlCenterShortcutItem._(
          shortcut: ControlShortcut.streak,
          id: 'shortcut_streak',
          title: 'Streak',
          subtitle: 'Ta série et tes habitudes de régularité.',
          icon: CupertinoIcons.flame_fill,
        );
      case ControlShortcut.notes:
        return const ControlCenterShortcutItem._(
          shortcut: ControlShortcut.notes,
          id: 'shortcut_notes',
          title: 'Notes',
          subtitle: 'Tes notes et pensées du moment.',
          icon: CupertinoIcons.doc_text_fill,
        );
    }
  }
}

class ControlCenterCatalog {
  static const List<MainModule> mainModules = [
    MainModule.screenTime,
    MainModule.schedule,
    MainModule.habits,
    MainModule.todo,
  ];

  static const List<ControlShortcut> shortcuts = [
    ControlShortcut.rank,
    ControlShortcut.focusMode,
    ControlShortcut.blockAppsAndSites,
    ControlShortcut.streak,
    ControlShortcut.notes,
  ];

  static const Set<DashboardWidget> defaultWidgets = {
    DashboardWidget.focus,
    DashboardWidget.notes,
    DashboardWidget.winStreak,
    DashboardWidget.blackoutButton,
  };

  static ControlCenterItem? itemFromId(String id) {
    for (final module in mainModules) {
      final item = ControlCenterModuleItem(module);
      if (item.id == id) return item;
    }
    for (final shortcut in shortcuts) {
      final item = ControlCenterShortcutItem(shortcut);
      if (item.id == id) return item;
    }
    return null;
  }
}

class ControlCenterSetupState {
  final List<ControlCenterItem> selectedModules;
  final List<ControlCenterItem> selectedShortcuts;
  final Set<DashboardWidget> enabledDashboardWidgets;
  final SetupStep currentStep;
  final bool hasCompletedSetup;

  const ControlCenterSetupState({
    required this.selectedModules,
    required this.selectedShortcuts,
    required this.enabledDashboardWidgets,
    required this.currentStep,
    required this.hasCompletedSetup,
  });

  factory ControlCenterSetupState.initial() {
    return ControlCenterSetupState(
      selectedModules: const [],
      selectedShortcuts: const [],
      enabledDashboardWidgets: ControlCenterCatalog.defaultWidgets,
      currentStep: SetupStep.emptyCenter,
      hasCompletedSetup: false,
    );
  }

  int get maxSlots => 4;

  List<ControlCenterItem?> get slots {
    final items = <ControlCenterItem>[
      ...selectedModules,
      ...selectedShortcuts,
    ];
    final trimmed = items.take(maxSlots).toList(growable: false);
    final padded = <ControlCenterItem?>[...trimmed];
    while (padded.length < maxSlots) {
      padded.add(null);
    }
    return padded;
  }

  int get filledSlots => slots.whereType<ControlCenterItem>().length;
  int get remainingSlots => (maxSlots - filledSlots).clamp(0, maxSlots);

  bool containsItemId(String itemId) {
    for (final item in selectedModules) {
      if (item.id == itemId) return true;
    }
    for (final item in selectedShortcuts) {
      if (item.id == itemId) return true;
    }
    return false;
  }

  ControlCenterSetupState copyWith({
    List<ControlCenterItem>? selectedModules,
    List<ControlCenterItem>? selectedShortcuts,
    Set<DashboardWidget>? enabledDashboardWidgets,
    SetupStep? currentStep,
    bool? hasCompletedSetup,
  }) {
    return ControlCenterSetupState(
      selectedModules: selectedModules ?? this.selectedModules,
      selectedShortcuts: selectedShortcuts ?? this.selectedShortcuts,
      enabledDashboardWidgets:
          enabledDashboardWidgets ?? this.enabledDashboardWidgets,
      currentStep: currentStep ?? this.currentStep,
      hasCompletedSetup: hasCompletedSetup ?? this.hasCompletedSetup,
    );
  }
}

class ControlCenterConfiguration {
  final List<String> slotItems;
  final Set<String> enabledWidgets;
  final bool setupCompleted;

  const ControlCenterConfiguration({
    required this.slotItems,
    required this.enabledWidgets,
    required this.setupCompleted,
  });

  factory ControlCenterConfiguration.empty() => const ControlCenterConfiguration(
        slotItems: [],
        enabledWidgets: {},
        setupCompleted: false,
      );

  static ControlCenterConfiguration fromState(ControlCenterSetupState state) {
    final slots = <String>[
      for (final item in state.slots)
        if (item == null) '' else item.id,
    ];
    final widgets = state.enabledDashboardWidgets
        .map((w) => w.name)
        .toSet();
    return ControlCenterConfiguration(
      slotItems: slots,
      enabledWidgets: widgets,
      setupCompleted: state.hasCompletedSetup,
    );
  }

  ControlCenterSetupState toState({SetupStep startStep = SetupStep.emptyCenter}) {
    final modules = <ControlCenterItem>[];
    final shortcuts = <ControlCenterItem>[];
    for (final id in slotItems) {
      if (id.trim().isEmpty) continue;
      final item = ControlCenterCatalog.itemFromId(id.trim());
      if (item == null) continue;
      if (item.type == ControlCenterItemType.module) {
        modules.add(item);
      } else {
        shortcuts.add(item);
      }
    }
    final widgetSet = <DashboardWidget>{};
    for (final raw in enabledWidgets) {
      for (final widget in DashboardWidget.values) {
        if (widget.name == raw) widgetSet.add(widget);
      }
    }
    return ControlCenterSetupState(
      selectedModules: modules.take(4).toList(growable: false),
      selectedShortcuts: shortcuts.take(4).toList(growable: false),
      enabledDashboardWidgets:
          widgetSet.isEmpty ? ControlCenterCatalog.defaultWidgets : widgetSet,
      currentStep: startStep,
      hasCompletedSetup: setupCompleted,
    );
  }
}
