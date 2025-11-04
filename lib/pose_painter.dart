import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'models/exercise_model.dart';

/// 포즈 스켈레톤 렌더링을 위한 CustomPainter
class PosePainter extends CustomPainter {
  final List<Pose> poses;           // 감지된 포즈 목록
  final Size imageSize;             // 원본 이미지 크기
  final ExerciseModel? exercise;    // 선택된 운동 (각도별 색상 표시용)

  PosePainter(this.poses, this.imageSize, {this.exercise});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 기본 선 스타일 설정 (뼈대 - 연한 회색)
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeCap = StrokeCap.round;

    // 2. 점 스타일 설정 (관절)
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    // 3. 각 포즈에 대해 그리기
    for (final pose in poses) {
      // 3-1. 기본 스켈레톤 그리기 (연한 색상)
      _drawBaseSkeleton(canvas, basePaint, pose, imageSize, size);

      // 3-2. 운동이 선택되었다면, 각도별로 강조 표시
      if (exercise != null) {
        _drawAngleHighlights(canvas, pose, imageSize, size);
      }

      // 3-3. 몸 랜드마크에만 점 그리기 (얼굴 제외)
      _drawBodyLandmarks(canvas, circlePaint, pose, imageSize, size);
    }
  }

  /// 기본 스켈레톤 그리기 (연한 회색)
  void _drawBaseSkeleton(
    Canvas canvas,
    Paint paint,
    Pose pose,
    Size inputImageSize,
    Size size
  ) {
    // 몸통 연결
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, 
      inputImageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, 
      inputImageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, 
      inputImageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, 
      inputImageSize, size);
    
    // 왼팔
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, 
      inputImageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, 
      inputImageSize, size);
    
    // 오른팔
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, 
      inputImageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, 
      inputImageSize, size);
    
    // 왼다리
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, 
      inputImageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, 
      inputImageSize, size);
    
    // 오른다리
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, 
      inputImageSize, size);
    _drawConnection(canvas, paint, pose, 
      PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, 
      inputImageSize, size);
  }

  /// 각도별 강조 표시 (각 각도마다 다른 색상)
  void _drawAngleHighlights(
    Canvas canvas,
    Pose pose,
    Size inputImageSize,
    Size size
  ) {
    if (exercise == null) return;

    // 각 key_angle마다 고유한 색상 할당
    final angleColors = _getAngleColors();
    
    int angleIndex = 0;
    for (var entry in exercise!.keyAngles.entries) {
      final angleKey = entry.key;
      final angleInfo = entry.value;
      final points = angleInfo.points;
      
      if (points.length != 3) continue;

      // 각도에 할당된 색상 가져오기
      final color = angleColors[angleKey] ?? _getColorByIndex(angleIndex);
      
      // 두꺼운 선 스타일
      final anglePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..color = color
        ..strokeCap = StrokeCap.round;

      // 3점을 연결하는 2개의 선 그리기
      _drawAngleLine(canvas, anglePaint, pose, points[0], points[1], inputImageSize, size);
      _drawAngleLine(canvas, anglePaint, pose, points[1], points[2], inputImageSize, size);

      angleIndex++;
    }
  }

  /// 각도별 고유 색상 정의
  /// 같은 angle key는 어떤 운동에서든 동일한 색상 사용
  Map<String, Color> _getAngleColors() {
    return {
      // Body tilt angles
      'left_body_tilt': Colors.green.shade400,
      'right_body_tilt': Colors.pink.shade400,
      
      // Elbow angles
      'left_elbow_angle': Colors.blue.shade400,
      'right_elbow_angle': Colors.orange.shade400,
      
      // Knee angles (일반)
      'left_knee_angle': Colors.purple.shade400,
      'right_knee_angle': Colors.teal.shade400,
      
      // Knee angles (특정 동작용)
      'front_knee_angle': Colors.amber.shade600,
      'back_knee_angle': Colors.lightGreen.shade400,
      'knee_angle_left': Colors.cyan.shade400,
      'knee_angle_right': Colors.lime.shade400,
      
      // Hip flexion
      'left_hip_flexion': Colors.lime.shade400,
      'right_hip_flexion': Colors.deepOrange.shade400,
      
      // Hip angles (일반)
      'left_hip_angle': Colors.deepPurple.shade400,
      'right_hip_angle': Colors.lightBlue.shade400,
      
      // Hip angles (특정 동작용)
      'front_hip_angle': Colors.pink.shade300,
      'back_hip_angle': Colors.cyan.shade300,
      'hip_angle_left': Colors.yellow.shade600,
      'hip_angle_right': Colors.red.shade400,
      
      // Shoulder angles
      'left_shoulder_angle': Colors.deepOrange.shade300,
      'right_shoulder_angle': Colors.teal.shade300,
      
      // Back and torso
      'back_angle': Colors.indigo.shade400,
      'torso_forward_bend': Colors.amber.shade400,
    };
  }

  /// 인덱스 기반 색상 생성 (정의되지 않은 각도용)
  Color _getColorByIndex(int index) {
    final colors = [
      Colors.green.shade400,
      Colors.pink.shade400,
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.yellow.shade600,
      Colors.red.shade400,
      Colors.cyan.shade400,
      Colors.lime.shade400,
      Colors.indigo.shade400,
      Colors.amber.shade400,
    ];
    return colors[index % colors.length];
  }

  /// 각도를 구성하는 선 그리기 (랜드마크 이름으로)
  void _drawAngleLine(
    Canvas canvas,
    Paint paint,
    Pose pose,
    String landmark1Name,
    String landmark2Name,
    Size inputImageSize,
    Size size
  ) {
    final point1 = _getLandmarkByName(pose, landmark1Name);
    final point2 = _getLandmarkByName(pose, landmark2Name);

    if (point1 != null && point2 != null) {
      final offset1 = _translatePoint(point1.x, point1.y, inputImageSize, size);
      final offset2 = _translatePoint(point2.x, point2.y, inputImageSize, size);
      canvas.drawLine(offset1, offset2, paint);
    }
  }

  /// 랜드마크 이름으로 PoseLandmark 가져오기
  PoseLandmark? _getLandmarkByName(Pose pose, String name) {
    // 직접 매핑
    final directMap = {
      'Nose': PoseLandmarkType.nose,
      'Left Shoulder': PoseLandmarkType.leftShoulder,
      'Right Shoulder': PoseLandmarkType.rightShoulder,
      'Left Elbow': PoseLandmarkType.leftElbow,
      'Right Elbow': PoseLandmarkType.rightElbow,
      'Left Wrist': PoseLandmarkType.leftWrist,
      'Right Wrist': PoseLandmarkType.rightWrist,
      'Left Hip': PoseLandmarkType.leftHip,
      'Right Hip': PoseLandmarkType.rightHip,
      'Left Knee': PoseLandmarkType.leftKnee,
      'Right Knee': PoseLandmarkType.rightKnee,
      'Left Ankle': PoseLandmarkType.leftAnkle,
      'Right Ankle': PoseLandmarkType.rightAnkle,
    };

    if (directMap.containsKey(name)) {
      return pose.landmarks[directMap[name]];
    }

    // 복합 랜드마크 (중점 계산)
    switch (name) {
      case 'Neck':
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        if (leftShoulder != null && rightShoulder != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2,
            z: (leftShoulder.z + rightShoulder.z) / 2,
            likelihood: (leftShoulder.likelihood + rightShoulder.likelihood) / 2,
          );
        }
        break;

      case 'Back':
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        
        if (leftShoulder != null && rightShoulder != null && 
            leftHip != null && rightHip != null) {
          final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;
          final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
          final shoulderMidZ = (leftShoulder.z + rightShoulder.z) / 2;
          
          final hipMidX = (leftHip.x + rightHip.x) / 2;
          final hipMidY = (leftHip.y + rightHip.y) / 2;
          final hipMidZ = (leftHip.z + rightHip.z) / 2;
          
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (shoulderMidX + hipMidX) / 2,
            y: (shoulderMidY + hipMidY) / 2,
            z: (shoulderMidZ + hipMidZ) / 2,
            likelihood: (leftShoulder.likelihood + rightShoulder.likelihood + 
                        leftHip.likelihood + rightHip.likelihood) / 4,
          );
        }
        break;

      case 'Waist':
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        if (leftHip != null && rightHip != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2,
            z: (leftHip.z + rightHip.z) / 2,
            likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
          );
        }
        break;

      case 'Shoulder':
        final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
        final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
        if (leftShoulder != null && rightShoulder != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftShoulder.x + rightShoulder.x) / 2,
            y: (leftShoulder.y + rightShoulder.y) / 2,
            z: (leftShoulder.z + rightShoulder.z) / 2,
            likelihood: (leftShoulder.likelihood + rightShoulder.likelihood) / 2,
          );
        }
        break;

      case 'Hip':
        final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
        final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
        if (leftHip != null && rightHip != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftHip.x + rightHip.x) / 2,
            y: (leftHip.y + rightHip.y) / 2,
            z: (leftHip.z + rightHip.z) / 2,
            likelihood: (leftHip.likelihood + rightHip.likelihood) / 2,
          );
        }
        break;

      case 'Knee':
        final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
        final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
        if (leftKnee != null && rightKnee != null) {
          return PoseLandmark(
            type: PoseLandmarkType.nose,
            x: (leftKnee.x + rightKnee.x) / 2,
            y: (leftKnee.y + rightKnee.y) / 2,
            z: (leftKnee.z + rightKnee.z) / 2,
            likelihood: (leftKnee.likelihood + rightKnee.likelihood) / 2,
          );
        }
        break;
    }

    return null;
  }

  /// 몸 랜드마크만 그리기 (얼굴 제외)
  void _drawBodyLandmarks(
    Canvas canvas,
    Paint paint,
    Pose pose,
    Size inputImageSize,
    Size size
  ) {
    // 몸통, 팔, 다리 랜드마크만 그리기 (얼굴 제외)
    final bodyLandmarkTypes = [
      // 어깨
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      // 팔꿈치
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      // 손목
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      // 엉덩이
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      // 무릎
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      // 발목
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (final type in bodyLandmarkTypes) {
      final landmark = pose.landmarks[type];
      if (landmark != null) {
        final translatedPoint = _translatePoint(
          landmark.x,
          landmark.y,
          inputImageSize,
          size,
        );
        canvas.drawCircle(translatedPoint, 8.0, paint);
      }
    }
  }

  /// 연결선 그리기
  void _drawConnection(
    Canvas canvas,
    Paint paint,
    Pose pose,
    PoseLandmarkType type1,
    PoseLandmarkType type2,
    Size inputImageSize,
    Size size
  ) {
    // 1. 두 랜드마크 가져오기
    final landmark1 = pose.landmarks[type1];
    final landmark2 = pose.landmarks[type2];

    // 2. 둘 다 존재할 때만 그리기
    if (landmark1 != null && landmark2 != null) {
      // 3. 좌표 변환
      final point1 = _translatePoint(landmark1.x, landmark1.y, inputImageSize, size);
      final point2 = _translatePoint(landmark2.x, landmark2.y, inputImageSize, size);
      
      // 4. 선 그리기
      canvas.drawLine(point1, point2, paint);
    }
  }

  /// 좌표 변환 (이미지 크기 → 캔버스 크기)
  Offset _translatePoint(double x, double y, Size inputImageSize, Size size) {
    // aspect ratio를 고려한 스케일 계산
    final double scaleX = size.width / inputImageSize.width;
    final double scaleY = size.height / inputImageSize.height;
    
    // 더 작은 스케일을 사용하여 이미지가 잘리지 않도록 함
    final double scale = scaleX < scaleY ? scaleX : scaleY;
    
    // 중앙 정렬을 위한 오프셋 계산
    final double offsetX = (size.width - inputImageSize.width * scale) / 2;
    final double offsetY = (size.height - inputImageSize.height * scale) / 2;
    
    return Offset(
      x * scale + offsetX,
      y * scale + offsetY,
    );
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses || 
           oldDelegate.imageSize != imageSize ||
           oldDelegate.exercise != exercise;
  }
}



