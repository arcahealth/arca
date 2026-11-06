import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({required this.repository}) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileActiveSwitched>(_onActiveSwitched);
    on<ProfileAdded>(_onProfileAdded);
  }

  final ProfileRepository repository;

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());
    try {
      final profiles = await repository.getProfiles();
      final activeId = await repository.getActiveProfileId();
      final active = profiles.firstWhere(
        (p) => p.id == activeId,
        orElse: () => profiles.isNotEmpty
            ? profiles.first
            : Profile(
                id: 'self',
                name: 'Me (Primary)',
                relationship: ProfileRelationship.self,
                createdAt: DateTime.now(),
              ),
      );
      emit(ProfileLoaded(profiles: profiles, activeProfile: active));
    } catch (e) {
      emit(ProfileFailure('Failed to load family member profiles: $e'));
    }
  }

  Future<void> _onActiveSwitched(
    ProfileActiveSwitched event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    try {
      await repository.setActiveProfileId(event.profileId);
      final active = current.profiles.firstWhere(
        (p) => p.id == event.profileId,
        orElse: () => current.activeProfile,
      );
      emit(ProfileLoaded(profiles: current.profiles, activeProfile: active));
    } catch (e) {
      emit(ProfileFailure('Failed to switch active profile: $e'));
    }
  }

  Future<void> _onProfileAdded(
    ProfileAdded event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await repository.addProfile(event.profile);
      await repository.setActiveProfileId(event.profile.id);
      final profiles = await repository.getProfiles();
      emit(ProfileLoaded(profiles: profiles, activeProfile: event.profile));
    } catch (e) {
      emit(ProfileFailure('Failed to add family member profile: $e'));
    }
  }
}
