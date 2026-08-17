# plan.md: 賽博空間純音效驅動 Lo-Fi 音樂生成器開發計劃

本文件為 **Cyber-LoFi Spatial Music Generator** 之完整開發規範與架構設計書。本專案採用 **音效採樣合成為主（Foley-First Engine）**，將現實空間音效切片與變調轉化為音樂元素，並在過度變調失真時提供備用樂器保護機制。

---

## 1. 專案概述 (Project Overview)

* **專案名稱**：Cyber-LoFi Spatial Music Generator (Foley-First Edition)
* **目標平台**：Android (API Level 26+)
* **核心框架**：Flutter (3.22+) / Dart (3.4+)
* **核心定位**：基於裝置 GPS 座標、離線 GeoJSON 空間圖層及加速度計數據，將環境音效採樣（捷運進站音、氣壓煞車聲、電火花聲、地底低頻、週為人流密度等）經由 `flutter_soloud` 進行 **Pitch Shift（音高變換）與 瞬態切片（Transient Slicing）**，即時生成賽博 Lo-Fi 音樂。

---

## 2. 技術棧與套件規格 (Tech Stack & Dependencies)

### 2.1 程式語言與資料格式

* **Primary Language**: Dart 3.x
* **Data Format**: GeoJSON, Wave (16-bit 44.1kHz WAV)

### 2.2 核心依賴套件 (`pubspec.yaml`)

* **`flutter_soloud`**: 高效能 C++ 底層音訊引擎，負責多軌 Sampler、Playback Rate (Pitch Shift)、Looping 與 Volume 混音。
* **`turf`**: 本地計算點到線（Point-to-Line）、點到面（Point-in-Polygon）空間距離。
* **`geolocator`**: 讀取 GPS 座標。
* **`sensors_plus`**: 讀取使用者加速度計（Accelerometer）數據。
* **`flutter_foreground_task`**: 確保 App 螢幕關閉或切換至背景時，GPS 與音訊引擎持續運行。
* **`permission_handler`**: 處理 Android 位置與前台服務通知權限。

---

## 3. 音訊來源與資產結構 (Audio Source & Assets)

### 3.1 音效與備用樂器對映表 (Audio Source Mapping)

| 音樂軌道 (Track) | 主要來源 (Primary Foley) | 音效轉化處理方式 (DSP Processing) | 備用降級樂器 (Fallback Instrument) |
| --- | --- | --- | --- |
| **旋律 (Melody)** | 捷運進站警報音 (`mrt_beep.wav`) | 捕捉瞬態 (Attack)，經 Sampler 根據五聲音階進行 Pitch Shift | 鋪氈鋼琴 (`felt_piano_d.wav`) |
| **節奏/小鼓 (Snare)** | 公車煞車洩壓氣聲 (`air_brake.wav`) | 帶通濾波器 (1k-4kHz) 切片做成 Snare | 標準 Lo-Fi Snare (`lofi_snare.wav`) |
| **節奏/腳踏鈸 (Hi-Hat)** | 電波/高壓電 Spark 音效 (`power_spark.wav`) | 短時間窗切片 + 極短衰減 Envelope | 傳統 Lo-Fi Hi-Hat (`hihat.wav`) |
| **重低音 (Sub-Bass)** | 地底捷運過站低頻 (`subway_rumble.wav`) | 低通濾波器 (Cutoff < 120Hz) 調諧至根音 $D1/B0$ | - |
| **節奏底噪 (Vinyl)** | 地下水管/雨水流動聲 (`water_trickle.wav`) | 帶狀濾波模擬黑膠炒豆質感 | - |

### 3.2 專案目錄結構

