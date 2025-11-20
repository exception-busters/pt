import 'package:flutter/material.dart';
import 'package:flutter_application_1/color.dart';

/// 향상된 에러 위젯 - 사용자 친화적인 에러 메시지와 재시도 기능 제공
class AppErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String title;

  const AppErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.title = '문제가 발생했습니다',
  });

  /// 네트워크 에러용 팩토리 생성자
  factory AppErrorWidget.network({
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      icon: Icons.wifi_off,
      title: '네트워크 연결 실패',
      message: '인터넷 연결을 확인해주세요',
      onRetry: onRetry,
    );
  }

  /// 데이터 로딩 실패용 팩토리 생성자
  factory AppErrorWidget.dataLoadFailed({
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      icon: Icons.cloud_off,
      title: '데이터를 불러올 수 없습니다',
      message: message ?? '잠시 후 다시 시도해주세요',
      onRetry: onRetry,
    );
  }

  /// 권한 에러용 팩토리 생성자
  factory AppErrorWidget.permission({
    String? message,
    VoidCallback? onRetry,
  }) {
    return AppErrorWidget(
      icon: Icons.lock_outline,
      title: '권한이 필요합니다',
      message: message ?? '이 기능을 사용하려면 권한이 필요합니다',
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 에러 아이콘
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),

            // 에러 제목
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: mainButtonColor,
              ),
              textAlign: TextAlign.center,
            ),

            // 에러 메시지
            if (message != null) ...[
              const SizedBox(height: 12),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 재시도 버튼
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 간단한 에러 표시용 인라인 위젯
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              color: Colors.red.shade400,
              tooltip: '다시 시도',
            ),
          ],
        ],
      ),
    );
  }
}
