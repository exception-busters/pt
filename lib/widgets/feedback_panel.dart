import 'package:flutter/material.dart';

/// 피드백 패널 위젯
class FeedbackPanel extends StatelessWidget {
  final List<String> feedbacks;

  const FeedbackPanel({
    Key? key,
    required this.feedbacks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (feedbacks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '운동 자세를 선택하고 시작하세요',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: feedbacks.map((feedback) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _getIconForFeedback(feedback),
                  color: _getColorForFeedback(feedback),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feedback,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getIconForFeedback(String feedback) {
    if (feedback.contains('완벽') || feedback.contains('✓')) {
      return Icons.check_circle;
    } else if (feedback.contains('⚠') || feedback.contains('잘못')) {
      return Icons.warning;
    } else if (feedback.contains('좋습니다')) {
      return Icons.thumb_up;
    } else {
      return Icons.info;
    }
  }

  Color _getColorForFeedback(String feedback) {
    if (feedback.contains('완벽') || feedback.contains('✓')) {
      return Colors.green;
    } else if (feedback.contains('⚠') || feedback.contains('잘못')) {
      return Colors.red;
    } else if (feedback.contains('좋습니다')) {
      return Colors.lightGreen;
    } else {
      return Colors.amber;
    }
  }
}

