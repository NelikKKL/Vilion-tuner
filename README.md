# 🎻 Violin Tuner & Metronome

Flutter-приложение для настройки скрипки и метроном с реальным определением высоты звука.

## Возможности

| Функция | Описание |
|---|---|
| 🎵 **Тюнер скрипки** | Реальное определение высоты через алгоритм YIN + PCM микрофон |
| 🎸 **4 струны** | G₃ (196 Гц), D₄ (294 Гц), A₄ (440 Гц), E₅ (659 Гц) + AUTO |
| 🥁 **Метроном** | Tap-tempo, выбор тактового размера, реальные звуки клика |
| 🎨 **Material You** | Динамические цвета с обоев (Android 12+) |
| 🌙 **Тёмная/светлая тема** | System / Light / Dark |
| 🎹 **Хроматический тюнер** | Все 12 полутонов |

## Архитектура тюнера

```
Микрофон (44100 Гц, PCM 16-bit, моно)
    │
    ▼
Накопитель чанков (4096 сэмплов = ~93 мс)
    │
    ▼
Background Isolate (не блокирует UI)
    │
    ├── RMS gate (тишина → игнор)
    │
    ▼
YIN алгоритм (порог 0.15)
    │
    ▼
Медианный фильтр (окно 5) — устраняет дребезг
    │
    ▼
freq → MIDI → нота + центы → UI
```

**Почему YIN?**
- Точнее простого FFT для монофонических инструментов
- Хорошо работает для скрипки (богатый обертонами звук)
- Не требует внешних DSP библиотек — чистый Dart

## Быстрый старт

```bash
git clone https://github.com/YOUR_USERNAME/violin_tuner.git
cd violin_tuner
flutter pub get
flutter run
```

## Зависимости

```yaml
record: ^5.1.2          # PCM поток с микрофона
audioplayers: ^6.0.0    # Звуки метронома
dynamic_color: ^1.7.0   # Material You
permission_handler: ^11.3.1
provider: ^6.1.2
```

## GitHub Actions — Автосборка APK

При каждом пуше в `main`:
1. Открой вкладку **Actions**
2. Выбери последний запуск
3. Скачай APK из раздела **Artifacts**

## Структура проекта

```
lib/
├── main.dart
├── theme/app_theme.dart
├── screens/
│   ├── main_screen.dart
│   ├── tuner_screen.dart
│   ├── metronome_screen.dart
│   ├── chromatic_screen.dart
│   └── settings_screen.dart
├── services/
│   ├── tuner_service.dart       ← реальный микрофон + isolate
│   ├── yin_pitch_detector.dart  ← YIN алгоритм
│   └── metronome_service.dart   ← реальные WAV клики
└── widgets/
    ├── tuner_needle.dart
    ├── violin_scroll_widget.dart
    ├── string_button.dart
    ├── beat_indicator.dart
    └── bpm_dial.dart

assets/sounds/
├── click_accent.wav   ← высокий тон, бит 1
└── click_normal.wav   ← обычный клик
```

## Разрешения

- `RECORD_AUDIO` — микрофон для тюнера
- `NSMicrophoneUsageDescription` — iOS

## Настройка под себя

**Чувствительность YIN** (в `yin_pitch_detector.dart`):
```dart
threshold: 0.15  // ↓ чувствительнее, ↑ стабильнее
```

**Эталонный тон A4** (в `tuner_service.dart`):
```dart
final midiNote = 12 * log(freq / 440.0) / log(2) + 69;
//                                  ↑ замени на 432, 443 и т.д.
```
