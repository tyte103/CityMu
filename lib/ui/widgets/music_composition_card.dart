import 'package:flutter/material.dart';
import '../../controllers/music_orchestrator.dart';
import '../../core/theme/app_theme.dart';
import '../../models/audio_parameter.dart';

/// Minimalist UI Widget displaying the real-time breakdown of all
/// Gemini AI composed musical elements, 4-bar dynamic grooves, recurring motifs, and integrated Taiwanese soundscapes.
class MusicCompositionCard extends StatelessWidget {
  const MusicCompositionCard({
    super.key,
    required this.audioParameter,
  });

  final AudioParameter audioParameter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = audioParameter.isPlaying;
    final orchestrator = MusicOrchestrator.instance;
    final comp = orchestrator.currentComposition;
    final isComposing = orchestrator.isComposingAi;

    return Card(
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.cardBorderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with AI Spatial Theme Title & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primaryBlue,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Gemini 空間專屬作曲',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          comp.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComposing
                        ? AppTheme.techZoneAmber.withValues(alpha: 0.15)
                        : (isPlaying ? AppTheme.activeGreen.withValues(alpha: 0.12) : AppTheme.chipBackground),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isComposing
                          ? AppTheme.techZoneAmber
                          : (isPlaying ? AppTheme.activeGreen.withValues(alpha: 0.3) : AppTheme.cardBorderLight),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComposing)
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.techZoneAmber),
                        )
                      else
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPlaying ? AppTheme.activeGreen : AppTheme.textTertiary,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        isComposing ? 'AI 譜曲中' : (isPlaying ? '演奏中' : '待機'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isComposing
                              ? AppTheme.techZoneAmber
                              : (isPlaying ? AppTheme.activeGreen : AppTheme.textSecondary),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 2. Poetic Atmosphere Story Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.chipBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.music_note_rounded, size: 14, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        comp.scaleName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comp.poeticStory,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Track Mute / Solo Toggles
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '音軌個別靜音控制 (Track Mixer)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTrackMuteBtn(
                    context,
                    label: '🎹 Pad 和弦',
                    isMuted: orchestrator.isPadMuted,
                    onTap: () => orchestrator.toggleTrackMute('pad'),
                    accentColor: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTrackMuteBtn(
                    context,
                    label: '🎵 AI 旋律',
                    isMuted: orchestrator.isMelodyMuted,
                    onTap: () => orchestrator.toggleTrackMute('melody'),
                    accentColor: AppTheme.parkZoneGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTrackMuteBtn(
                    context,
                    label: '🥁 4小節鼓組',
                    isMuted: orchestrator.isDrumsMuted,
                    onTap: () => orchestrator.toggleTrackMute('drums'),
                    accentColor: AppTheme.techZoneAmber,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildTrackMuteBtn(
                    context,
                    label: '🚇 捷運聲景',
                    isMuted: orchestrator.isFoleyMuted,
                    onTap: () => orchestrator.toggleTrackMute('foley'),
                    accentColor: AppTheme.mrtZoneBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Current Sound Status Banner & Step Position
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.cardBorderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      size: 14,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPlaying ? audioParameter.activeSoundSource : '點擊播放以啟動 AI 專屬動機與空間音樂',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPlaying ? AppTheme.textPrimary : AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '第 ${audioParameter.barIndex + 1} 小節 · 第 ${audioParameter.stepIndex + 1}/16 拍 · 當前和弦: ${audioParameter.currentChordName}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Zone Chord Progression Cycle (4 Bars)
            Text(
              '${comp.title} · 4 小節專屬和弦進行',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(4, (i) {
                final chordName = i < comp.chordNames.length ? comp.chordNames[i] : 'Chord';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    child: _buildChordChip(context, chordName, i, AppTheme.primaryBlue),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // 6. Unified Spatial Soundscapes & Foley Tracks (4 平行聲景家族)
            Text(
              '空間環境聲景特徵 (Spatial Foley Soundscapes)',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.subway_rounded,
                  label: '🚇 捷運軌道',
                  sublabel: '進站/刷卡/關門音',
                  isUnlocked: orchestrator.isMrtInRange,
                  isSounding: isPlaying && audioParameter.activeSoundSource.contains('捷運'),
                  accentColor: AppTheme.mrtZoneBlue,
                ),
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.park_rounded,
                  label: '🌳 公園鳥鳴',
                  sublabel: '布穀鳥 E5→C5',
                  isUnlocked: orchestrator.isParkInRange,
                  isSounding: isPlaying && (audioParameter.activeSoundSource.contains('號誌') || audioParameter.activeSoundSource.contains('鳥鳴')),
                  accentColor: AppTheme.parkZoneGreen,
                ),
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.water_drop_rounded,
                  label: '🌊 水岸微風',
                  sublabel: '五音分解琶音',
                  isUnlocked: orchestrator.isWaterInRange,
                  isSounding: isPlaying && audioParameter.activeSoundSource.contains('水岸'),
                  accentColor: AppTheme.waterZoneCyan,
                ),
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.temple_buddhist_rounded,
                  label: '🏮 廟宇鐘磬',
                  sublabel: '古廟大銅鐘 293Hz',
                  isUnlocked: orchestrator.isTempleInRange,
                  isSounding: isPlaying && audioParameter.activeSoundSource.contains('銅鐘'),
                  accentColor: const Color(0xFFEF5350),
                ),
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.fastfood_rounded,
                  label: '🍜 夜市沙鈴',
                  sublabel: '快節奏小吃律動',
                  isUnlocked: orchestrator.isMarketInRange,
                  isSounding: isPlaying && audioParameter.activeSoundSource.contains('夜市'),
                  accentColor: const Color(0xFFFFA726),
                ),
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.school_rounded,
                  label: '🏫 校園傅鐘',
                  sublabel: '西敏寺四音序列',
                  isUnlocked: orchestrator.isCampusInRange,
                  isSounding: isPlaying && audioParameter.activeSoundSource.contains('傅鐘'),
                  accentColor: const Color(0xFF42A5F5),
                ),
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.palette_rounded,
                  label: '🎨 文創藝術',
                  sublabel: '大提琴暖調長音',
                  isUnlocked: orchestrator.isCultureInRange,
                  isSounding: isPlaying && audioParameter.activeSoundSource.contains('文創'),
                  accentColor: const Color(0xFFAB47BC),
                ),
                _buildSpatialStemBadge(
                  context,
                  icon: Icons.pedal_bike_rounded,
                  label: '🚲 YouBike 車鈴',
                  sublabel: '雙音金屬鈴',
                  isUnlocked: orchestrator.isYouBikeInRange,
                  isSounding: isPlaying && audioParameter.activeSoundSource.contains('YouBike'),
                  accentColor: AppTheme.techZoneAmber,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7. 4-Bar Dynamic Drum Groove System (告別單調重複)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '4 小節動態呼吸鼓組 (Dynamic Lo-Fi Beats)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.chipBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getBarGrooveDescription(audioParameter.barIndex),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDrumIndicator(
                    context,
                    label: '大鼓 Kick',
                    subtext: '底層律動',
                    isActive: isPlaying && audioParameter.isKickActive,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDrumIndicator(
                    context,
                    label: '小鼓 Snare',
                    subtext: '幽靈音/切分',
                    isActive: isPlaying && audioParameter.isSnareActive,
                    color: AppTheme.mrtZoneBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDrumIndicator(
                    context,
                    label: '鈸 Hi-Hat',
                    subtext: '搖擺碎拍',
                    isActive: isPlaying && audioParameter.isHiHatActive,
                    color: AppTheme.techZoneAmber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getBarGrooveDescription(int bar) {
    switch (bar % 4) {
      case 0:
        return 'Bar 1: 基礎鋪墊';
      case 1:
        return 'Bar 2: 切分幽靈音';
      case 2:
        return 'Bar 3: 雙大鼓推進';
      case 3:
        return 'Bar 4: 留白過門 Drop';
      default:
        return '';
    }
  }

  Widget _buildTrackMuteBtn(
    BuildContext context, {
    required String label,
    required bool isMuted,
    required VoidCallback onTap,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isMuted ? AppTheme.chipBackground : accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMuted ? AppTheme.cardBorderLight : accentColor.withValues(alpha: 0.4),
            width: isMuted ? 1.0 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isMuted ? FontWeight.normal : FontWeight.bold,
                color: isMuted ? AppTheme.textTertiary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isMuted ? '靜音' : '發聲中',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: isMuted ? AppTheme.textTertiary : accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChordChip(BuildContext context, String chord, int index, Color accentColor) {
    final isCurrent = audioParameter.isPlaying && audioParameter.barIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? accentColor : AppTheme.chipBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrent ? accentColor : AppTheme.cardBorderLight,
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          chord,
          style: TextStyle(
            fontSize: 12,
            color: isCurrent ? Colors.white : AppTheme.textPrimary,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSpatialStemBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required bool isUnlocked,
    required bool isSounding,
    required Color accentColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: !isUnlocked
            ? AppTheme.chipBackground.withValues(alpha: 0.5)
            : isSounding
                ? accentColor.withValues(alpha: 0.15)
                : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: !isUnlocked
              ? AppTheme.cardBorderLight
              : isSounding
                  ? accentColor
                  : AppTheme.cardBorderLight,
          width: isSounding ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUnlocked ? icon : Icons.lock_outline_rounded,
            size: 14,
            color: !isUnlocked
                ? AppTheme.textTertiary
                : isSounding
                    ? accentColor
                    : AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSounding ? FontWeight.bold : FontWeight.w500,
                      color: !isUnlocked ? AppTheme.textTertiary : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? (isSounding ? accentColor : AppTheme.chipBackground)
                          : AppTheme.chipBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isUnlocked ? (isSounding ? '發聲中' : '就緒') : '距離未達',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? (isSounding ? Colors.white : AppTheme.textSecondary)
                            : AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrumIndicator(
    BuildContext context, {
    required String label,
    required String subtext,
    required bool isActive,
    required Color color,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.12) : AppTheme.chipBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? color : AppTheme.cardBorderLight,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? color : AppTheme.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? color : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
