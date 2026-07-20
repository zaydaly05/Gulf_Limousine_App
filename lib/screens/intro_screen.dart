import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    /// 🎥 Video setup
    _videoController =
    VideoPlayerController.asset("assets/videos/intro.mp4")
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0); // mute
        _videoController.play();
        setState(() {});
      });

    /// ✨ Fade animation
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _fadeController.forward();

    /// ⏭ Auto navigate after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      _goToLogin();
    });
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🎬 Background Video
          SizedBox.expand(
            child: _videoController.value.isInitialized
                ? FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController.value.size.width,
                height: _videoController.value.size.height,
                child: VideoPlayer(_videoController),
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ),

          /// 🌑 Dark luxury overlay
          Container(color: Colors.black.withOpacity(0.55)),

          /// 🚘 Center Branding
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.directions_car,
                      color: Colors.orange, size: 90),
                  SizedBox(height: 20),
                  Text(
                    "Gulf Limousine Travel",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Luxury Rides. Premium Experience.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),

          /// ⏭ Skip Button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _goToLogin,
              child: const Text("Skip",
                  style: TextStyle(color: Colors.white70)),
            ),
          )
        ],
      ),
    );
  }
}
