import 'package:flutter/material.dart';

/// 접을 수 있는 피드백 패널 위젯
class CollapsibleFeedbackPanel extends StatefulWidget {
  final List<String> feedbacks;

  const CollapsibleFeedbackPanel({
    Key? key,
    required this.feedbacks,
  }) : super(key: key);

  @override
  State<CollapsibleFeedbackPanel> createState() => _CollapsibleFeedbackPanelState();
}

class _CollapsibleFeedbackPanelState extends State<CollapsibleFeedbackPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.feedbacks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 토글 버튼
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.feedback,
                  color: Colors.white70,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '피드백 ${widget.feedbacks.length}개',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        
        // 피드백 내용 (접혔을 때 숨김)
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.feedbacks.map((feedback) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _getIconForFeedback(feedback),
                        color: _getColorForFeedback(feedback),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feedback,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getIconForFeedback(String feedback) {
    if (feedback.contains('완벽') || feedback.contains('✓') || feedback.contains('완료')) {
      return Icons.check_circle;
    } else if (feedback.contains('⚠') || feedback.contains('잘못')) {
      return Icons.warning;
    } else if (feedback.contains('좋습니다')) {
      return Icons.thumb_up;
    } else if (feedback.contains('준비') || feedback.contains('⏳')) {
      return Icons.timer;
    } else {
      return Icons.info;
    }
  }

  Color _getColorForFeedback(String feedback) {
    if (feedback.contains('완벽') || feedback.contains('✓') || feedback.contains('완료')) {
      return Colors.green;
    } else if (feedback.contains('⚠') || feedback.contains('잘못')) {
      return Colors.red;
    } else if (feedback.contains('좋습니다')) {
      return Colors.lightGreen;
    } else if (feedback.contains('준비') || feedback.contains('⏳')) {
      return Colors.blue;
    } else {
      return Colors.amber;
    }
  }
}


