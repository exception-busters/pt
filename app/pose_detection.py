import cv2
import mediapipe as mp
import json
import sys
import os

# MediaPipe Pose 모델 불러오기
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    enable_segmentation=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

# 그리기 유틸리티 불러오기
mp_drawing = mp.solutions.drawing_utils

def detect_pose_from_image(image_path):
    """
    이미지에서 포즈를 감지하고 결과를 JSON으로 반환
    """
    try:
        # 이미지 읽기
        image = cv2.imread(image_path)
        if image is None:
            return {"error": "이미지를 읽을 수 없습니다."}
        
        # BGR에서 RGB로 변환
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # 포즈 감지
        results = pose.process(image_rgb)
        
        # 결과 처리
        pose_data = {
            "landmarks": [],
            "connections": []
        }
        
        if results.pose_landmarks:
            # 랜드마크 추출
            for landmark in results.pose_landmarks.landmark:
                pose_data["landmarks"].append({
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "visibility": landmark.visibility
                })
            
            # 연결선 정보 (MediaPipe의 기본 연결선)
            connections = mp_pose.POSE_CONNECTIONS
            for connection in connections:
                pose_data["connections"].append({
                    "start": connection[0],
                    "end": connection[1]
                })
        
        return pose_data
        
    except Exception as e:
        return {"error": str(e)}

def detect_pose_from_camera():
    """
    카메라에서 실시간 포즈 감지 (Flutter에서 호출)
    """
    try:
        # 웹캠 열기 - 여러 카메라 인덱스 시도
        cap = None
        for i in range(3):  # 0, 1, 2번 카메라 시도
            test_cap = cv2.VideoCapture(i)
            if test_cap.isOpened():
                ret, frame = test_cap.read()
                if ret:
                    cap = test_cap
                    break
                else:
                    test_cap.release()
        
        if cap is None:
            # 카메라가 없을 때 더미 데이터 반환
            return {
                "landmarks": [],
                "connections": [],
                "message": "카메라를 찾을 수 없습니다. 더미 데이터를 반환합니다."
            }
        
        # 한 프레임 캡처
        success, image = cap.read()
        cap.release()
        
        if not success:
            return {"error": "카메라에서 프레임을 읽을 수 없습니다."}
        
        # BGR에서 RGB로 변환
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        
        # 포즈 감지
        results = pose.process(image_rgb)
        
        # 결과 처리
        pose_data = {
            "landmarks": [],
            "connections": []
        }
        
        if results.pose_landmarks:
            # 랜드마크 추출
            for landmark in results.pose_landmarks.landmark:
                pose_data["landmarks"].append({
                    "x": landmark.x,
                    "y": landmark.y,
                    "z": landmark.z,
                    "visibility": landmark.visibility
                })
            
            # 연결선 정보
            connections = mp_pose.POSE_CONNECTIONS
            for connection in connections:
                pose_data["connections"].append({
                    "start": connection[0],
                    "end": connection[1]
                })
        else:
            # 포즈가 감지되지 않았을 때 더미 데이터
            pose_data["message"] = "포즈가 감지되지 않았습니다."
        
        return pose_data
        
    except Exception as e:
        return {"error": f"카메라 처리 중 오류: {str(e)}"}

if __name__ == "__main__":
    # Flutter에서 호출할 때 사용
    if len(sys.argv) > 1:
        if sys.argv[1] == "camera":
            result = detect_pose_from_camera()
        else:
            result = detect_pose_from_image(sys.argv[1])
    else:
        result = detect_pose_from_camera()
    
    # JSON 결과 출력
    print(json.dumps(result, ensure_ascii=False))
