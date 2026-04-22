import 'sport.dart';

/// A sports team
class Team {
  const Team({
    required this.id,
    required this.nameEn,
    required this.nameJa,
    required this.leagueId,
    required this.sportType,
    this.logoUrl,
    this.country,
    this.rapidApiId,
  });

  final String id;
  final String nameEn;
  final String nameJa;
  final String leagueId;
  final SportType sportType;
  final String? logoUrl;
  final String? country;
  final int? rapidApiId; // RapidAPI team ID

  factory Team.fromFirestore(Map<String, dynamic> data, String docId) {
    return Team(
      id: docId,
      nameEn: data['nameEn'] as String,
      nameJa: data['nameJa'] as String,
      leagueId: data['leagueId'] as String,
      sportType: SportType.values.firstWhere(
        (e) => e.name == data['sportType'],
        orElse: () => SportType.football,
      ),
      logoUrl: data['logoUrl'] as String?,
      country: data['country'] as String?,
      rapidApiId: data['rapidApiId'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameEn': nameEn,
      'nameJa': nameJa,
      'leagueId': leagueId,
      'sportType': sportType.name,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (country != null) 'country': country,
      if (rapidApiId != null) 'rapidApiId': rapidApiId,
    };
  }

  Team copyWith({
    String? id,
    String? nameEn,
    String? nameJa,
    String? leagueId,
    SportType? sportType,
    String? logoUrl,
    String? country,
    int? rapidApiId,
  }) {
    return Team(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameJa: nameJa ?? this.nameJa,
      leagueId: leagueId ?? this.leagueId,
      sportType: sportType ?? this.sportType,
      logoUrl: logoUrl ?? this.logoUrl,
      country: country ?? this.country,
      rapidApiId: rapidApiId ?? this.rapidApiId,
    );
  }
}
