import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedAuthBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedAuthBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedAuthBackground> createState() => _AnimatedAuthBackgroundState();
}

class _AnimatedAuthBackgroundState extends State<AnimatedAuthBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _floatingController;
  
  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _controller2 = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat();
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _floatingController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.1),
                  Colors.white,
                  Theme.of(context).primaryColor.withOpacity(0.05),
                ],
              ),
            ),
          ),
          
          // Animated shapes
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: index == 0 ? _controller1 : _controller2,
              builder: (context, child) {
                final animation = index == 0 ? _controller1 : _controller2;
                return Positioned(
                  top: index * 200.0 - 100,
                  left: index.isEven ? -100 : null,
                  right: index.isOdd ? -100 : null,
                  child: Transform.rotate(
                    angle: animation.value * 2 * math.pi,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.1),
                            Theme.of(context).primaryColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Floating particles
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                return Positioned(
                  top: 100.0 + (index * 150),
                  left: 50.0 + (index * 60),
                  child: Transform.translate(
                    offset: Offset(
                      math.sin(_floatingController.value * math.pi) * 20,
                      math.cos(_floatingController.value * math.pi) * 20,
                    ),
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          // Child content
          widget.child,
        ],
      ),
    );
  }
}

// Animated wave painter for bottom decoration
class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  
  WavePainter({
    required this.animation,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, size.height);
    
    for (var i = 0; i <= size.width; i++) {
      final y = size.height * 0.8 +
          math.sin((i / size.width * 2 * math.pi) + (animation.value * 2 * math.pi)) * 20;
      path.lineTo(i.toDouble(), y);
    }
    
    path.lineTo(size.width, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}