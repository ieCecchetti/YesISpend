import 'package:flutter/material.dart';

class HorizontalScrollText extends StatefulWidget {
  final String value;
  final int timeBeforerestart;
  final double pixelPerSecond;

  const HorizontalScrollText({
    Key? key,
    required this.value,
    this.timeBeforerestart = 1,
    this.pixelPerSecond = 10,
  }) : super(key: key);

  @override
  _HorizontalScrollTextState createState() => _HorizontalScrollTextState();
}

class _HorizontalScrollTextState extends State<HorizontalScrollText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _animation;
  bool _shouldScroll = false;

  double _textWidth = 0;
  double _containerWidth = 0;

  final GlobalKey _textKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // Wait until layout is built to get text width
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _containerWidth = context.size!.width;
      _textWidth = _calculateTextWidth(widget.value);

      if (_textWidth > _containerWidth) {
        _startScrollingAnimation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: ClipRect(
        child: _animation == null
            ? _buildStaticText()
            : AnimatedBuilder(
                animation: _animation!,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_animation!.value, 0),
                    child: child,
                  );
                },
                child: _buildScrollingText(),
              ),
      ),
    );
  }

  Widget _buildStaticText() {
    return Builder(
      builder: (context) => Text(
      widget.value,
      key: _textKey,
        style: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildScrollingText() {
    return Builder(
      builder: (context) => SizedBox(
      width: _textWidth,
      child: Text(
        widget.value,
          style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
        textAlign: TextAlign.left,
        softWrap: false,
        ),
      ),
    );
  }

  double _calculateTextWidth(String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16.0),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    return textPainter.width;
  }

  void _startScrollingAnimation() {
    final double scrollDistance = _textWidth - _containerWidth;
    final int durationSeconds = (scrollDistance / widget.pixelPerSecond).ceil();

    _controller.duration = Duration(seconds: durationSeconds);
    _animation = Tween<double>(
      begin: 0,
      end: -scrollDistance,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(Duration(seconds: widget.timeBeforerestart), () {
          if (mounted) {
            _controller.reset();
            _controller.forward();
          }
        });
      }
    });

    setState(() {
      _shouldScroll = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
