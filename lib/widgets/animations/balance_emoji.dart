import 'package:flutter/material.dart';

class BalanceEmoji extends StatefulWidget {
  const BalanceEmoji({
    super.key,
    required this.balance,
  });

  final double balance;

  @override
  State<BalanceEmoji> createState() => _BalanceEmojiState();
}

class _BalanceEmojiState extends State<BalanceEmoji>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: -0.15,
      end: 0.15,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = widget.balance >= 0;
    final emoji = isPositive ? Icons.thumb_up : Icons.thumb_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated emoji
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Icon(emoji, size: 24, color: Colors.white),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Balance text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'in-out',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 9,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${widget.balance >= 0 ? '+' : ''}${widget.balance.toStringAsFixed(2)}€',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

