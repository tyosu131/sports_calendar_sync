import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
import 'package:sports_calendar_sync/domain/models/firestore_decode.dart';
import 'package:sports_calendar_sync/domain/models/user_profile.dart';

void main() {
  group('UserProfile canonical follow state', () {
    test('flat state wins over the per-competition compatibility map', () {
      const profile = UserProfile(
        uid: 'user',
        email: 'user@example.com',
        followedTeamIds: ['arsenal'],
        favoriteTeamIdsByCompetition: {
          'football_premier': ['another_team'],
        },
      );

      expect(profile.followedTeamIds, ['arsenal']);
      expect(profile.allFavoriteTeamIds, ['arsenal']);
      expect(profile.toFirestore()['followedTeamIds'], ['arsenal']);
    });

    test('reads a legacy flat-only document', () {
      final profile = UserProfile.fromFirestore({
        'email': 'user@example.com',
        'followedTeamIds': ['arsenal'],
      }, 'user');

      expect(profile.followedTeamIds, ['arsenal']);
      expect(profile.allFavoriteTeamIds, ['arsenal']);
      expect(profile.favoriteTeamIdsByCompetition, isEmpty);
      expect(profile.selectedCompetitions, isEmpty);
      expect(profile.preferredLanguage, 'ja');
    });

    test('a present preferredLanguage of the wrong type fails closed', () {
      expect(
        () => UserProfile.fromFirestore({
          'email': 'user@example.com',
          'followedTeamIds': ['arsenal'],
          'preferredLanguage': 1,
        }, 'user'),
        throwsA(
          isA<FirestoreDecodeException>()
              .having((error) => error.field, 'field', 'preferredLanguage')
              .having((error) => error.documentId, 'documentId', 'user')
              .having(
                (error) => error.toString(),
                'toString',
                contains('users/user'),
              ),
        ),
      );
    });
  });

  group('follow update repairs only missing rule keys', () {
    test('does not overwrite language or email that are already stored', () {
      final updates = followFieldUpdates(
        existing: const {
          'email': 'user@example.com',
          'preferredLanguage': 'en',
          'followedTeamIds': <String>[],
        },
        teamId: 'arsenal',
        follow: true,
        authEmail: 'other@example.com',
      );

      expect(updates.keys, ['followedTeamIds']);
      expect(updates['followedTeamIds'], isA<FieldValue>());
    });

    test('adds ja and the auth email only when those keys are absent', () {
      final updates = followFieldUpdates(
        existing: const {
          'followedTeamIds': <String>['arsenal'],
        },
        teamId: 'arsenal',
        follow: false,
        authEmail: ' user@example.com ',
      );

      expect(updates['preferredLanguage'], 'ja');
      expect(updates['email'], 'user@example.com');
      expect(updates['followedTeamIds'], isA<FieldValue>());
    });

    test('does not invent an email when Auth has none', () {
      final updates = followFieldUpdates(
        existing: const {'preferredLanguage': 'ja'},
        teamId: 'arsenal',
        follow: true,
        authEmail: ' ',
      );

      expect(updates.keys, ['followedTeamIds']);
    });
  });

  group('SampleUserRepository global follow operations', () {
    test(
      'duplicate follows from different contexts store one stable ID',
      () async {
        final repository = SampleUserRepository();

        await repository.followTeam(
          SampleUserRepository.sampleUid,
          'arsenal',
          competitionKey: 'football_premier',
        );
        await repository.followTeam(
          SampleUserRepository.sampleUid,
          'arsenal',
          competitionKey: 'football_champions_league',
        );

        final profile = await repository.fetchProfile(
          SampleUserRepository.sampleUid,
        );
        expect(
          profile!.followedTeamIds.where((id) => id == 'arsenal'),
          hasLength(1),
        );
        expect(profile.favoriteTeamIdsByCompetition, {
          'football_j1': ['kashima_antlers', 'gamba_osaka'],
        });
        expect(profile.selectedCompetitions, ['football_j1']);
      },
    );

    test(
      'unfollow removes globally regardless of competition context',
      () async {
        final repository = SampleUserRepository();
        await repository.followTeam(SampleUserRepository.sampleUid, 'arsenal');
        await repository.unfollowTeam(
          SampleUserRepository.sampleUid,
          'arsenal',
          competitionKey: 'unrelated_competition',
        );

        final profile = await repository.fetchProfile(
          SampleUserRepository.sampleUid,
        );
        expect(profile!.followedTeamIds, ['kashima_antlers', 'gamba_osaka']);
      },
    );
  });
}
