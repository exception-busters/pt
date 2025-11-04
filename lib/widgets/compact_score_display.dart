import 'package:flutter/material.dart';
import '../services/feedback_generator.dart';

/// 컴팩트한 점수 표시 위젯 (최상단용)
class CompactScoreDisplay extends StatelessWidget {
  final double score;

  const CompactScoreDisplay({
    Key? key,
    required this.score,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: _getScoreColor(score),
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            '${score.toStringAsFixed(0)}점',
            style: TextStyle(
              color: _getScoreColor(score),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            FeedbackGenerator.getScoreLevel(score),
            style: TextStyle(
              color: _getScoreColor(score),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 90) return Colors.green;
    if (score >= 70) return Colors.lightGreen;
    if (score >= 50) return Colors.amber;
    return Colors.red;
  }
}



