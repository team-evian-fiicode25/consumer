import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/services/settings_service.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class SettingsLoaded extends SettingsEvent {}

class TrafficUpdatesChanged extends SettingsEvent {
  final bool showTrafficUpdates;

  const TrafficUpdatesChanged(this.showTrafficUpdates);

  @override
  List<Object> get props => [showTrafficUpdates];
}

class DistanceUnitChanged extends SettingsEvent {
  final String distanceUnit;

  const DistanceUnitChanged(this.distanceUnit);

  @override
  List<Object> get props => [distanceUnit];
}

class PreferredTransportChanged extends SettingsEvent {
  final String preferredTransport;

  const PreferredTransportChanged(this.preferredTransport);

  @override
  List<Object> get props => [preferredTransport];
}

class NotificationsChanged extends SettingsEvent {
  final bool enableNotifications;

  const NotificationsChanged(this.enableNotifications);

  @override
  List<Object> get props => [enableNotifications];
}

class LocationHistoryChanged extends SettingsEvent {
  final bool enableLocationHistory;

  const LocationHistoryChanged(this.enableLocationHistory);

  @override
  List<Object> get props => [enableLocationHistory];
}

class SoundEffectsChanged extends SettingsEvent {
  final bool enableSoundEffects;

  const SoundEffectsChanged(this.enableSoundEffects);

  @override
  List<Object> get props => [enableSoundEffects];
}

class SettingsState extends Equatable {
  final bool showTrafficUpdates;
  final String distanceUnit;
  final String preferredTransport;
  final bool enableNotifications;
  final bool enableLocationHistory;
  final bool enableSoundEffects;
  final bool isLoading;

  const SettingsState({
    required this.showTrafficUpdates,
    required this.distanceUnit,
    required this.preferredTransport,
    required this.enableNotifications,
    required this.enableLocationHistory,
    required this.enableSoundEffects,
    this.isLoading = false,
  });

  factory SettingsState.initial() => const SettingsState(
        showTrafficUpdates: SettingsService.defaultTrafficUpdates,
        distanceUnit: SettingsService.defaultDistanceUnit,
        preferredTransport: SettingsService.defaultPreferredTransport,
        enableNotifications: SettingsService.defaultNotifications,
        enableLocationHistory: SettingsService.defaultLocationHistory,
        enableSoundEffects: SettingsService.defaultSoundEffects,
        isLoading: true,
      );

  SettingsState copyWith({
    bool? showTrafficUpdates,
    String? distanceUnit,
    String? preferredTransport,
    bool? enableNotifications,
    bool? enableLocationHistory,
    bool? enableSoundEffects,
    bool? isLoading,
  }) {
    return SettingsState(
      showTrafficUpdates: showTrafficUpdates ?? this.showTrafficUpdates,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      preferredTransport: preferredTransport ?? this.preferredTransport,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableLocationHistory: enableLocationHistory ?? this.enableLocationHistory,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object> get props => [
        showTrafficUpdates,
        distanceUnit,
        preferredTransport,
        enableNotifications,
        enableLocationHistory,
        enableSoundEffects,
        isLoading,
      ];
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsService _settingsService = SettingsService();

  SettingsBloc() : super(SettingsState.initial()) {
    on<SettingsLoaded>(_onSettingsLoaded);
    on<TrafficUpdatesChanged>(_onTrafficUpdatesChanged);
    on<DistanceUnitChanged>(_onDistanceUnitChanged);
    on<PreferredTransportChanged>(_onPreferredTransportChanged);
    on<NotificationsChanged>(_onNotificationsChanged);
    on<LocationHistoryChanged>(_onLocationHistoryChanged);
    on<SoundEffectsChanged>(_onSoundEffectsChanged);
  }

  Future<void> _onSettingsLoaded(SettingsLoaded event, Emitter<SettingsState> emit) async {
    final trafficUpdates = await _settingsService.loadTrafficUpdates();
    final distanceUnit = await _settingsService.loadDistanceUnit();
    final preferredTransport = await _settingsService.loadPreferredTransport();
    final enableNotifications = await _settingsService.loadNotifications();
    final enableLocationHistory = await _settingsService.loadLocationHistory();
    final enableSoundEffects = await _settingsService.loadSoundEffects();

    emit(state.copyWith(
      showTrafficUpdates: trafficUpdates,
      distanceUnit: distanceUnit,
      preferredTransport: preferredTransport,
      enableNotifications: enableNotifications,
      enableLocationHistory: enableLocationHistory,
      enableSoundEffects: enableSoundEffects,
      isLoading: false,
    ));
  }

  Future<void> _onTrafficUpdatesChanged(TrafficUpdatesChanged event, Emitter<SettingsState> emit) async {
    await _settingsService.saveTrafficUpdates(event.showTrafficUpdates);
    emit(state.copyWith(showTrafficUpdates: event.showTrafficUpdates));
  }

  Future<void> _onDistanceUnitChanged(DistanceUnitChanged event, Emitter<SettingsState> emit) async {
    await _settingsService.saveDistanceUnit(event.distanceUnit);
    emit(state.copyWith(distanceUnit: event.distanceUnit));
  }

  Future<void> _onPreferredTransportChanged(PreferredTransportChanged event, Emitter<SettingsState> emit) async {
    await _settingsService.savePreferredTransport(event.preferredTransport);
    emit(state.copyWith(preferredTransport: event.preferredTransport));
  }

  Future<void> _onNotificationsChanged(NotificationsChanged event, Emitter<SettingsState> emit) async {
    await _settingsService.saveNotifications(event.enableNotifications);
    emit(state.copyWith(enableNotifications: event.enableNotifications));
  }

  Future<void> _onLocationHistoryChanged(LocationHistoryChanged event, Emitter<SettingsState> emit) async {
    await _settingsService.saveLocationHistory(event.enableLocationHistory);
    emit(state.copyWith(enableLocationHistory: event.enableLocationHistory));
  }

  Future<void> _onSoundEffectsChanged(SoundEffectsChanged event, Emitter<SettingsState> emit) async {
    await _settingsService.saveSoundEffects(event.enableSoundEffects);
    emit(state.copyWith(enableSoundEffects: event.enableSoundEffects));
  }
}