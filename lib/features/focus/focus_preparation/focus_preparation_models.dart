enum FocusPreparationStatus {
  notSeen('not_seen'),
  skipped('skipped'),
  completed('completed');

  const FocusPreparationStatus(this.storageValue);
  final String storageValue;

  static FocusPreparationStatus fromStorage(String? raw) {
    for (final value in values) {
      if (value.storageValue == raw) {
        return value;
      }
    }
    return FocusPreparationStatus.notSeen;
  }
}

enum FocusPreparationLaunchContext { preFocus, settings }

enum FocusPreparationFlowOutcome { completed, skipped }
