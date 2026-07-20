import 'package:flutter/material.dart';

class AnimatedCarCard extends StatelessWidget {
  final String image;
  final String name;
  final String price;
  final VoidCallback onTap;

  const AnimatedCarCard({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(
                  image,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(price,
                        style: const TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
