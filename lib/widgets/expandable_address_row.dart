import 'package:flutter/material.dart';

/// Multi-line address text with optional expand/collapse when it overflows.
class ExpandableAddressText extends StatefulWidget {
  final String text;
  final int collapsedLines;
  final TextStyle style;
  final Color actionColor;

  const ExpandableAddressText({
    super.key,
    required this.text,
    this.collapsedLines = 2,
    this.style = const TextStyle(
      fontWeight: FontWeight.w600,
      height: 1.35,
    ),
    this.actionColor = const Color(0xFFFF8C00),
  });

  @override
  State<ExpandableAddressText> createState() => _ExpandableAddressTextState();
}

class _ExpandableAddressTextState extends State<ExpandableAddressText> {
  bool _expanded = false;

  bool _exceedsCollapsedLines(double maxWidth, TextDirection textDirection) {
    if (widget.text.isEmpty || maxWidth <= 0) return false;

    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: widget.collapsedLines,
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);

    return painter.didExceedMaxLines;
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isExpandable = _exceedsCollapsedLines(
          constraints.maxWidth,
          textDirection,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              maxLines: _expanded ? null : widget.collapsedLines,
              overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
              softWrap: true,
              style: widget.style,
            ),
            if (isExpandable)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: widget.actionColor,
                  ),
                  onPressed: _toggleExpanded,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'See less' : 'See more',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Displays a label and multi-line address with optional expand/collapse.
class ExpandableAddressRow extends StatelessWidget {
  final String label;
  final String address;
  final IconData icon;
  final Color iconColor;
  final int collapsedLines;

  const ExpandableAddressRow({
    super.key,
    required this.label,
    required this.address,
    this.icon = Icons.place,
    this.iconColor = const Color(0xFFFF8C00),
    this.collapsedLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ExpandableAddressText(
                  text: address,
                  collapsedLines: collapsedLines,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
