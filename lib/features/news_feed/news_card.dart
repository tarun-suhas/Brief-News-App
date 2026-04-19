import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:news_app/generated/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../services/news_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/news_model.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class NewsCard extends StatefulWidget {
  final NewsModel newsItem;

  const NewsCard({super.key, required this.newsItem});

  @override
  State<NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<NewsCard> with SingleTickerProviderStateMixin {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;

  late AnimationController _heartController;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  bool _showHeart = false;
  
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  double _xOffset = 0;
  double _yOffset = 0;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initSensors();
    
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3).chain(CurveTween(curve: Curves.elasticOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartController);

    _heartOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartController);
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  void _initSensors() {
    _accelSubscription = accelerometerEventStream().listen((event) {
      if (mounted) {
        setState(() {
          // Multiply for intensity. Inverted to simulate viewing through a window
          _xOffset = -event.x * 3.0; 
          _yOffset = event.y * 3.0;
        });
      }
    }, onError: (error) {
       // Emulators without gyroscopes will throw an error here. 
       // We catch it so it doesn't crash the entire app.
       debugPrint("Sensors not available on this device: $error");
    });
  }

  @override
  void dispose() {
    _accelSubscription?.cancel();
    _flutterTts.stop();
    _heartController.dispose();
    super.dispose();
  }
  
  void _onDoubleTap() {
    final userId = context.read<AuthService>().currentUserData?.uid;
    if (userId == null) return;
    
    final isLiked = widget.newsItem.likes.contains(userId);
    if (!isLiked) {
      _toggleLike(userId, false);
    }
    
    // Play animation regardless of current like state to give feedback
    _playHeartAnimation();
  }

  void _playHeartAnimation() {
    HapticFeedback.mediumImpact();
    setState(() => _showHeart = true);
    _heartController.forward(from: 0.0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  Future<void> _toggleLike(String userId, bool isCurrentlyLiked) async {
    try {
      await context.read<NewsService>().toggleLike(widget.newsItem.id, userId, isCurrentlyLiked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
  
  void _toggleAudio() async {
    if (_isPlaying) {
      await _flutterTts.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (mounted) setState(() => _isPlaying = true);
      String textToRead = "${widget.newsItem.title}. ... ${widget.newsItem.content}";
      await _flutterTts.speak(textToRead);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthService>().currentUserData?.uid;
    final isLiked = userId != null && widget.newsItem.likes.contains(userId);

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
        // Background Layer with Cinematic Blur AND Parallax
        if (widget.newsItem.imageUrl.isNotEmpty) ...[
          // Scale it up by 1.1x so that translating doesn't reveal the white edges underneath
          Transform.scale(
            scale: 1.15,
            child: Transform.translate(
              offset: Offset(_xOffset, _yOffset),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.newsItem.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppColors.background),
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Container(color: AppColors.background.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
          ),
          
          // Foreground Crisp Image stays locked in position
          Image.network(
            widget.newsItem.imageUrl,
            fit: BoxFit.contain,
            alignment: const Alignment(0.0, -0.4),
          ),
        ] else
          Container(color: AppColors.background),

        // Deep Cinematic Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.background.withValues(alpha: 0.98),
                AppColors.background.withValues(alpha: 0.2),
                Colors.transparent,
                AppColors.background.withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),

        // Animated Pop Heart Over Image
        if (_showHeart)
          Center(
            child: AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Opacity(
                  opacity: _heartOpacity.value,
                  child: Transform.scale(
                    scale: _heartScale.value,
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.white, Colors.white.withValues(alpha: 0.8)],
                      ).createShader(bounds),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 100,
                        shadows: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        // Content
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 64.0, top: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.newsItem.isBreaking)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.breakingBadge,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.breakingBadge.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(AppLocalizations.of(context)!.breakingBadge, style: AppTextStyles.badge),
                    ),
                  ),
                ),
                
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like Counter & Button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (userId != null) {
                            HapticFeedback.lightImpact();
                            _toggleLike(userId, isLiked);
                          }
                        },
                        child: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.redAccent : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.newsItem.likes.length}',
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 14, 
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text-To-Speech Listen Button
                      GestureDetector(
                        onTap: _toggleAudio,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.stop : Icons.volume_up, 
                            color: AppColors.primary, 
                            size: 18
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(widget.newsItem.title, style: AppTextStyles.feedTitle),
              if (widget.newsItem.subtitle != null && widget.newsItem.subtitle!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  widget.newsItem.subtitle!,
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.textPrimary.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showFullArticle(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.newsItem.content,
                      style: AppTextStyles.feedContent,
                      maxLines: 7,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.of(context)!.tapToReadMore, style: AppTextStyles.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    ),
);
  }

  void _showFullArticle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: AppColors.surface.withValues(alpha: 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ListView(
                controller: scrollController,
                children: [
                   Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Text(widget.newsItem.title, style: AppTextStyles.h2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        timeago.format(widget.newsItem.createdAt, locale: Localizations.localeOf(context).languageCode),
                        style: AppTextStyles.subtitle.copyWith(color: AppColors.primary),
                      ),
                      if (widget.newsItem.readingTime != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.timer_outlined, color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.newsItem.readingTime} ${l10n.minRead}',
                          style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                        ),
                      ],
                      const Spacer(),
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.newsItem.likes.length}',
                        style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.newsItem.category, style: AppTextStyles.badge.copyWith(fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.newsItem.content,
                    style: AppTextStyles.body.copyWith(fontSize: 16, height: 1.6),
                  ),
                  if (widget.newsItem.sourceName != null) ...[
                    const SizedBox(height: 32),
                    Divider(color: AppColors.textSecondary.withValues(alpha: 0.1)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () async {
                        if (widget.newsItem.sourceUrl != null) {
                          final uri = Uri.parse(widget.newsItem.sourceUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Text(
                            '${l10n.readMoreAt} ',
                            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                          ),
                          Text(
                            widget.newsItem.sourceName!,
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              decoration: widget.newsItem.sourceUrl != null ? TextDecoration.underline : null,
                            ),
                          ),
                          if (widget.newsItem.sourceUrl != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
