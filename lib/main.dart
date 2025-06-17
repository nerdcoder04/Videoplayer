import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for SystemChrome
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no_screenshot/no_screenshot.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player App',
      theme: AppTheme.theme,
      home: MainScreen(prefs: prefs),
    );
  }
}

class MainScreen extends StatefulWidget {
  final SharedPreferences prefs;
  
  const MainScreen({super.key, required this.prefs});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
    _screens = [
      LibraryScreen(prefs: widget.prefs),
      SettingsScreen(prefs: widget.prefs),
    ];
  }

  void _initializeSettings() {
    if (widget.prefs.getBool('watermarkEnabled') == null) {
      widget.prefs.setBool('watermarkEnabled', true);
    }
    if (widget.prefs.getBool('secureModeEnabled') == null) {
      widget.prefs.setBool('secureModeEnabled', true);
    }
    if (widget.prefs.getBool('screenshotProtectionEnabled') == null) {
      widget.prefs.setBool('screenshotProtectionEnabled', true);
    }
    if (widget.prefs.getString('watermarkUsername') == null) {
      widget.prefs.setString('watermarkUsername', '');
    }
    if (widget.prefs.getString('watermarkPosition') == null) {
      widget.prefs.setString('watermarkPosition', WatermarkPosition.bottomRight.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.lightGradient,
          ),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.video_library,
                  label: 'Library',
                  index: 0,
                  isSelected: _currentIndex == 0,
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  index: 1,
                  isSelected: _currentIndex == 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isSelected ? AppTheme.featuredCardGradient : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryScreen extends StatefulWidget {
  final SharedPreferences prefs;
  
  const LibraryScreen({super.key, required this.prefs});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  File? _selectedVideo;
  String? _uploadStatus;
  List<File> _recentVideos = [];

  @override
  void initState() {
    super.initState();
    _loadRecentVideos();
  }

  Future<void> _loadRecentVideos() async {
    final directory = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${directory.path}/watermarked_videos');
    if (await videoDir.exists()) {
      final files = await videoDir.list().toList();
      setState(() {
        _recentVideos = files
            .whereType<File>()
            .where((file) => file.path.endsWith('.mp4'))
            .toList();
      });
    }
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedVideo = File(result.files.single.path!);
          _uploadStatus = 'Video selected: ${result.files.single.name}';
        });

        String? watermarkUsername;
        WatermarkPosition watermarkPosition = WatermarkPosition.bottomRight;
        if (widget.prefs.getBool('watermarkEnabled') ?? false) {
          watermarkUsername = widget.prefs.getString('watermarkUsername');
          final positionString = widget.prefs.getString('watermarkPosition');
          watermarkPosition = WatermarkPosition.values.firstWhere(
            (e) => e.toString() == positionString,
            orElse: () => WatermarkPosition.bottomRight,
          );
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoFile: _selectedVideo!,
              onVideoSaved: _loadRecentVideos,
              prefs: widget.prefs,
              initialWatermarkUsername: watermarkUsername,
              initialWatermarkPosition: watermarkUsername != null ? watermarkPosition : null,
            ),
          ),
        );
      } else {
        setState(() {
          _uploadStatus = 'No video selected';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error selecting video: $e';
      });
    }
  }

  Future<void> _deleteVideo(File video) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.cardColor,
        title: const Text(
          'Delete Video',
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${path.basename(video.path)}"?',
          style: const TextStyle(
            color: AppTheme.textColor,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textColor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final metadataPath = '${video.path}.json';
        final metadataFile = File(metadataPath);
        if (await metadataFile.exists()) {
          await metadataFile.delete();
        }
        await video.delete();
        setState(() {
          _recentVideos.remove(video);
          _uploadStatus = 'Video deleted successfully';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Video deleted successfully'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      } catch (e) {
        setState(() {
          _uploadStatus = 'Error deleting video: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting video: $e'),
            backgroundColor: AppTheme.primaryColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Video Library',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: AppTheme.darkGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickAndUploadVideo,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.upload_file,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload Video',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Select MP4 files to get started',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_uploadStatus != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: AppTheme.accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _uploadStatus!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_recentVideos.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Recent Videos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _recentVideos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final video = entry.value;
                      final metadataPath = '${video.path}.json';
                      final isWatermarked = File(metadataPath).existsSync();

                      return Padding(
                        padding: EdgeInsets.only(
                          right: index == _recentVideos.length - 1 ? 0 : 16,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerScreen(
                                  videoFile: video,
                                  onVideoSaved: _loadRecentVideos,
                                  prefs: widget.prefs,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 200, // Fixed width for each video card
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: isWatermarked
                                  ? AppTheme.accentCardGradient
                                  : AppTheme.cardGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 100, // Fixed height for video thumbnail
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        size: 40,
                                        color: isWatermarked
                                            ? Colors.white
                                            : AppTheme.textColor,
                                      ),
                                      if (isWatermarked)
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: AppTheme.highlightColor,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  path.basename(video.path),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isWatermarked
                                        ? Colors.white
                                        : AppTheme.textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Size: ${(video.lengthSync() / (1024 * 1024)).toStringAsFixed(2)} MB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isWatermarked
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: isWatermarked
                                          ? Colors.white
                                          : AppTheme.textColor,
                                      size: 24,
                                    ),
                                    onPressed: () => _deleteVideo(video),
                                    tooltip: 'Delete Video',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.textColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 40, // Match padding
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Steps to Use:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '1. Go to the settings.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2. Add User name and position in watermarks settings. Make changes according to your need.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '3. Come back to video library.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '4. Upload the video.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '5. Use the basic controls (more controls in icon.triple_dot).',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '6. Click on save icon.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '7. And... Voilà! Your watermark is now part of the show!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 100), // Padding to avoid bottom navigation bar overlap
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final SharedPreferences prefs;
  
  const SettingsScreen({super.key, required this.prefs});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _watermarkUsername;
  WatermarkPosition? _watermarkPosition;

  @override
  void initState() {
    super.initState();
    _watermarkUsername = widget.prefs.getString('watermarkUsername') ?? '';
    final positionString = widget.prefs.getString('watermarkPosition');
    _watermarkPosition = WatermarkPosition.values.firstWhere(
      (e) => e.toString() == positionString,
      orElse: () => WatermarkPosition.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final watermarkEnabled = widget.prefs.getBool('watermarkEnabled') ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppTheme.textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingTile(
                      icon: Icons.water_drop,
                      title: 'Watermark Feature',
                      subtitle: 'Show watermark on videos',
                      value: watermarkEnabled,
                      onChanged: (value) {
                        setState(() {
                          widget.prefs.setBool('watermarkEnabled', value);
                          if (!value) {
                            _watermarkUsername = '';
                            widget.prefs.setString('watermarkUsername', '');
                          }
                        });
                      },
                      gradient: AppTheme.accentCardGradient,
                    ),
                    if (watermarkEnabled) ...[
                      const Divider(height: 1, color: Colors.grey),
                      _buildWatermarkConfig(),
                    ],
                    const Divider(height: 1, color: Colors.grey),
                    _buildSettingTile(
                      icon: Icons.lock,
                      title: 'Secure Mode',
                      subtitle: 'Restrict video controls and speed',
                      value: widget.prefs.getBool('secureModeEnabled') ?? true,
                      onChanged: (value) {
                        setState(() {
                          widget.prefs.setBool('secureModeEnabled', value);
                        });
                      },
                      gradient: AppTheme.featuredCardGradient,
                    ),
                    const Divider(height: 1, color: Colors.grey),
                    _buildSettingTile(
                      icon: Icons.screenshot,
                      title: 'Screenshot Protection',
                      subtitle: 'Prevent screenshots during playback',
                      value: widget.prefs.getBool('screenshotProtectionEnabled') ?? true,
                      onChanged: (value) {
                        setState(() {
                          widget.prefs.setBool('screenshotProtectionEnabled', value);
                        });
                      },
                      gradient: AppTheme.darkGradient,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.highlightColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.block,
                        color: AppTheme.highlightColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Screenshot Attempts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor,
                            ),
                          ),
                          Text(
                            'Blocked: ${widget.prefs.getInt('screenshotAttempts') ?? 1}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Changing these settings will affect the video player controls and behavior.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100), // Padding to avoid bottom navigation bar overlap
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.accentColor,
              thumbColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return AppTheme.primaryColor;
                }
                return Colors.grey[300];
              }),
              trackColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return AppTheme.accentColor;
                }
                return Colors.grey[400];
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatermarkConfig() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform(
            transform: Matrix4.identity(),
            child: TextField(
              textDirection: TextDirection.ltr,
              onChanged: (value) {
                setState(() {
                  _watermarkUsername = value;
                  widget.prefs.setString('watermarkUsername', value);
                });
              },
              controller: TextEditingController(text: _watermarkUsername),
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'Roboto',
              ),
              decoration: InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.7)),
                hintText: 'Enter your username',
                hintStyle: TextStyle(color: AppTheme.textColor.withOpacity(0.5)),
                filled: true,
                fillColor: AppTheme.accentColor.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Position:',
                style: TextStyle(
                  color: AppTheme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<WatermarkPosition>(
                    value: _watermarkPosition,
                    onChanged: (WatermarkPosition? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _watermarkPosition = newValue;
                          widget.prefs.setString('watermarkPosition', newValue.toString());
                        });
                      }
                    },
                    items: WatermarkPosition.values.map((position) {
                      return DropdownMenuItem<WatermarkPosition>(
                        value: position,
                        child: Text(
                          position.toString().split('.').last,
                          style: const TextStyle(color: AppTheme.textColor),
                        ),
                      );
                    }).toList(),
                    isExpanded: true,
                    dropdownColor: AppTheme.cardColor,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.textColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum WatermarkPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

enum ControlMenuOption {
  speed,
  volume,
  fullScreen,
  secureMode,
}

class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;
  final VoidCallback? onVideoSaved;
  final SharedPreferences prefs;
  final String? initialWatermarkUsername;
  final WatermarkPosition? initialWatermarkPosition;

  const VideoPlayerScreen({
    super.key,
    required this.videoFile,
    this.onVideoSaved,
    required this.prefs,
    this.initialWatermarkUsername,
    this.initialWatermarkPosition,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isFullScreen = false;
  double _volume = 1.0;
  bool _secureMode = false;
  double _playbackSpeed = 1.0;
  final double _minSpeed = 0.5;
  final double _maxSpeed = 2.0;
  bool _showControls = true;
  bool _showVolumeBar = false;
  bool _showSpeedBar = false;
  bool _isSaving = false;
  bool _isHorizontalVideo = false; // To track if the video is horizontal

  String? _watermarkUsername;
  WatermarkPosition _watermarkPosition = WatermarkPosition.bottomRight;
  bool _showWatermark = false;
  DateTime? _lastWatermarkUpdate;

  final NoScreenshot _noScreenshot = NoScreenshot();
  bool _screenshotProtectionEnabled = true;
  int _screenshotAttempts = 0;

  @override
  void initState() {
    super.initState();
    // Ensure the app starts in portrait mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    _screenshotProtectionEnabled = widget.prefs.getBool('screenshotProtectionEnabled') ?? true;
    _screenshotAttempts = widget.prefs.getInt('screenshotAttempts') ?? 0;

    _loadWatermarkMetadata();

    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {
          // Determine if the video is horizontal (landscape) based on aspect ratio
          _isHorizontalVideo = _controller.value.aspectRatio > 1;
        });
        _controller.setLooping(true);
        _controller.setVolume(_volume);
        
        _initScreenshotProtection();
        
        _controller.addListener(() {
          if (_showWatermark && _controller.value.isPlaying) {
            final now = DateTime.now();
            if (_lastWatermarkUpdate == null || 
                now.difference(_lastWatermarkUpdate!).inSeconds >= 30) {
              setState(() {
                _lastWatermarkUpdate = now;
              });
            }
          }
        });
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing video: $error')),
        );
      });
  }

  Future<void> _loadWatermarkMetadata() async {
    if (widget.initialWatermarkUsername != null && widget.initialWatermarkUsername!.isNotEmpty) {
      setState(() {
        _watermarkUsername = widget.initialWatermarkUsername;
        _watermarkPosition = widget.initialWatermarkPosition ?? WatermarkPosition.bottomRight;
        _showWatermark = true;
        _lastWatermarkUpdate = DateTime.now();
      });
      return;
    }

    final metadataPath = '${widget.videoFile.path}.json';
    final metadataFile = File(metadataPath);
    if (await metadataFile.exists()) {
      try {
        final metadataString = await metadataFile.readAsString();
        final metadata = jsonDecode(metadataString);
        setState(() {
          _watermarkUsername = metadata['username'];
          _watermarkPosition = WatermarkPosition.values.firstWhere(
            (e) => e.toString() == metadata['position'],
            orElse: () => WatermarkPosition.bottomRight,
          );
          _lastWatermarkUpdate = DateTime.parse(metadata['timestamp']);
          _showWatermark = _watermarkUsername != null && _watermarkUsername!.isNotEmpty;
        });
      } catch (e) {
        print('Error loading watermark metadata: $e');
      }
    }
  }

  Future<void> _initScreenshotProtection() async {
    if (_screenshotProtectionEnabled) {
      await _noScreenshot.screenshotOff();
    } else {
      await _noScreenshot.screenshotOn();
    }
  }

  void _handleScreenshotAttempt() {
    setState(() {
      _screenshotAttempts++;
      widget.prefs.setInt('screenshotAttempts', _screenshotAttempts);
    });

    if (_controller.value.isPlaying) {
      _controller.pause();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Screenshot Blocked'),
        content: const Text('Taking screenshots is not allowed during video playback.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noScreenshot.screenshotOn();
    _controller.dispose();
    // Reset orientation to portrait when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = !_isFullScreen;
      _showVolumeBar = false;
      _showSpeedBar = false;

      // Change orientation based on full-screen state and video orientation
      if (_isFullScreen && _isHorizontalVideo) {
        // Allow landscape orientation for horizontal videos in full-screen
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        // Revert to portrait orientation when exiting full-screen or for vertical videos
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  void _rewind() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _controller.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  void _fastForward() {
    final currentPosition = _controller.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    final duration = _controller.value.duration;
    _controller.seekTo(newPosition > duration ? duration : newPosition);
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed.clamp(_minSpeed, _maxSpeed);
      _controller.setPlaybackSpeed(_playbackSpeed);
      _showSpeedBar = false;
    });
  }

  void _toggleVolumeBar() {
    setState(() {
      _showVolumeBar = !_showVolumeBar;
      _showSpeedBar = false;
    });
  }

  void _toggleSpeedBar() {
    setState(() {
      _showSpeedBar = !_showSpeedBar;
      _showVolumeBar = false;
    });
  }

  void _toggleSecureMode() {
    setState(() {
      _secureMode = !_secureMode;
      _showControls = true;
      if (_secureMode && _playbackSpeed > _maxSpeed) {
        _playbackSpeed = 1.0;
        _controller.setPlaybackSpeed(1.0);
      }
    });
  }

  void _toggleControlsVisibility() {
    if (!_secureMode) {
      setState(() {
        _showControls = !_showControls;
        if (!_showControls) {
          _showVolumeBar = false;
          _showSpeedBar = false;
        }
      });
    }
  }

  Future<void> _saveWatermarkedVideo() async {
    if (!_showWatermark || _watermarkUsername == null || _watermarkUsername!.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final directory = await getApplicationDocumentsDirectory();
      final videoDir = Directory('${directory.path}/watermarked_videos');
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${videoDir.path}/watermarked_$timestamp.mp4';
      final metadataPath = '$outputPath.json';

      await widget.videoFile.copy(outputPath);

      final metadata = {
        'username': _watermarkUsername,
        'position': _watermarkPosition.toString(),
        'timestamp': _lastWatermarkUpdate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
      final metadataFile = File(metadataPath);
      await metadataFile.writeAsString(jsonEncode(metadata));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Watermarked video saved successfully!')),
      );

      if (widget.onVideoSaved != null) {
        widget.onVideoSaved!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving watermarked video: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Widget _buildWatermark() {
    if (!_showWatermark || _watermarkUsername == null || _watermarkUsername!.isEmpty) {
      return const SizedBox();
    }

    final timestamp = _lastWatermarkUpdate?.toLocal().toString().split('.')[0] ?? '';
    final watermarkText = '$_watermarkUsername\n$timestamp';

    Alignment alignment;
    switch (_watermarkPosition) {
      case WatermarkPosition.topLeft:
        alignment = Alignment.topLeft;
        break;
      case WatermarkPosition.topRight:
        alignment = Alignment.topRight;
        break;
      case WatermarkPosition.bottomLeft:
        alignment = Alignment.bottomLeft;
        break;
      case WatermarkPosition.bottomRight:
        alignment = Alignment.bottomRight;
        break;
      case WatermarkPosition.center:
        alignment = Alignment.center;
        break;
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Opacity(
          opacity: 0.5,
          child: Text(
            watermarkText,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 16,
              shadows: const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 10,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showControlMenu(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final position = RelativeRect.fromLTRB(
      size.width - 200,
      0,
      0,
      size.height,
    );

    showMenu<ControlMenuOption>(
      context: context,
      position: position,
      items: [
        const PopupMenuItem<ControlMenuOption>(
          value: ControlMenuOption.speed,
          child: Row(
            children: [
              Icon(Icons.speed, color: Colors.black),
              SizedBox(width: 8),
              Text('Playback Speed'),
            ],
          ),
        ),
        const PopupMenuItem<ControlMenuOption>(
          value: ControlMenuOption.volume,
          child: Row(
            children: [
              Icon(Icons.volume_up, color: Colors.black),
              SizedBox(width: 8),
              Text('Volume'),
            ],
          ),
        ),
        const PopupMenuItem<ControlMenuOption>(
          value: ControlMenuOption.fullScreen,
          child: Row(
            children: [
              Icon(Icons.fullscreen, color: Colors.black),
              SizedBox(width: 8),
              Text('Full Screen'),
            ],
          ),
        ),
        const PopupMenuItem<ControlMenuOption>(
          value: ControlMenuOption.secureMode,
          child: Row(
            children: [
              Icon(Icons.lock, color: Colors.black),
              SizedBox(width: 8),
              Text('Secure Mode'),
            ],
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ).then((ControlMenuOption? value) {
      if (value != null) {
        switch (value) {
          case ControlMenuOption.speed:
            if (!_secureMode) _toggleSpeedBar();
            break;
          case ControlMenuOption.volume:
            if (!_secureMode) _toggleVolumeBar();
            break;
          case ControlMenuOption.fullScreen:
            _toggleFullScreen();
            break;
          case ControlMenuOption.secureMode:
            _toggleSecureMode();
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final watermarkEnabled = widget.prefs.getBool('watermarkEnabled') ?? true;
    final secureModeEnabled = widget.prefs.getBool('secureModeEnabled') ?? true;
    _screenshotProtectionEnabled = widget.prefs.getBool('screenshotProtectionEnabled') ?? true;

    return Scaffold(
      backgroundColor: _isFullScreen ? Colors.black : Theme.of(context).scaffoldBackgroundColor,
      appBar: _isFullScreen || _secureMode
          ? null
          : AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Video Player'),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                if (watermarkEnabled && _showWatermark)
                  IconButton(
                    icon: Icon(
                      Icons.check,
                      color: _showWatermark ? AppTheme.highlightColor : AppTheme.highlightColor.withOpacity(0.5),
                    ),
                    onPressed: _saveWatermarkedVideo,
                    tooltip: 'Save Watermarked Video',
                  ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showControlMenu(context),
                  tooltip: 'More Controls',
                ),
              ],
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: _isFullScreen ? null : AppTheme.lightGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              GestureDetector(
                onTap: _toggleControlsVisibility,
                child: _controller.value.isInitialized
                    ? Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: _controller.value.aspectRatio,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: VideoPlayer(_controller),
                                    ),
                                  ),
                                  if (watermarkEnabled) _buildWatermark(),
                                ],
                              ),
                            ),
                          ),
                          if (_secureMode)
                            Positioned(
                              top: 16,
                              right: 16,
                              child: FloatingActionButton(
                                backgroundColor: AppTheme.primaryColor,
                                onPressed: _toggleSecureMode,
                                child: Icon(
                                  Icons.lock,
                                  size: 28,
                                  color: Colors.white,
                                ),
                                tooltip: 'Disable Secure Mode',
                              ),
                            ),
                          if (_showControls && !_secureMode && !_isFullScreen)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDuration(_controller.value.position),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                _formatDuration(_controller.value.duration),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          VideoProgressIndicator(
                                            _controller,
                                            allowScrubbing: !_secureMode,
                                            colors: VideoProgressColors(
                                              playedColor: AppTheme.accentColor,
                                              bufferedColor: Colors.white.withOpacity(0.5),
                                              backgroundColor: Colors.white.withOpacity(0.2),
                                            ),
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.replay_10,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                                onPressed: _rewind,
                                                tooltip: 'Rewind 10 seconds',
                                              ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: AppTheme.darkGradient,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0.2),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: IconButton(
                                                  icon: Icon(
                                                    _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                                    color: Colors.white,
                                                    size: 28,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (_controller.value.isPlaying) {
                                                        _controller.pause();
                                                      } else {
                                                        _controller.play();
                                                      }
                                                    });
                                                  },
                                                  tooltip: _controller.value.isPlaying ? 'Pause' : 'Play',
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.forward_10,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                                onPressed: _fastForward,
                                                tooltip: 'Fast forward 10 seconds',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (_showVolumeBar && !_secureMode)
                            Positioned(
                              bottom: 120,
                              right: 16,
                              child: AnimatedOpacity(
                                opacity: _showVolumeBar ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.darkGradient,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _volume == 0 ? Icons.volume_off : Icons.volume_up,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(height: 8),
                                      RotatedBox(
                                        quarterTurns: 3,
                                        child: Slider(
                                          value: _volume,
                                          onChanged: (value) {
                                            setState(() {
                                              _volume = value;
                                              _controller.setVolume(value);
                                            });
                                          },
                                          onChangeEnd: (value) {
                                            setState(() {
                                              _showVolumeBar = false;
                                            });
                                          },
                                          min: 0.0,
                                          max: 1.0,
                                          activeColor: AppTheme.accentColor,
                                          inactiveColor: Colors.white.withOpacity(0.3),
                                          thumbColor: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_showSpeedBar && !_secureMode && (!secureModeEnabled || !_secureMode))
                            Positioned(
                              bottom: 120,
                              left: 16,
                              child: AnimatedOpacity(
                                opacity: _showSpeedBar ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  width: 60,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.darkGradient,
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_playbackSpeed.toStringAsFixed(1)}x',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      RotatedBox(
                                        quarterTurns: 3,
                                        child: Slider(
                                          value: _playbackSpeed,
                                          onChanged: (value) {
                                            setState(() {
                                              _playbackSpeed = value.clamp(_minSpeed, _maxSpeed);
                                              _controller.setPlaybackSpeed(_playbackSpeed);
                                            });
                                          },
                                          onChangeEnd: (value) {
                                            _changePlaybackSpeed(value);
                                          },
                                          min: _minSpeed,
                                          max: _maxSpeed,
                                          divisions: 3,
                                          label: '${_playbackSpeed.toStringAsFixed(1)}x',
                                          activeColor: AppTheme.accentColor,
                                          inactiveColor: Colors.white.withOpacity(0.3),
                                          thumbColor: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (_isFullScreen)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton(
                                backgroundColor: AppTheme.primaryColor,
                                onPressed: _toggleFullScreen,
                                child: const Icon(
                                  Icons.fullscreen_exit,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              if (_isSaving)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}