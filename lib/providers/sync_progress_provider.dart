import 'package:flutter_riverpod/flutter_riverpod.dart';

class SyncProgressState {
  final bool isSyncing;
  final int totalSteps;
  final int currentStep;
  final String message;

  const SyncProgressState({
    this.isSyncing = false,
    this.totalSteps = 0,
    this.currentStep = 0,
    this.message = '',
  });

  double get progress =>
      totalSteps > 0 ? (currentStep / totalSteps).clamp(0.0, 1.0) : 0.0;

  int get percentage => (progress * 100).toInt();

  SyncProgressState copyWith({
    bool? isSyncing,
    int? totalSteps,
    int? currentStep,
    String? message,
  }) {
    return SyncProgressState(
      isSyncing: isSyncing ?? this.isSyncing,
      totalSteps: totalSteps ?? this.totalSteps,
      currentStep: currentStep ?? this.currentStep,
      message: message ?? this.message,
    );
  }
}

class SyncProgressNotifier extends StateNotifier<SyncProgressState> {
  SyncProgressNotifier() : super(const SyncProgressState());

  void startSync(int totalSteps, String initialMessage) {
    state = SyncProgressState(
      isSyncing: true,
      totalSteps: totalSteps,
      currentStep: 0,
      message: initialMessage,
    );
  }

  void updateProgress(int currentStep, String message) {
    state = state.copyWith(
      currentStep: currentStep,
      message: message,
    );
  }

  void completeSync([String message = '동기화 완료!']) {
    state = state.copyWith(
      currentStep: state.totalSteps,
      message: message,
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      state = const SyncProgressState(); // 완료 후 자동 닫힘
    });
  }
}

final syncProgressProvider =
    StateNotifierProvider<SyncProgressNotifier, SyncProgressState>((ref) {
  return SyncProgressNotifier();
});
