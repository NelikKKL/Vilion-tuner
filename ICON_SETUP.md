# Icon Setup

The app icon has been integrated. Files added/updated:

## Android (automatic, already placed)
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48×48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72×72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96×96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144×144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192×192)

## Using flutter_launcher_icons (optional, for regeneration)
```
flutter pub get
flutter pub run flutter_launcher_icons
```

## Source files
- `icon_1024.png` — master icon (1024×1024)
- `icon.svg` — vector source

## UI changes (v1.1.0)
- Custom violin icon in bottom navigation bar (Tuner tab)
- App icon shown in Settings footer with version number
- Version bumped to 1.1.0+2