```text
cyber_lofi/
├── android/
├── assets/
│   ├── audio/
│   │   ├── foley_primary/          # 核心音效採樣庫
│   │   │   ├── mrt_beep.wav        # 旋律音源
│   │   │   ├── air_brake.wav       # 小鼓音源
│   │   │   ├── power_spark.wav     # Hi-Hat 音源
│   │   │   ├── subway_rumble.wav   # Bass 音源
│   │   │   └── water_trickle.wav   # 底噪音源
│   │   └── fallback_instruments/   # 備用降級樂器庫 (音高失真保護)
│   │       ├── felt_piano_d.wav
│   │       └── lofi_snare.wav
│   └── geo/
│       ├── mrt_lines.geojson       # 離線捷運與軌道向量圖層
│       ├── power_grid.geojson      # 離線變電所/高壓設施圖層
│       └── water_pipes.geojson     # 離線地下幹管圖層
├── lib/
│   ├── main.dart                   # 程式總入口、服務初始化
│   ├── core/
│   │   ├── constants/
│   │   │   ├── audio_constants.dart # 音階、BPM、音量閾值定義
│   │   │   └── gis_constants.dart   # 影響半徑、GeoJSON 路徑
│   │   └── enums/
│   │       └── feature_type.dart   # 空間要素分類 (mrt, power, water)
│   ├── models/
│   │   ├── audio_parameter.dart    # 音訊參數封裝模型 (Volume, Pitch, BPM)
│   │   └── spatial_feature.dart    # 空間計算結果模型 (Type, Distance)
│   ├── services/
│   │   ├── audio_engine_service.dart  # flutter_soloud 封裝與音高變換層
│   │   ├── gis_service.dart           # turf 本地空間運算服務
│   │   ├── location_service.dart      # Geolocator 監聽服務
│   │   ├── sensor_service.dart        # SensorsPlus 加速度計監聽服務
│   │   └── foreground_service.dart    # Android 前台服務背景常駐
│   ├── controllers/
│   │   └── music_orchestrator.dart    # 核心音樂編排器
│   └── ui/
│       ├── screens/
│       │   └── home_screen.dart       # 主控制與繪圖視覺化介面
│       └── widgets/
│           ├── radar_view.dart        # 空間要素相對位置雷達圖
│           └── audio_visualizer.dart  # 動態波形圖
└── plan.md                         # 開發計畫文件
```

---

## 4. 音效處理與映射邏輯 (Unambiguous Rules)

### 4.1 音效降級保護機制 (`audio_engine_service.dart`)

在動態變調時，系統執行以下單一降級規則，確保音質穩定：

* **半音極限保護 (Pitch Shift Boundary Check)**：
當音樂邏輯計算出旋律所需的移調半音數 $\vert{}\Delta \text{Semitones}\vert{} > 7$（超過純五度）時，音效會產生嚴重的 Chipmunk 數位失真。
* **處理方式**：觸發降級，該音符自動改由 `fallback_instruments/felt_piano_d.wav` 播放。



---

### 4.2 空間與感測器音效控制邏輯 (`music_orchestrator.dart`)

全曲基於 **D Major 五聲音階** $(D, E, F\sharp, A, B)$：




#### 4.2.2 節奏音軌：氣壓煞車音 (`air_brake.wav`) 與 Spark (`power_spark.wav`)

* **加速度計連動**：讀取 3 軸加速度算出的去重力強度 $M = \sqrt{x^2 + y^2 + z^2} - 9.80665$：
* **靜止 ($M < 0.3 \text{ m/s}^2$)**：靜音節奏軌。
* **步行 ($M \ge 0.3 \text{ m/s}^2$)**：觸發 `air_brake.wav` 做為第 2、4 拍 Snare，觸發 `power_spark.wav` 做為 Hi-Hat。
* **BPM 映射**：$\text{BPM} = 75.0 + (M \times 5.0)$，上限截斷為 95.0 BPM。



#### 4.2.3 重低音與質感音軌：`subway_rumble.wav` & `water_trickle.wav`

* **Sub-Bass**：當 $d_{mrt} \le 150 \text{ 米}$ 時，開啟 `subway_rumble.wav`，音量隨距離遞增。
* **Vinyl 底噪**：當地下水管距離 $d_{water} \le 50 \text{ 米}$ 時，開啟 `water_trickle.wav` 帶狀濾波聲。

---

## 5. 開發階段與時程計劃 (Development Phases)

* **階段 1：資產準備**：對 `foley_primary/` 音效進行裁切（Truncate Silence）與標定 $D4$ 基頻，建立對應音階之 Speed 映射表。
* **階段 2：音訊引擎層 (`flutter_soloud`)**：編寫 `AudioEngineService`，實現 `playSample()`、`setVolume()` 與 `setRelativePlaySpeed()`。
* **階段 3：降級機制與樂理測試**：編寫單元測試，驗證移調半音數 $> 7$ 時能精準降級至 `felt_piano_d.wav`。
* **階段 4：GIS 與感測器綁定**：整合離線 Turf.js 與加速度計，實時驅動音樂編排器 `MusicOrchestrator`。
* **階段 5：前台服務與 UI**：整合 `flutter_foreground_task` 防殺機制，並繪製雷達可視化介面。

---

## 6. 驗收標準 (Acceptance Criteria)

1. **音效為主**：生成音樂中 90% 以上音域能清晰辨識出採樣自現實環境音效。
2. **音高獨立性**：捷運音效之 Pitch 變化僅精準遵循 D Major 五聲音階，不隨移動速度發生非樂理之音高飄移。
3. **降級保護**：極端變調（超過 7 半音）時能在 5ms 內平滑切換至備用鋼琴音效，無爆音。
4. **離線與背景穩定**：斷網狀態下，前台服務持續運行，中階 Android 機型 CPU 佔用率 $< 15\%$。
