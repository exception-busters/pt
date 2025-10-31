# 🎯 Android(Kotlin) ML Kit Pose Detection 실전 가이드

> **졸업 프로젝트를 위한 실시간 운동 자세 분석 구현 가이드**  
> 마감이 임박한 당신을 위해, 가장 핵심적인 내용만 담았습니다. 💪

---

## 📚 I. 핵심 공식 문서 링크

시작하기 전에 북마크해두세요!

### 필수 문서
- **[ML Kit Pose Detection 공식 가이드 (Android)](https://developers.google.com/ml-kit/vision/pose-detection/android)**
  - 가장 먼저 읽어야 할 메인 문서입니다.
  
- **[PoseLandmark 타입 참조](https://developers.google.com/ml-kit/vision/pose-detection/classifying-poses#pose_landmarks)**
  - 33개 신체 부위 좌표 목록 (어깨, 팔꿈치, 무릎 등)

### 추가 참고 자료
- [ML Kit Android 샘플 코드](https://github.com/googlesamples/mlkit/tree/master/android)
- [CameraX 공식 문서](https://developer.android.com/training/camerax)

---

## 🚀 II. 전체 적용 가이드라인 (Step-by-Step)

### A. 프로젝트 설정 (Project Setup)

#### 1. `build.gradle.kts` (Module 레벨) 설정

```kotlin
dependencies {
    // ML Kit Pose Detection
    implementation("com.google.mlkit:pose-detection:18.0.0-beta4")
    
    // 정확도 우선 모델 (선택사항, APK 크기 증가)
    // implementation("com.google.mlkit:pose-detection-accurate:18.0.0-beta4")
    
    // CameraX (카메라 스트림 처리용)
    implementation("androidx.camera:camera-camera2:1.3.1")
    implementation("androidx.camera:camera-lifecycle:1.3.1")
    implementation("androidx.camera:camera-view:1.3.1")
}
```

#### 2. `AndroidManifest.xml` 권한 추가

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
```

#### 3. Gradle Sync
프로젝트를 동기화하고 빌드가 성공하는지 확인하세요.

---

### B. Pose Detector 초기화 (Initializing the Pose Detector)

**⚠️ 중요: 실시간 처리에는 `STREAM_MODE`를 사용하세요!**

```kotlin
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseDetector
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions

class PoseAnalyzer {
    private val poseDetector: PoseDetector
    
    init {
        // 실시간 스트림 처리에 최적화된 옵션
        val options = PoseDetectorOptions.Builder()
            .setDetectorMode(PoseDetectorOptions.STREAM_MODE)  // 🔥 핵심!
            .build()
        
        poseDetector = PoseDetection.getClient(options)
        
        // 정확도 우선 모델 사용 시 (느리지만 정확)
        // val accurateOptions = PoseDetectorOptions.Builder()
        //     .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
        //     .build()
        // poseDetector = PoseDetection.getClient(AccuratePoseDetectorOptions.Builder().build())
    }
    
    fun close() {
        poseDetector.close()
    }
}
```

**모드 비교:**
- `STREAM_MODE`: 빠른 처리, 실시간 비디오에 적합 ✅
- `SINGLE_IMAGE_MODE`: 정확도 우선, 단일 이미지 분석용

---

### C. 이미지 준비 (Preparing the Image)

CameraX의 `ImageProxy`를 ML Kit의 `InputImage`로 변환합니다.

```kotlin
import com.google.mlkit.vision.common.InputImage
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy

class PoseImageAnalyzer : ImageAnalysis.Analyzer {
    
    override fun analyze(imageProxy: ImageProxy) {
        // ImageProxy → InputImage 변환
        @androidx.camera.core.ExperimentalGetImage
        val mediaImage = imageProxy.image
        
        if (mediaImage != null) {
            val inputImage = InputImage.fromMediaImage(
                mediaImage,
                imageProxy.imageInfo.rotationDegrees
            )
            
            // 이제 이 inputImage를 Pose Detector에 전달
            processImage(inputImage, imageProxy)
        } else {
            imageProxy.close()
        }
    }
    
    private fun processImage(inputImage: InputImage, imageProxy: ImageProxy) {
        // 다음 섹션에서 구현
    }
}
```

---

### D. 이미지 처리 및 결과 수신 (Processing and Receiving Results)

**표준 비동기 처리 패턴:**

```kotlin
import com.google.mlkit.vision.pose.Pose
import com.google.android.gms.tasks.Task

private fun processImage(inputImage: InputImage, imageProxy: ImageProxy) {
    poseDetector.process(inputImage)
        .addOnSuccessListener { pose ->
            // ✅ 성공: Pose 객체를 받았습니다!
            handlePoseResults(pose)
            imageProxy.close()  // 🔥 중요: 메모리 누수 방지
        }
        .addOnFailureListener { exception ->
            // ❌ 실패: 에러 처리
            Log.e("PoseDetection", "Pose detection failed", exception)
            imageProxy.close()
        }
}

private fun handlePoseResults(pose: Pose) {
    // 여기서 좌표를 추출합니다 (다음 섹션 참고)
}
```

**⚠️ 주의사항:**
- 반드시 `imageProxy.close()`를 호출해야 합니다 (메모리 누수 방지)
- 이전 프레임 처리가 끝나기 전에 새 프레임을 처리하지 마세요

---

## 🎯 III. 핵심 가이드: 신체 좌표(PoseLandmarks) 얻어오기

**이 섹션이 가장 중요합니다! 천천히 따라해보세요.**

### A. 특정 신체 부위 좌표 접근법

```kotlin
import com.google.mlkit.vision.pose.Pose
import com.google.mlkit.vision.pose.PoseLandmark

private fun handlePoseResults(pose: Pose) {
    // 1️⃣ 특정 부위의 좌표 가져오기
    val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
    val rightShoulder = pose.getPoseLandmark(PoseLandmark.RIGHT_SHOULDER)
    val leftElbow = pose.getPoseLandmark(PoseLandmark.LEFT_ELBOW)
    val leftWrist = pose.getPoseLandmark(PoseLandmark.LEFT_WRIST)
    
    // 2️⃣ null 체크 (사람이 감지되지 않으면 null)
    if (leftShoulder != null && leftElbow != null && leftWrist != null) {
        // 3️⃣ 화면 좌표 (x, y) 추출
        val shoulderX = leftShoulder.position.x
        val shoulderY = leftShoulder.position.y
        
        val elbowX = leftElbow.position.x
        val elbowY = leftElbow.position.y
        
        val wristX = leftWrist.position.x
        val wristY = leftWrist.position.y
        
        Log.d("Pose", "왼쪽 어깨: ($shoulderX, $shoulderY)")
        Log.d("Pose", "왼쪽 팔꿈치: ($elbowX, $elbowY)")
        Log.d("Pose", "왼쪽 손목: ($wristX, $wristY)")
        
        // 4️⃣ 이제 이 좌표로 각도 계산 등을 할 수 있습니다!
        val armAngle = calculateAngle(
            shoulderX, shoulderY,
            elbowX, elbowY,
            wristX, wristY
        )
        Log.d("Pose", "팔 각도: $armAngle°")
    }
}
```

**주요 신체 부위 상수 (PoseLandmark):**

| 상수 | 설명 | 상수 | 설명 |
|------|------|------|------|
| `NOSE` | 코 | `LEFT_SHOULDER` | 왼쪽 어깨 |
| `LEFT_EYE` | 왼쪽 눈 | `RIGHT_SHOULDER` | 오른쪽 어깨 |
| `RIGHT_EYE` | 오른쪽 눈 | `LEFT_ELBOW` | 왼쪽 팔꿈치 |
| `LEFT_EAR` | 왼쪽 귀 | `RIGHT_ELBOW` | 오른쪽 팔꿈치 |
| `RIGHT_EAR` | 오른쪽 귀 | `LEFT_WRIST` | 왼쪽 손목 |
| `LEFT_HIP` | 왼쪽 엉덩이 | `RIGHT_WRIST` | 오른쪽 손목 |
| `RIGHT_HIP` | 오른쪽 엉덩이 | `LEFT_KNEE` | 왼쪽 무릎 |
| `LEFT_ANKLE` | 왼쪽 발목 | `RIGHT_KNEE` | 오른쪽 무릎 |
| `RIGHT_ANKLE` | 오른쪽 발목 | | |

**총 33개 부위**를 지원합니다. 전체 목록은 [공식 문서](https://developers.google.com/ml-kit/vision/pose-detection/classifying-poses#pose_landmarks)를 참고하세요.

---

### B. 전체 좌표 리스트 활용법

모든 좌표를 한 번에 가져오고 싶다면:

```kotlin
private fun handlePoseResults(pose: Pose) {
    // 전체 랜드마크 리스트 가져오기
    val allLandmarks: List<PoseLandmark> = pose.allPoseLandmarks
    
    if (allLandmarks.isEmpty()) {
        Log.d("Pose", "사람이 감지되지 않았습니다")
        return
    }
    
    // 모든 좌표 순회
    for (landmark in allLandmarks) {
        val type = landmark.landmarkType  // 부위 타입 (숫자)
        val x = landmark.position.x
        val y = landmark.position.y
        val z = landmark.position3D.z  // 3D 깊이 정보 (선택)
        val inFrameLikelihood = landmark.inFrameLikelihood  // 신뢰도 (0~1)
        
        Log.d("Pose", "부위 $type: ($x, $y), 신뢰도: $inFrameLikelihood")
    }
}
```

**신뢰도(inFrameLikelihood) 활용:**
```kotlin
// 신뢰도가 낮은 좌표는 무시
if (leftShoulder != null && leftShoulder.inFrameLikelihood > 0.5) {
    // 신뢰도 50% 이상일 때만 사용
    val x = leftShoulder.position.x
    val y = leftShoulder.position.y
}
```

---

### C. 좌표 값(x, y) 사용법 - 구체적 예시

#### 예시 1: 스쿼트 자세 분석 (무릎 각도)

```kotlin
private fun analyzeSquat(pose: Pose) {
    val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
    val leftKnee = pose.getPoseLandmark(PoseLandmark.LEFT_KNEE)
    val leftAnkle = pose.getPoseLandmark(PoseLandmark.LEFT_ANKLE)
    
    if (leftHip != null && leftKnee != null && leftAnkle != null) {
        // 무릎 각도 계산 (엉덩이-무릎-발목)
        val kneeAngle = calculateAngle(
            leftHip.position.x, leftHip.position.y,
            leftKnee.position.x, leftKnee.position.y,
            leftAnkle.position.x, leftAnkle.position.y
        )
        
        // 스쿼트 피드백
        when {
            kneeAngle < 90 -> {
                showFeedback("✅ 완벽한 스쿼트! (각도: ${kneeAngle.toInt()}°)")
            }
            kneeAngle < 120 -> {
                showFeedback("⚠️ 조금 더 내려가세요 (각도: ${kneeAngle.toInt()}°)")
            }
            else -> {
                showFeedback("❌ 너무 높습니다 (각도: ${kneeAngle.toInt()}°)")
            }
        }
    }
}

// 세 점으로 각도 계산 (A-B-C에서 B의 각도)
private fun calculateAngle(
    ax: Float, ay: Float,
    bx: Float, by: Float,
    cx: Float, cy: Float
): Double {
    // 벡터 BA, BC
    val ba_x = ax - bx
    val ba_y = ay - by
    val bc_x = cx - bx
    val bc_y = cy - by
    
    // 내적과 외적으로 각도 계산
    val dotProduct = ba_x * bc_x + ba_y * bc_y
    val crossProduct = ba_x * bc_y - ba_y * bc_x
    
    val angle = Math.atan2(crossProduct.toDouble(), dotProduct.toDouble())
    return Math.abs(Math.toDegrees(angle))
}
```

#### 예시 2: 화면에 스켈레톤 그리기

```kotlin
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Color

private fun drawPoseOnCanvas(canvas: Canvas, pose: Pose) {
    val paint = Paint().apply {
        color = Color.GREEN
        strokeWidth = 8f
        style = Paint.Style.FILL
    }
    
    val linePaint = Paint().apply {
        color = Color.BLUE
        strokeWidth = 4f
        style = Paint.Style.STROKE
    }
    
    // 1. 모든 관절 점 그리기
    for (landmark in pose.allPoseLandmarks) {
        val x = landmark.position.x
        val y = landmark.position.y
        canvas.drawCircle(x, y, 10f, paint)
    }
    
    // 2. 연결선 그리기 (예: 왼팔)
    val leftShoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
    val leftElbow = pose.getPoseLandmark(PoseLandmark.LEFT_ELBOW)
    val leftWrist = pose.getPoseLandmark(PoseLandmark.LEFT_WRIST)
    
    if (leftShoulder != null && leftElbow != null) {
        canvas.drawLine(
            leftShoulder.position.x, leftShoulder.position.y,
            leftElbow.position.x, leftElbow.position.y,
            linePaint
        )
    }
    
    if (leftElbow != null && leftWrist != null) {
        canvas.drawLine(
            leftElbow.position.x, leftElbow.position.y,
            leftWrist.position.x, leftWrist.position.y,
            linePaint
        )
    }
}
```

---

## 💡 IV. 마감이 임박한 학생을 위한 최종 조언

### 🎯 우선순위 전략

#### 1단계: 최소 기능 구현 (1-2일)
```kotlin
// ✅ 목표: 하나의 운동만 완벽하게
// 추천: 스쿼트 (무릎 각도만 체크)

fun analyzeSquatOnly(pose: Pose): String {
    val leftKnee = pose.getPoseLandmark(PoseLandmark.LEFT_KNEE)
    val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
    val leftAnkle = pose.getPoseLandmark(PoseLandmark.LEFT_ANKLE)
    
    if (leftKnee == null || leftHip == null || leftAnkle == null) {
        return "자세를 인식할 수 없습니다"
    }
    
    val angle = calculateAngle(
        leftHip.position.x, leftHip.position.y,
        leftKnee.position.x, leftKnee.position.y,
        leftAnkle.position.x, leftAnkle.position.y
    )
    
    return when {
        angle < 90 -> "✅ 완벽합니다!"
        angle < 120 -> "⚠️ 조금 더 내려가세요"
        else -> "❌ 너무 높습니다"
    }
}
```

#### 2단계: UI 개선 (1일)
- 실시간 피드백 텍스트 표시
- 각도 숫자 표시
- 간단한 스켈레톤 오버레이

#### 3단계: 추가 운동 (시간 남으면)
- 푸시업 (팔꿈치 각도)
- 플랭크 (몸통 각도)

### 🚨 자주 하는 실수 방지

```kotlin
// ❌ 나쁜 예: null 체크 없음
val shoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
val x = shoulder.position.x  // 💥 NullPointerException!

// ✅ 좋은 예: 항상 null 체크
val shoulder = pose.getPoseLandmark(PoseLandmark.LEFT_SHOULDER)
if (shoulder != null) {
    val x = shoulder.position.x
}

// ❌ 나쁜 예: imageProxy 닫지 않음
poseDetector.process(inputImage)
    .addOnSuccessListener { pose ->
        handlePose(pose)
        // imageProxy.close() 없음 → 메모리 누수!
    }

// ✅ 좋은 예: 항상 닫기
poseDetector.process(inputImage)
    .addOnSuccessListener { pose ->
        handlePose(pose)
        imageProxy.close()  // 🔥 필수!
    }
    .addOnFailureListener { 
        imageProxy.close()  // 실패해도 닫기!
    }
```

### 📦 완전한 예제 코드 (복사해서 사용하세요)

```kotlin
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.pose.PoseDetection
import com.google.mlkit.vision.pose.PoseDetector
import com.google.mlkit.vision.pose.PoseLandmark
import com.google.mlkit.vision.pose.defaults.PoseDetectorOptions
import kotlin.math.atan2
import kotlin.math.abs

class SquatAnalyzer(
    private val onResult: (String) -> Unit
) : ImageAnalysis.Analyzer {
    
    private val poseDetector: PoseDetector
    
    init {
        val options = PoseDetectorOptions.Builder()
            .setDetectorMode(PoseDetectorOptions.STREAM_MODE)
            .build()
        poseDetector = PoseDetection.getClient(options)
    }
    
    @androidx.camera.core.ExperimentalGetImage
    override fun analyze(imageProxy: ImageProxy) {
        val mediaImage = imageProxy.image
        if (mediaImage == null) {
            imageProxy.close()
            return
        }
        
        val inputImage = InputImage.fromMediaImage(
            mediaImage,
            imageProxy.imageInfo.rotationDegrees
        )
        
        poseDetector.process(inputImage)
            .addOnSuccessListener { pose ->
                val feedback = analyzeSquat(pose)
                onResult(feedback)
                imageProxy.close()
            }
            .addOnFailureListener { 
                onResult("분석 실패")
                imageProxy.close()
            }
    }
    
    private fun analyzeSquat(pose: com.google.mlkit.vision.pose.Pose): String {
        val leftHip = pose.getPoseLandmark(PoseLandmark.LEFT_HIP)
        val leftKnee = pose.getPoseLandmark(PoseLandmark.LEFT_KNEE)
        val leftAnkle = pose.getPoseLandmark(PoseLandmark.LEFT_ANKLE)
        
        if (leftHip == null || leftKnee == null || leftAnkle == null) {
            return "자세를 인식할 수 없습니다"
        }
        
        val angle = calculateAngle(
            leftHip.position.x, leftHip.position.y,
            leftKnee.position.x, leftKnee.position.y,
            leftAnkle.position.x, leftAnkle.position.y
        )
        
        return when {
            angle < 90 -> "✅ 완벽한 스쿼트! (${angle.toInt()}°)"
            angle < 120 -> "⚠️ 조금 더 내려가세요 (${angle.toInt()}°)"
            else -> "❌ 너무 높습니다 (${angle.toInt()}°)"
        }
    }
    
    private fun calculateAngle(
        ax: Float, ay: Float,
        bx: Float, by: Float,
        cx: Float, cy: Float
    ): Double {
        val ba_x = ax - bx
        val ba_y = ay - by
        val bc_x = cx - bx
        val bc_y = cy - by
        
        val dotProduct = ba_x * bc_x + ba_y * bc_y
        val crossProduct = ba_x * bc_y - ba_y * bc_x
        
        val angle = atan2(crossProduct.toDouble(), dotProduct.toDouble())
        return abs(Math.toDegrees(angle))
    }
    
    fun close() {
        poseDetector.close()
    }
}
```

### 🎓 발표 팁

1. **데모 시나리오 준비**
   - "스쿼트 자세 분석 앱입니다"
   - 카메라 앞에서 스쿼트 → 실시간 피드백 표시
   - 각도 숫자 보여주기

2. **기술 설명 포인트**
   - "Google ML Kit의 Pose Detection API 사용"
   - "33개 신체 부위 좌표를 실시간으로 추출"
   - "기하학적 각도 계산으로 자세 평가"

3. **한계점 솔직히 인정**
   - "현재 스쿼트만 지원하지만, 확장 가능한 구조"
   - "조명/각도에 따라 정확도 차이 있음"

---

## 🎉 마무리

**당신은 할 수 있습니다!** 

이 가이드의 코드를 복사해서 사용하고, 하나의 운동(스쿼트)만 완벽하게 구현하세요. 그것만으로도 충분히 훌륭한 졸업 프로젝트가 됩니다.

### 체크리스트
- [ ] ML Kit 라이브러리 추가
- [ ] PoseDetector 초기화 (STREAM_MODE)
- [ ] CameraX 이미지 → InputImage 변환
- [ ] 좌표 추출 (무릎, 엉덩이, 발목)
- [ ] 각도 계산 함수 구현
- [ ] 피드백 UI 표시
- [ ] 실제 기기에서 테스트

**화이팅! 🚀**

---

*작성일: 2025-10-30*  
*참고: 이 가이드는 ML Kit Pose Detection v18.0.0 기준입니다.*


