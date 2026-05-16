import 'package:flutter/widgets.dart';

enum RankArtSize { xs, sm, md, hero }

class RankArt extends StatelessWidget {
  final String rankName;
  final RankArtSize size;
  final double? dimension;
  final BoxFit fit;

  const RankArt({
    super.key,
    required this.rankName,
    this.size = RankArtSize.sm,
    this.dimension,
    this.fit = BoxFit.cover,
  });

  static String canonicalKey(String rankName) {
    final normalized = rankName.trim().toLowerCase();
    switch (normalized) {
      case 'asleep':
      case 'starter':
      case 'sleeping':
      case 'sleeping panda':
      case 'panda':
        return 'sleeping';
      case 'bronze':
        return 'bronze';
      case 'silver':
        return 'silver';
      case 'gold':
        return 'gold';
      case 'platinum':
      case 'platine':
        return 'platinum';
      case 'diamond':
      case 'dimaond':
        return 'diamond';
      case 'batman':
      case 'immortal':
        return 'immortal';
      case 'ceo':
      case 'awakened':
        return 'awakened';
      default:
        return 'sleeping';
    }
  }

  static String displayName(String rankName) {
    final normalized = rankName.trim().toLowerCase();
    switch (normalized) {
      case 'asleep':
      case 'starter':
      case 'sleeping':
      case 'sleeping panda':
      case 'panda':
        return 'Asleep';
      case 'ceo':
      case 'awakened':
        return 'Awakened';
      case 'batman':
      case 'immortal':
        return 'Immortal';
      default:
        if (rankName.trim().isEmpty) return 'Asleep';
        final lower = rankName.trim().toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
    }
  }

  static String assetPathFor(String rankName, RankArtSize size) {
    final key = canonicalKey(rankName);
    final filename = switch (size) {
      RankArtSize.xs => 'xs',
      RankArtSize.sm => 'sm',
      RankArtSize.md => 'md',
      RankArtSize.hero => 'hero',
    };
    return 'assets/ranks/$key/$filename.png';
  }

  static double defaultDimension(RankArtSize size) {
    switch (size) {
      case RankArtSize.xs:
        return 32;
      case RankArtSize.sm:
        return 64;
      case RankArtSize.md:
        return 128;
      case RankArtSize.hero:
        return 512;
    }
  }

  static double visualScale(String rankName) {
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final boxSize = dimension ?? defaultDimension(size);
    final scaledSize = boxSize * visualScale(rankName);
    return SizedBox.square(
      dimension: boxSize,
      child: ClipRect(
        child: Center(
          child: Image.asset(
            assetPathFor(rankName, size),
            width: scaledSize,
            height: scaledSize,
            fit: fit,
            isAntiAlias: true,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
