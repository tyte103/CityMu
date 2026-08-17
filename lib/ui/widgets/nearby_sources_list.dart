import 'package:flutter/material.dart';
import '../../core/constants/gis_constants.dart';
import '../../core/enums/feature_type.dart';
import '../../core/theme/app_theme.dart';
import '../../models/spatial_feature.dart';

/// Clean minimalist component that lists all nearby spatial sound sources.
class NearbySourcesList extends StatelessWidget {
  const NearbySourcesList({
    super.key,
    required this.features,
    this.onFeatureTap,
  });

  final List<SpatialFeature> features;
  final ValueChanged<SpatialFeature>? onFeatureTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.cardBorderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🔊 附近聲源',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${features.length} 處可感應聲景',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (features.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorderLight),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.spatial_audio_off_rounded, size: 28, color: AppTheme.textTertiary),
                    SizedBox(height: 8),
                    Text(
                      '周圍 500m 內暫無特定聲景地標',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '正在播放台北城市通用漫步 Lo-Fi 律動',
                      style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: features.length,
                separatorBuilder: (_, __) => const Divider(color: AppTheme.cardBorderLight, height: 12),
                itemBuilder: (context, index) {
                  final feature = features[index];
                  final acousticRadius = _getAcousticRadius(feature.type);
                  final isInRange = feature.distanceMeters <= acousticRadius;
                  final soundDesc = _getSoundDescription(feature.type);

                  return InkWell(
                    onTap: () => onFeatureTap?.call(feature),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Row(
                        children: [
                          // Category Icon Avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(feature.type).withValues(alpha: isInRange ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getCategoryColor(feature.type).withValues(alpha: isInRange ? 0.4 : 0.15),
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(feature.type),
                              size: 18,
                              color: _getCategoryColor(feature.type),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Name & Sound Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        feature.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isInRange ? FontWeight.bold : FontWeight.w500,
                                          color: isInRange ? AppTheme.textPrimary : AppTheme.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  soundDesc,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isInRange ? AppTheme.textSecondary : AppTheme.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Distance & Range Status Badge
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isInRange
                                      ? AppTheme.activeGreen.withValues(alpha: 0.12)
                                      : AppTheme.chipBackground,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isInRange
                                        ? AppTheme.activeGreen.withValues(alpha: 0.4)
                                        : AppTheme.cardBorderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isInRange) ...[
                                      const Icon(Icons.volume_up_rounded, size: 10, color: AppTheme.activeGreen),
                                      const SizedBox(width: 3),
                                    ],
                                    Text(
                                      isInRange ? '作用中' : '半徑外',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isInRange ? AppTheme.activeGreen : AppTheme.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${feature.distanceMeters.toStringAsFixed(0)}m',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: isInRange ? AppTheme.primaryBlue : AppTheme.textTertiary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  double _getAcousticRadius(FeatureType type) {
    switch (type) {
      case FeatureType.mrt:
        return GisConstants.mrtSubBassRadius;
      case FeatureType.park:
        return GisConstants.parkAcousticRadius;
      case FeatureType.temple:
        return GisConstants.templeAcousticRadius;
      case FeatureType.market:
        return GisConstants.marketAcousticRadius;
      case FeatureType.campus:
        return GisConstants.campusAcousticRadius;
      case FeatureType.culture:
        return GisConstants.cultureAcousticRadius;
      case FeatureType.water:
        return GisConstants.waterTextureRadius;
      case FeatureType.power:
        return GisConstants.powerGridRadius;
    }
  }

  Color _getCategoryColor(FeatureType type) {
    switch (type) {
      case FeatureType.mrt:
        return AppTheme.mrtZoneBlue;
      case FeatureType.park:
        return AppTheme.parkZoneGreen;
      case FeatureType.temple:
        return Colors.deepOrange;
      case FeatureType.market:
        return Colors.amber.shade800;
      case FeatureType.campus:
        return Colors.indigo;
      case FeatureType.culture:
        return Colors.purple;
      case FeatureType.water:
        return AppTheme.waterZoneCyan;
      case FeatureType.power:
        return Colors.teal;
    }
  }

  IconData _getCategoryIcon(FeatureType type) {
    switch (type) {
      case FeatureType.mrt:
        return Icons.subway_rounded;
      case FeatureType.park:
        return Icons.park_rounded;
      case FeatureType.temple:
        return Icons.temple_buddhist_rounded;
      case FeatureType.market:
        return Icons.restaurant_rounded;
      case FeatureType.campus:
        return Icons.school_rounded;
      case FeatureType.culture:
        return Icons.palette_rounded;
      case FeatureType.water:
        return Icons.water_drop_rounded;
      case FeatureType.power:
        return Icons.electric_bolt_rounded;
    }
  }

  String _getSoundDescription(FeatureType type) {
    switch (type) {
      case FeatureType.mrt:
        return '🚇 捷運進站 Jingle / 實錄變奏 / 閘門感應';
      case FeatureType.park:
        return '🍃 大安蟬鳴 / 樹蛙夜鳴 / 行人布穀鳥';
      case FeatureType.temple:
        return '🏮 龍山寺青銅梵鐘 (293Hz) / 誦經木魚';
      case FeatureType.market:
        return '🍜 夜市鐵板熱炒滋滋聲 / 傳統打彈珠';
      case FeatureType.campus:
        return '🏫 台大傅鐘 21 響 [Ab4-C5-Bb4-Eb4]';
      case FeatureType.culture:
        return '🎨 松菸華山文創黑膠底噪與咖啡蒸氣';
      case FeatureType.water:
        return '🌊 淡水河/基隆河水岸流水琶音';
      case FeatureType.power:
        return '⚡ 科技能量電音 / YouBike 雙音車鈴 / 超商門鈴';
    }
  }
}
