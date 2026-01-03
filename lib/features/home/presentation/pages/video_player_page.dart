import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';

class VideoPlayerPage extends StatefulWidget {
  final List<Map<String, dynamic>>? videos;
  final List<Map<String, dynamic>>? sections;
  final int initialIndex;
  final String? videoUrl;
  final String title;
  final String? courseTitle;

  const VideoPlayerPage({
    Key? key,
    this.videos,
    this.sections,
    this.initialIndex = 0,
    this.videoUrl,
    required this.title,
    this.courseTitle,
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;
  int _currentVideoIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentVideoIndex = widget.initialIndex;
    _initializePlayer();
  }

  String _formatDuration(dynamic durationValue) {
    if (durationValue == null) return '0:00';

    // Convert to int (handle both int and String types)
    int seconds;
    if (durationValue is int) {
      seconds = durationValue;
    } else if (durationValue is String) {
      seconds = int.tryParse(durationValue) ?? 0;
    } else if (durationValue is double) {
      seconds = durationValue.toInt();
    } else {
      return '0:00';
    }

    if (seconds == 0) return '0:00';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${secs.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Dispose previous controllers
      _chewieController?.dispose();
      await _videoPlayerController?.dispose();

      String? videoUrl;

      // Get video URL from either videos list or sections
      if (widget.videos != null && widget.videos!.isNotEmpty) {
        final currentVideo = widget.videos![_currentVideoIndex];
        videoUrl = currentVideo['url'] ?? currentVideo['videoUrl'];
      } else if (widget.sections != null && widget.sections!.isNotEmpty) {
        // Find the video in sections based on global index
        int globalIndex = 0;
        bool found = false;

        for (var section in widget.sections!) {
          final sectionVideos =
              (section['videos'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          for (var video in sectionVideos) {
            if (globalIndex == _currentVideoIndex) {
              videoUrl = video['url'] ?? video['videoUrl'];
              found = true;
              break;
            }
            globalIndex++;
          }

          if (found) break;
        }
      } else {
        videoUrl = widget.videoUrl;
      }

      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('Video URL topilmadi');
      }

      // Check if URL is local or network
      final isNetworkUrl = videoUrl.startsWith('http');
      final fullUrl = isNetworkUrl
          ? videoUrl
          : '${AppConstants.baseUrl}$videoUrl';

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(fullUrl),
      );
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsOnEnterFullScreen: [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.grey.shade300,
          bufferedColor: Colors.grey.shade400,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        autoInitialize: true,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Video yuklashda xatolik',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
        additionalOptions: (context) {
          return <OptionItem>[
            OptionItem(
              onTap: (context) {
                final currentPosition = _videoPlayerController!.value.position;
                final newPosition =
                    currentPosition - const Duration(seconds: 15);
                _videoPlayerController!.seekTo(
                  newPosition < Duration.zero ? Duration.zero : newPosition,
                );
              },
              iconData: Icons.replay_10,
              title: '15s orqaga',
            ),
            OptionItem(
              onTap: (context) {
                final currentPosition = _videoPlayerController!.value.position;
                final duration = _videoPlayerController!.value.duration;
                final newPosition =
                    currentPosition + const Duration(seconds: 15);
                _videoPlayerController!.seekTo(
                  newPosition > duration ? duration : newPosition,
                );
              },
              iconData: Icons.forward_10,
              title: '15s oldinga',
            ),
            OptionItem(
              onTap: (context) {
                final currentOrientation = MediaQuery.of(context).orientation;
                if (currentOrientation == Orientation.portrait) {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.landscapeLeft,
                    DeviceOrientation.landscapeRight,
                  ]);
                } else {
                  SystemChrome.setPreferredOrientations([
                    DeviceOrientation.portraitUp,
                    DeviceOrientation.portraitDown,
                  ]);
                }
              },
              iconData: Icons.screen_rotation,
              title: 'Ekranni aylantirish',
            ),
          ];
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  int _getTotalVideoCount() {
    if (widget.videos != null) {
      return widget.videos!.length;
    } else if (widget.sections != null) {
      int total = 0;
      for (var section in widget.sections!) {
        final sectionVideos =
            (section['videos'] as List<dynamic>?)?.length ?? 0;
        total += sectionVideos;
      }
      return total;
    }
    return 0;
  }

  void _playNextVideo() {
    final totalVideos = _getTotalVideoCount();
    if (_currentVideoIndex < totalVideos - 1) {
      setState(() {
        _currentVideoIndex++;
      });
      _initializePlayer();
    }
  }

  void _playPreviousVideo() {
    if (_currentVideoIndex > 0) {
      setState(() {
        _currentVideoIndex--;
      });
      _initializePlayer();
    }
  }

  void _selectVideo(int index) {
    if (index != _currentVideoIndex) {
      setState(() {
        _currentVideoIndex = index;
      });
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    // Reset orientation to portrait when leaving
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Map<String, dynamic>? _getCurrentVideoData() {
    if (widget.videos != null && _currentVideoIndex < widget.videos!.length) {
      return widget.videos![_currentVideoIndex];
    } else if (widget.sections != null) {
      int globalIndex = 0;
      for (var section in widget.sections!) {
        final sectionVideos =
            (section['videos'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        for (var video in sectionVideos) {
          if (globalIndex == _currentVideoIndex) {
            return video;
          }
          globalIndex++;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final totalVideos = _getTotalVideoCount();
    final hasPlaylist = totalVideos > 1;
    final currentVideo = _getCurrentVideoData();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.all(8.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              iconSize: 18.sp,
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseTitle ?? widget.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasPlaylist)
              Text(
                '${_currentVideoIndex + 1} / $totalVideos',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _isLoading
                ? Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _errorMessage != null
                ? Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Video yuklashda xatolik',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.w),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14.sp,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          ElevatedButton(
                            onPressed: _initializePlayer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: 32.w,
                                vertical: 12.h,
                              ),
                            ),
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _isInitialized && _chewieController != null
                ? Chewie(controller: _chewieController!)
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),

          // Video Info and Playlist
          if (hasPlaylist)
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Current Video Info
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentVideo?['title'] ??
                                'Video ${_currentVideoIndex + 1}',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _formatDuration(currentVideo?['duration']),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Navigation Buttons
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _currentVideoIndex > 0
                                  ? _playPreviousVideo
                                  : null,
                              icon: const Icon(Icons.skip_previous),
                              label: const Text('Oldingi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _currentVideoIndex < totalVideos - 1
                                  ? _playNextVideo
                                  : null,
                              icon: const Icon(Icons.skip_next),
                              label: const Text('Keyingi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Video List
                    Expanded(
                      child:
                          widget.sections != null && widget.sections!.isNotEmpty
                          ? ListView.builder(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              itemCount: widget.sections!.length,
                              itemBuilder: (context, sectionIndex) {
                                final section = widget.sections![sectionIndex];
                                final sectionVideos =
                                    (section['videos'] as List<dynamic>?)
                                        ?.cast<Map<String, dynamic>>() ??
                                    [];

                                return Theme(
                                  data: Theme.of(
                                    context,
                                  ).copyWith(dividerColor: Colors.transparent),
                                  child: ExpansionTile(
                                    initiallyExpanded: true,
                                    tilePadding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    title: Text(
                                      section['title'] ??
                                          'Bo\'lim ${sectionIndex + 1}',
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${sectionVideos.length} ta video',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    children: sectionVideos.asMap().entries.map(
                                      (entry) {
                                        final localIndex = entry.key;
                                        final video = entry.value;

                                        // Calculate global index
                                        int globalIndex = 0;
                                        for (int i = 0; i < sectionIndex; i++) {
                                          final prevSection =
                                              widget.sections![i];
                                          final prevVideos =
                                              (prevSection['videos']
                                                      as List<dynamic>?)
                                                  ?.length ??
                                              0;
                                          globalIndex += prevVideos;
                                        }
                                        globalIndex += localIndex;

                                        final isCurrentVideo =
                                            globalIndex == _currentVideoIndex;

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isCurrentVideo
                                                ? AppColors.primary.withOpacity(
                                                    0.08,
                                                  )
                                                : Colors.transparent,
                                            border: Border(
                                              top: BorderSide(
                                                color: Colors.grey.shade200,
                                              ),
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                  vertical: 4.h,
                                                ),
                                            leading: Container(
                                              width: 36.w,
                                              height: 36.w,
                                              decoration: BoxDecoration(
                                                color: isCurrentVideo
                                                    ? AppColors.primary
                                                    : Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                              child: Center(
                                                child: isCurrentVideo
                                                    ? Icon(
                                                        Icons.play_arrow,
                                                        color: Colors.white,
                                                        size: 20.sp,
                                                      )
                                                    : Text(
                                                        '${localIndex + 1}',
                                                        style: TextStyle(
                                                          fontSize: 13.sp,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            title: Text(
                                              video['title'] ??
                                                  'Video ${localIndex + 1}',
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: isCurrentVideo
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                                color: isCurrentVideo
                                                    ? AppColors.primary
                                                    : AppColors.textPrimary,
                                              ),
                                            ),
                                            subtitle: Text(
                                              _formatDuration(
                                                video['duration'],
                                              ),
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            trailing: isCurrentVideo
                                                ? Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8.w,
                                                          vertical: 4.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4.r,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Ko\'rilmoqda',
                                                      style: TextStyle(
                                                        fontSize: 9.sp,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                            onTap: () =>
                                                _selectVideo(globalIndex),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                                );
                              },
                            )
                          : ListView.separated(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              itemCount: widget.videos!.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, index) {
                                final video = widget.videos![index];
                                final isCurrentVideo =
                                    index == _currentVideoIndex;

                                return ListTile(
                                  selected: isCurrentVideo,
                                  selectedTileColor: AppColors.primary
                                      .withOpacity(0.08),
                                  leading: Container(
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(
                                      color: isCurrentVideo
                                          ? AppColors.primary
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Center(
                                      child: isCurrentVideo
                                          ? Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                              size: 24.sp,
                                            )
                                          : Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    video['title'] ?? 'Video ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: isCurrentVideo
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isCurrentVideo
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatDuration(video['duration']),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: isCurrentVideo
                                      ? Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 4.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              4.r,
                                            ),
                                          ),
                                          child: Text(
                                            'Ko\'rilmoqda',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                  onTap: () => _selectVideo(index),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
