// 🚀 Const 최적화 예시
class OptimizedWidgets {
  // ❌ 기존 코드 (매번 새 인스턴스 생성)
  static Widget oldStyle() {
    return Container(
      padding: EdgeInsets.all(8), // const 누락
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '감지된 포즈: 0개',
        style: TextStyle( // const 누락
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ✅ 최적화된 코드 (const 활용)
  static Widget optimizedStyle() {
    return Container(
      padding: const EdgeInsets.all(8), // const 추가
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '감지된 포즈: 0개',
        style: TextStyle( // const 추가
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// 🚀 상수 정의로 재사용성 향상
class AppConstants {
  static const EdgeInsets defaultPadding = EdgeInsets.all(8);
  static const EdgeInsets statusPadding = EdgeInsets.all(8);
  static const EdgeInsets debugPadding = EdgeInsets.all(8);
  
  static const TextStyle statusTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle serverTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );
  
  static const TextStyle debugTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 12,
  );
  
  static const BoxDecoration statusDecoration = BoxDecoration(
    color: Colors.black54,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );
  
  static const BoxDecoration debugDecoration = BoxDecoration(
    color: Colors.black54,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );
}
