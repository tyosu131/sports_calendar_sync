import 'package:flutter_test/flutter_test.dart';
import 'package:sports_calendar_sync/data/repositories/user_repository.dart';
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
        expect(profile!.followedTeamIds, [
          'kashima_antlers',
          'gamba_osaka',
        ]);
      },
    );
  });
}
