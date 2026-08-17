import 'package:flutter/material.dart';
import '../../controllers/music_orchestrator.dart';
import '../../core/constants/gis_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/taiwan_spatial_landmarks_data.dart';
import '../../models/ai_composition.dart';
import '../../models/spatial_landmark_preset.dart';
import '../../services/gemini_service.dart';
import '../../services/location_service.dart';
import '../../services/sensor_service.dart';
import '../widgets/audio_visualizer.dart';
import '../widgets/minimal_map_view.dart';
import '../widgets/nearby_sources_list.dart';

/// Main Dashboard Screen for CityMu featuring a Clean Minimalist interface.
/// Core focus: 1) Interactive Map, 2) Nearby Sound Sources List, 3) Gemini AI Composer.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MusicOrchestrator _orchestrator = MusicOrchestrator.instance;
  bool _showSimulatorPanel = false;

  // Simulator controls state
  double _simulatedSpeed = 0.0;
  double _simulatedLon = GisConstants.defaultLongitude;
  double _simulatedLat = GisConstants.defaultLatitude;
  late TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: GeminiService.instance.currentApiKey ?? GeminiService.defaultKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _teleportTo(double lon, double lat) {
    setState(() {
      _simulatedLon = lon;
      _simulatedLat = lat;
    });
    LocationService.instance.setMockLocation(lon, lat);
    _orchestrator.onManualLocationChange(lon, lat);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _orchestrator,
      builder: (context, child) {
        final state = _orchestrator.state;
        final comp = _orchestrator.currentComposition;
        final features = _orchestrator.nearbyFeatures;
        final loc = LocationService.instance.currentLocation;

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Minimal Clean Top Bar
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'CityMu',
                                  style: theme.textTheme.displayLarge?.copyWith(fontSize: 26),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    comp.title.split(' [').first,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '台灣城市空間聲景 · 即時生成式 Lo-Fi',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _showSimulatorPanel = !_showSimulatorPanel;
                                });
                              },
                              icon: Icon(
                                _showSimulatorPanel ? Icons.tune_rounded : Icons.tune_outlined,
                                color: _showSimulatorPanel ? AppTheme.primaryBlue : AppTheme.textSecondary,
                                size: 22,
                              ),
                              tooltip: '模擬器與 DSP 調音監聽器',
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _orchestrator.togglePlay(),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: state.isPlaying ? AppTheme.primaryBlue : AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: state.isPlaying ? AppTheme.primaryBlue : AppTheme.cardBorderLight,
                                  ),
                                  boxShadow: state.isPlaying
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: state.isPlaying ? Colors.white : AppTheme.textPrimary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      state.isPlaying ? '暫停' : '播放',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: state.isPlaying ? Colors.white : AppTheme.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Simulator Panel (Collapsible - 可選展開的座標傳送與 DSP 監聽器)
                if (_showSimulatorPanel)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    sliver: SliverToBoxAdapter(
                      child: _buildSimulatorCard(theme),
                    ),
                  ),

                // 🌟 核心區塊 1：空間地圖 (Minimalist Spatial Map)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  sliver: SliverToBoxAdapter(
                    child: MinimalMapView(
                      latitude: loc.$2,
                      longitude: loc.$1,
                      nearbyFeatures: features,
                      height: 240,
                    ),
                  ),
                ),

                // 🌟 核心區塊 2：附近聲源列表 (Nearby Sound Sources)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  sliver: SliverToBoxAdapter(
                    child: NearbySourcesList(
                      features: features,
                      onFeatureTap: (feature) {
                        // Optional tap action to show feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已鎖定聲源：${feature.name} (距離 ${feature.distanceMeters.toStringAsFixed(0)}m)'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 🌟 核心區塊 3：Gemini AI 作曲與即時對話 (Gemini Spatial Composition & Chat)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  sliver: SliverToBoxAdapter(
                    child: _buildGeminiCompositionCard(theme, comp, loc),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the clean Gemini AI Composition & Interactive Chat Card
  Widget _buildGeminiCompositionCard(ThemeData theme, AiComposition comp, (double, double) loc) {
    return Card(
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.cardBorderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text('Gemini 空間作曲', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        comp.scaleName,
                        style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _orchestrator.refreshAiMood(),
                      icon: const Icon(Icons.refresh_rounded, size: 18, color: AppTheme.textSecondary),
                      tooltip: '重新由 AI 譜寫新樂章',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              comp.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryBlue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Poetic Story
            Text(
              comp.poeticStory,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 12),

            // Quick Style Prompts & Chat Launcher
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.nightlife_rounded, size: 14, color: Colors.indigo),
                    label: const Text('🎷 深夜爵士', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.chipBackground,
                    side: const BorderSide(color: AppTheme.cardBorderLight),
                    onPressed: () async {
                      final res = await _orchestrator.chatWithAiComposer('換成深夜爵士風格，加入柔和薩克斯風與延伸七和弦');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🎷 已套用 AI 作曲：${res.newComposition?.title ?? "微醺爵士 Neo-Soul"}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.orange),
                    label: const Text('⚡ 輕快 City Pop', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.chipBackground,
                    side: const BorderSide(color: AppTheme.cardBorderLight),
                    onPressed: () async {
                      final res = await _orchestrator.chatWithAiComposer('切換為80年代 City Pop 復古輕快節奏');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚡ 已套用 AI 作曲：${res.newComposition?.title ?? "復古 City Pop"}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.temple_buddhist_rounded, size: 14, color: Colors.deepOrange),
                    label: const Text('🏮 禪意古風', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.chipBackground,
                    side: const BorderSide(color: AppTheme.cardBorderLight),
                    onPressed: () async {
                      final res = await _orchestrator.chatWithAiComposer('融入廟宇古風與東方五聲音階');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🏮 已套用 AI 作曲：${res.newComposition?.title ?? "古剎禪意東方調"}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 6),
                  ActionChip(
                    avatar: const Icon(Icons.water_drop_rounded, size: 14, color: Colors.cyan),
                    label: const Text('🌧️ 雨天 Lo-Fi', style: TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.chipBackground,
                    side: const BorderSide(color: AppTheme.cardBorderLight),
                    onPressed: () async {
                      final res = await _orchestrator.chatWithAiComposer('營造台北細雨濛濛的慢板抒情氛圍');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🌧️ 已套用 AI 作曲：${res.newComposition?.title ?? "深夜細雨 Lo-Fi"}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Direct Interactive Chat Launcher Button
            InkWell(
              onTap: _showAiComposerChatModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      '💬 與 Gemini AI 作曲家自由對話...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String title,
    required String value,
    required String caption,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return Card(
      color: AppTheme.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.cardBorderLight, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 13, color: accentColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              caption,
              style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulatorCard(ThemeData theme) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16, color: AppTheme.primaryBlue),
                    const SizedBox(width: 8),
                    Text('虛擬城市與定位控制區 (唯一的測試控制點)', style: theme.textTheme.titleMedium),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Landmark Quick Categories & 102 Landmark Modal Launcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('雙北 102 處空間聲景地標：', style: theme.textTheme.labelSmall),
                TextButton.icon(
                  onPressed: _showLandmarksModal,
                  icon: const Icon(Icons.explore_rounded, size: 16, color: AppTheme.primaryBlue),
                  label: const Text('開啟 102 處地標清單 (含搜尋)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.subway_rounded, size: 14, color: AppTheme.mrtZoneBlue),
                  label: const Text('🚇 台北車站'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.5170, 25.0478),
                ),
                ActionChip(
                  avatar: const Icon(Icons.nature_people_rounded, size: 14, color: AppTheme.parkZoneGreen),
                  label: const Text('🌳 大安森林公園'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.5350, 25.0330),
                ),
                ActionChip(
                  avatar: const Icon(Icons.water_drop_rounded, size: 14, color: AppTheme.waterZoneCyan),
                  label: const Text('🌊 淡水渡船頭'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.4390, 25.1700),
                ),
                ActionChip(
                  avatar: const Icon(Icons.temple_buddhist_rounded, size: 14, color: Color(0xFFEF5350)),
                  label: const Text('🏮 艋舺龍山寺'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.4998, 25.0368),
                ),
                ActionChip(
                  avatar: const Icon(Icons.fastfood_rounded, size: 14, color: Color(0xFFFFA726)),
                  label: const Text('🍜 士林夜市'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.5240, 25.0880),
                ),
                ActionChip(
                  avatar: const Icon(Icons.school_rounded, size: 14, color: Color(0xFF42A5F5)),
                  label: const Text('🏫 台大傅鐘'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.5375, 25.0175),
                ),
                ActionChip(
                  avatar: const Icon(Icons.palette_rounded, size: 14, color: Color(0xFFAB47BC)),
                  label: const Text('🎨 華山文創'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.5295, 25.0440),
                ),
                ActionChip(
                  avatar: const Icon(Icons.electric_bolt_rounded, size: 14, color: AppTheme.techZoneAmber),
                  label: const Text('⚡ 光華數位'),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  onPressed: () => _teleportTo(121.5315, 25.0450),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Motion Intensity Slider
            Text('模擬步伐強度: ${_simulatedSpeed.toStringAsFixed(2)} m/s²', style: theme.textTheme.labelSmall),
            Slider(
              value: _simulatedSpeed,
              min: 0.0,
              max: 4.0,
              divisions: 20,
              activeColor: AppTheme.primaryBlue,
              onChanged: (val) {
                setState(() => _simulatedSpeed = val);
                SensorService.instance.setMockIntensity(val);
              },
            ),
            const SizedBox(height: 6),

            // Longitude Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('經度 Longitude: ${_simulatedLon.toStringAsFixed(4)}', style: theme.textTheme.labelSmall),
                Text('(121.4000 ~ 121.6500 雙北全域)', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              ],
            ),
            Slider(
              value: _simulatedLon.clamp(121.4000, 121.6500),
              min: 121.4000,
              max: 121.6500,
              activeColor: AppTheme.primaryBlue,
              onChanged: (val) {
                setState(() => _simulatedLon = val);
                LocationService.instance.setMockLocation(val, _simulatedLat);
              },
              onChangeEnd: (val) {
                _orchestrator.onManualLocationChange(val, _simulatedLat);
              },
            ),
            const SizedBox(height: 6),

            // Latitude Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('緯度 Latitude: ${_simulatedLat.toStringAsFixed(4)}', style: theme.textTheme.labelSmall),
                Text('(24.9500 ~ 25.2000 雙北全域)', style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
              ],
            ),
            Slider(
              value: _simulatedLat.clamp(24.9500, 25.2000),
              min: 24.9500,
              max: 25.2000,
              activeColor: AppTheme.primaryBlue,
              onChanged: (val) {
                setState(() => _simulatedLat = val);
                LocationService.instance.setMockLocation(_simulatedLon, val);
              },
              onChangeEnd: (val) {
                _orchestrator.onManualLocationChange(_simulatedLon, val);
              },
            ),
            // 💬 AI Composer Live Chat Dialog Launcher
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.12),
                    Colors.purple.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.35),
                ),
              ),
              child: ListTile(
                dense: true,
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  radius: 16,
                  child: Icon(Icons.auto_awesome, size: 16, color: Colors.white),
                ),
                title: const Text(
                  '💬 與 Gemini AI 作曲家即時對話',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  '下達自訂風格指令、換調、分析現場音檔或生成專屬旋律',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                trailing: ElevatedButton.icon(
                  onPressed: _showAiComposerChatModal,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                  label: const Text('開啟對話', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 🎧 Live Sound FX & DSP Inspector Box (即時音效與 DSP 調音監聽欄位)
            _buildSoundFxLogInspector(theme),
            const SizedBox(height: 8),

            // Gemini API Key Input Field
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.chipBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.key_rounded, size: 14, color: AppTheme.primaryBlue),
                      SizedBox(width: 6),
                      Text(
                        'Google Gemini API Key 設定 (已配置)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: '輸入 Gemini API Key',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.cardBorderLight),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.activeGreen),
                        onPressed: () {
                          GeminiService.instance.setApiKey(_apiKeyController.text);
                          _orchestrator.onManualLocationChange(_simulatedLon, _simulatedLat);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gemini API Key 已儲存並立即啟動新作曲！')),
                          );
                        },
                      ),
                    ),
                    onSubmitted: (val) {
                      GeminiService.instance.setApiKey(val);
                      _orchestrator.onManualLocationChange(_simulatedLon, _simulatedLat);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the real-time Sound FX and DSP adjustment live log inspector.
  Widget _buildSoundFxLogInspector(ThemeData theme) {
    final logs = _orchestrator.fxLogs;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E242B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333D47)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _orchestrator.state.isPlaying ? const Color(0xFF00E676) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '🎧 即時音效與 DSP 調音 Log 監聽器',
                    style: TextStyle(
                      color: Color(0xFFECEFF1),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF37474F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${logs.length} 筆調音記錄',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB0BEC5)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _orchestrator.clearFxLogs(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_sweep_outlined, size: 16, color: Color(0xFF90A4AE)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quick Instant Audio Trigger Testing Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTestChip(
                  label: '🚇 C381 關門聲 (實錄變奏)',
                  onTap: () => _orchestrator.testTriggerRealMrt(
                    MusicOrchestrator.realMrtCollection.firstWhere((e) => e.key == 'c381_closing'),
                  ),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🏮 誦經木魚 (392Hz)',
                  onTap: () => _orchestrator.testTriggerTemple(true),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🏮 青銅梵鐘 (293Hz)',
                  onTap: () => _orchestrator.testTriggerTemple(false),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🍜 夜市鐵板熱炒',
                  onTap: () => _orchestrator.testTriggerNightMarket(false),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🍜 夜市打彈珠',
                  onTap: () => _orchestrator.testTriggerNightMarket(true),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🏪 超商叮咚門鈴',
                  onTap: () => _orchestrator.testTriggerConvenienceStore(),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🚛 垃圾車「少女的祈禱」',
                  onTap: () => _orchestrator.testTriggerGarbageTruck(),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🚌 公車上下車刷卡',
                  onTap: () => _orchestrator.testTriggerBusSwipe(),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🍃 陽明山盛夏蟬鳴',
                  onTap: () => _orchestrator.testTriggerNature(true),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🐸 象山原生樹蛙',
                  onTap: () => _orchestrator.testTriggerNature(false),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🏫 台大傅鐘 21 響',
                  onTap: () => _orchestrator.testTriggerCampusBell(),
                ),
                const SizedBox(width: 6),
                _buildTestChip(
                  label: '🎨 文創黑膠與咖啡',
                  onTap: () => _orchestrator.testTriggerCulture(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Log List Output Viewport
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF13171B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF263238)),
            ),
            child: logs.isEmpty
                ? const Center(
                    child: Text(
                      '🎵 點擊上方音效按鈕或開啟播放器，即時調音與發聲參數將同步輸出於此...',
                      style: TextStyle(fontSize: 11, color: Color(0xFF78909C)),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const Divider(color: Color(0xFF212B35), height: 8),
                    itemBuilder: (context, index) {
                      final item = logs[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.formattedTime,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF607D8B),
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF263238),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  item.category,
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF81D4FA), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.soundName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFECEFF1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (item.stepInfo != null)
                                Text(
                                  item.stepInfo!,
                                  style: const TextStyle(fontSize: 9, color: Color(0xFF78909C)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              '⚙️ ${item.dspDetails}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF80CBC4),
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF263238),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF37474F)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, size: 12, color: Color(0xFF00E676)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFFECEFF1), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiComposerChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _AiComposerChatSheet(
          orchestrator: _orchestrator,
        );
      },
    );
  }

  void _showLandmarksModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _LandmarksSelectionSheet(
          currentLon: _simulatedLon,
          currentLat: _simulatedLat,
          onSelect: (preset) {
            Navigator.pop(ctx);
            _teleportTo(preset.longitude, preset.latitude);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('已瞬移至 ${preset.icon} ${preset.name}，音景引擎與 AI 作曲已重組！'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}

class _LandmarksSelectionSheet extends StatefulWidget {
  const _LandmarksSelectionSheet({
    required this.currentLon,
    required this.currentLat,
    required this.onSelect,
  });

  final double currentLon;
  final double currentLat;
  final ValueChanged<SpatialLandmarkPreset> onSelect;

  @override
  State<_LandmarksSelectionSheet> createState() => _LandmarksSelectionSheetState();
}

class _LandmarksSelectionSheetState extends State<_LandmarksSelectionSheet> {
  String _searchQuery = '';
  String _selectedCategory = '全部 (102)';
  late TextEditingController _searchController;

  static const List<String> _categories = [
    '全部 (102)',
    '🚇 捷運軌道站體',
    '🌳 公園生態綠地',
    '🌊 水岸碼頭流水',
    '🏮 廟宇鐘磬香火',
    '🍜 夜市叫賣美食',
    '🏫 校園學術鐘聲',
    '🎨 文創藝術展演',
    '⚡ 科技聚落商圈',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = kTaipeiSpatialLandmarks.where((landmark) {
      final matchesCategory = _selectedCategory == '全部 (102)' || landmark.category == _selectedCategory;
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          landmark.name.toLowerCase().contains(q) ||
          landmark.category.toLowerCase().contains(q) ||
          landmark.description.toLowerCase().contains(q) ||
          landmark.soundSignature.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.cardBorderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('雙北 102 處空間聲景地標', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('點擊任何地標即可瞬移定位並觸發即時距離感應生成專屬音樂', style: theme.textTheme.labelSmall),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: '搜尋地標名稱、捷運站、廟宇、夜市、校園或音效動機...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primaryBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.chipBackground,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.cardBorderLight),
                ),
              ),
            ),
          ),

          // Category Chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  backgroundColor: AppTheme.chipBackground,
                  side: BorderSide(color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBorderLight),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat);
                  },
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppTheme.cardBorderLight),

          // Landmarks List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('找不到符合條件的地標，請嘗試其他關鍵字。', style: TextStyle(color: AppTheme.textTertiary)),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.cardBorderLight),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.chipBackground,
                          child: Text(item.icon, style: const TextStyle(fontSize: 18)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.chipBackground,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.cardBorderLight),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(item.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.music_note_rounded, size: 12, color: AppTheme.primaryBlue),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.soundSignature,
                                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  '(${item.longitude.toStringAsFixed(3)}, ${item.latitude.toStringAsFixed(3)})',
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: () => widget.onSelect(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final AiComposition? composition;
  final DateTime timestamp;

  _ChatMessage({
    required this.isUser,
    required this.text,
    this.composition,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class _AiComposerChatSheet extends StatefulWidget {
  const _AiComposerChatSheet({
    required this.orchestrator,
  });

  final MusicOrchestrator orchestrator;

  @override
  State<_AiComposerChatSheet> createState() => _AiComposerChatSheetState();
}

class _AiComposerChatSheetState extends State<_AiComposerChatSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _quickPrompts = [
    '🌙 轉為深夜細雨 Lo-Fi',
    '🎷 轉為浪漫微醺 Neo-Soul',
    '🌊 轉為陽光水岸吉他',
    '🏮 融入靜謐廟宇東方調',
    '🔊 分析現場音檔特徵',
    '🎲 重新獨立隨機創作',
  ];

  @override
  void initState() {
    super.initState();
    final current = widget.orchestrator.currentComposition;
    _messages.add(
      _ChatMessage(
        isUser: false,
        text: '👋 你好！我是 CityMu 專屬的 Gemini AI 音樂作曲家。\n目前正在為您演奏【${current.title}】（${current.scaleName}）。\n\n您可以隨時告訴我您的音樂喜好（如：「換成更感傷的爵士吉他」、「分析周遭音檔」、「加入七和弦琶音」），或點選下方快捷建議，我會即時為您創作並注入播放器！',
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    final prompt = text.trim();
    if (prompt.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: prompt));
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final response = await widget.orchestrator.chatWithAiComposer(prompt);
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              isUser: false,
              text: response.message,
              composition: response.newComposition,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              isUser: false,
              text: '連線處理時發生錯誤 ($e)，請再試一次或切換離線模式。',
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header & Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue,
                  radius: 18,
                  child: Icon(Icons.auto_awesome, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🎙️ Gemini AI 作曲家即時對話',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: GeminiService.instance.hasValidApiKey
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              GeminiService.instance.hasValidApiKey ? '🟢 Gemini 3.5 雲端' : '⚡ 內建極速離線',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: GeminiService.instance.hasValidApiKey
                                    ? const Color(0xFF2E7D32)
                                    : AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Expanded(
                            child: Text(
                              '直接下達風格/和弦/分析指令',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '設定 Gemini API Key',
                  icon: Icon(
                    GeminiService.instance.hasValidApiKey ? Icons.key_rounded : Icons.key_off_rounded,
                    color: GeminiService.instance.hasValidApiKey ? const Color(0xFF2E7D32) : AppTheme.primaryBlue,
                    size: 20,
                  ),
                  onPressed: () {
                    final keyCtrl = TextEditingController(text: GeminiService.instance.currentApiKey ?? '');
                    showDialog(
                      context: context,
                      builder: (dCtx) => AlertDialog(
                        title: const Text('🔑 設定 Gemini API Key'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '輸入您的 Google Gemini API Key 以啟用完整雲端多模態即時創作。\n若留空則會以「極速內建智慧演算法」離線作曲。',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: keyCtrl,
                              decoration: const InputDecoration(
                                hintText: 'AIzaSy...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              keyCtrl.clear();
                              GeminiService.instance.setApiKey('');
                              setState(() {});
                              Navigator.pop(dCtx);
                            },
                            child: const Text('清除 (使用離線模式)'),
                          ),
                          FilledButton(
                            onPressed: () {
                              GeminiService.instance.setApiKey(keyCtrl.text.trim());
                              setState(() {});
                              Navigator.pop(dCtx);
                            },
                            child: const Text('儲存'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorderLight),

          // Quick Prompt Inspiration Chips
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.chipBackground,
                  side: const BorderSide(color: AppTheme.cardBorderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorderLight),

          // Chat Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg, theme);
              },
            ),
          ),

          // Loading Indicator if AI is composing
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  Text('Gemini 正在聆聽空間並編織專屬音樂...', style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue)),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, mediaQuery.viewInsets.bottom + 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(top: BorderSide(color: AppTheme.cardBorderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '向 AI 作曲家下指令 (例如: 換成憂鬱吉他、分析音檔...)',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: AppTheme.chipBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.cardBorderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: AppTheme.cardBorderLight),
                      ),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _sendMessage(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg, ThemeData theme) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: AppTheme.chipBackground,
              radius: 14,
              child: Icon(Icons.auto_awesome, size: 14, color: AppTheme.primaryBlue),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.chipBackground,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: AppTheme.cardBorderLight),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.45),
                    ),
                  ),
                  if (msg.composition != null) ...[
                    const SizedBox(height: 8),
                    _buildCompositionCard(msg.composition!, theme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompositionCard(AiComposition comp, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.music_note_rounded, size: 14, color: AppTheme.primaryBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  comp.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.chipBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(comp.scaleName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '和弦進程: ${comp.chordNames.join(' ➔ ')}',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            comp.poeticStory,
            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textTertiary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.orchestrator.applyCustomAiComposition(comp);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✨ 已成功套用【${comp.title}】至播放器！'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
              label: const Text('✨ 立即套用此 AI 創作至播放器', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
