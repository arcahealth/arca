import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arca/features/profiles/data/repositories/in_memory_profile_repository.dart';
import 'package:arca/features/profiles/domain/models/profile.dart';
import 'package:arca/features/profiles/presentation/bloc/profile_bloc.dart';
import 'package:arca/features/profiles/presentation/bloc/profile_event.dart';
import 'package:arca/features/profiles/presentation/bloc/profile_state.dart';

void main() {
  group('ProfileBloc Tests', () {
    late InMemoryProfileRepository repository;

    setUp(() {
      repository = InMemoryProfileRepository();
    });

    test('initial state is ProfileInitial', () {
      final bloc = ProfileBloc(repository: repository);
      expect(bloc.state, isA<ProfileInitial>());
      bloc.close();
    });

    blocTest<ProfileBloc, ProfileState>(
      'loads family member profiles and defaults to active profile',
      build: () => ProfileBloc(repository: repository),
      act: (bloc) => bloc.add(const ProfileLoadRequested()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having(
          (s) => s.activeProfile.id,
          'activeProfile.id',
          'self',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'switches active profile successfully',
      build: () => ProfileBloc(repository: repository),
      seed: () {
        final profiles = [
          Profile(
            id: 'self',
            name: 'Me',
            relationship: ProfileRelationship.self,
            createdAt: DateTime(2026, 1, 1),
          ),
          Profile(
            id: 'child_1',
            name: 'Leo',
            relationship: ProfileRelationship.child,
            createdAt: DateTime(2026, 2, 1),
          ),
        ];
        return ProfileLoaded(profiles: profiles, activeProfile: profiles.first);
      },
      act: (bloc) => bloc.add(const ProfileActiveSwitched('child_1')),
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.activeProfile.id,
          'activeProfile.id',
          'child_1',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'adds a new profile and sets it as active',
      build: () => ProfileBloc(repository: repository),
      act: (bloc) {
        final newProfile = Profile(
          id: 'parent_1',
          name: 'Eleanor',
          relationship: ProfileRelationship.parent,
          createdAt: DateTime(2026, 3, 1),
        );
        bloc.add(ProfileAdded(newProfile));
      },
      expect: () => [
        isA<ProfileLoaded>().having(
          (s) => s.activeProfile.name,
          'activeProfile.name',
          'Eleanor',
        ),
      ],
    );
  });
}
