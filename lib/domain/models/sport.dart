/// Supported sport types
enum SportType {
  football, // サッカー
  baseball, // 野球
  basketball, // バスケットボール
  americanFootball, // アメフト
  rugby, // ラグビー
}

extension SportTypeExtension on SportType {
  String get displayNameJa {
    switch (this) {
      case SportType.football:
        return 'サッカー';
      case SportType.baseball:
        return '野球';
      case SportType.basketball:
        return 'バスケットボール';
      case SportType.americanFootball:
        return 'アメリカンフットボール';
      case SportType.rugby:
        return 'ラグビー';
    }
  }

  String get displayNameEn {
    switch (this) {
      case SportType.football:
        return 'Football';
      case SportType.baseball:
        return 'Baseball';
      case SportType.basketball:
        return 'Basketball';
      case SportType.americanFootball:
        return 'American Football';
      case SportType.rugby:
        return 'Rugby';
    }
  }

  String get iconAsset {
    switch (this) {
      case SportType.football:
        return 'assets/icons/football.png';
      case SportType.baseball:
        return 'assets/icons/baseball.png';
      case SportType.basketball:
        return 'assets/icons/basketball.png';
      case SportType.americanFootball:
        return 'assets/icons/american_football.png';
      case SportType.rugby:
        return 'assets/icons/rugby.png';
    }
  }
}

/// A sports league (e.g. J1 League, NPB, NBA)
class League {
  const League({
    required this.id,
    required this.nameEn,
    required this.nameJa,
    required this.sportType,
    required this.country,
    this.logoUrl,
    this.rapidApiId,
  });

  final String id;
  final String nameEn;
  final String nameJa;
  final SportType sportType;
  final String country;
  final String? logoUrl;
  final int? rapidApiId; // RapidAPI league/competition ID

  factory League.fromFirestore(Map<String, dynamic> data, String docId) {
    return League(
      id: docId,
      nameEn: data['nameEn'] as String,
      nameJa: data['nameJa'] as String,
      sportType: SportType.values.firstWhere(
        (e) => e.name == data['sportType'],
        orElse: () => SportType.football,
      ),
      country: data['country'] as String,
      logoUrl: data['logoUrl'] as String?,
      rapidApiId: data['rapidApiId'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nameEn': nameEn,
      'nameJa': nameJa,
      'sportType': sportType.name,
      'country': country,
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (rapidApiId != null) 'rapidApiId': rapidApiId,
    };
  }
}
