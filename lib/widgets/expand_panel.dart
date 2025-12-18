import 'package:flutter/material.dart';

class ExpandPanel extends StatefulWidget {
  final String title;
  final IconData? icon;
  final Widget child;
  final bool initiallyExpanded;
  final Widget? trailing;

  const ExpandPanel({
    super.key,
    required this.title,
    this.icon,
    required this.child,
    this.initiallyExpanded = false,
    this.trailing,
  });

  @override
  State<ExpandPanel> createState() => _ExpandPanelState();
}

class _ExpandPanelState extends State<ExpandPanel> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: ExpansionTile(
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: widget.icon != null
            ? Icon(
                widget.icon,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.trailing != null) widget.trailing!,
            Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        initiallyExpanded: widget.initiallyExpanded,
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

