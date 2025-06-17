# SecureVideo Player App

A Flutter-based secure video player for the MEL.Labs Internship Assessment, with video playback, dynamic watermarking and screenshot detection.

## Setup Instructions
1. **Prerequisites**:
   - Flutter SDK (3.x+)
   - Dart
   - Physical device for screenshot testing
   - MP4 videos
2. **Installation**:
   ```bash
   git clone https://github.com/nerdcoder04/Videoplayer.git
   cd player
   flutter pub get
   flutter run
   ```
3. Use file picker to import MP4 file.
4. **Dependencies**:
   - `video_player: ^2.9.1`
   - `file_picker: ^8.1.2`
   - `shared_preferences: ^2.3.0`
   - `no_screenshot: ^3.0.0`
   - `path_provider: ^2.1.4`
5. Use a physical device for screenshot testing.

## Features Implemented
- **Video Player**: MP4 playback with play/pause, seek, volume, full-screen, and time display; 10s rewind/fast-forward, 0.5x-2.0x speed.
- **Watermarking**: Username + timestamp overlay, updates every 30s, 50% opacity, multiple positions (top-left, top-right, bottom-left, bottom-right, center).
- **Screenshot Protection**: Blocks screenshots with black screen and "Screenshot Blocked" popup, logs attempts.
- **UI**: Mobile-friendly with library, player, settings screens; gradient navigation, secure mode.
- **Video Management**: Upload/delete videos, stores watermarked video metadata.

## Testing Screenshot Detection
1. Run app on physical device.
2. Play video, attempt screenshot (e.g., power + volume down).
3. Verify:
   - Black screen with "Screenshot Blocked" popup.
   - Video pauses.
   - Attempt count logged (may not update due to limitation).

## Known Limitations
- Screenshot attempt count update inconsistent.
- MP4-only support, per requirements.
- iOS screenshot detection unreliable.
- Watermark may overlap video content.

## Architecture Decisions
Built with Flutter for cross-platform use, using a simplified MVVM pattern:
- **Model**: Manages video metadata and settings via `SharedPreferences`, JSON for watermarked videos.
- **View**: Flutter widgets for library, player, settings screens.
- **ViewModel**: Stateful widgets and `VideoPlayerController` for state.
Modular structure with `screens`, `widgets`, `theme.dart`. Bottom navigation and dynamic orientation enhance usability.

## Security Approach Explanation
1. **Watermarking**: Semi-transparent username/timestamp overlay, updated every 30s, with five configurable positions to deter cropping, stored in `SharedPreferences`.
2. **Screenshot Protection**: `no_screenshot` blocks screenshots (black screen, popup), pauses video, logs attempts. Less reliable on iOS. Secure mode restricts controls.

## What You’d Improve Given More Time
- Animate watermark transitions.
- Fix screenshot count update, improve iOS detection.
- Support more video formats.
- Optimize loading for low-end devices, add unit tests.
