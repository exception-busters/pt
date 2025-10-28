import cv2
import mediapipe as mp
import json
import threading
import time
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# MediaPipe Pose 모델 불러오기
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=2,  # 더 정확한 모델 사용 (0, 1, 2 중 선택)
    enable_segmentation=False,
    min_detection_confidence=0.3,  # 감지 임계값 낮춤
    min_tracking_confidence=0.3   # 추적 임계값 낮춤
)

# 전역 변수
camera = None
is_running = False
latest_pose_data = {"landmarks": [], "connections": []}

def initialize_camera():
    """카메라 초기화"""
    global camera
    try:
        # 여러 카메라 인덱스 시도
        for i in range(3):
            test_cap = cv2.VideoCapture(i)
            if test_cap.isOpened():
                ret, frame = test_cap.read()
                if ret:
                    camera = test_cap
                    print(f"[OK] 카메라 {i}번을 사용합니다.")
                    print(f"[INFO] 카메라 해상도: {frame.shape[1]}x{frame.shape[0]}")
                    # 첫 프레임의 밝기 확인
                    avg_brightness = np.mean(frame)
                    print(f"[INFO] 평균 밝기: {avg_brightness:.2f}")
                    return True
                else:
                    test_cap.release()
                    print(f"[ERROR] 카메라 {i}번에서 프레임을 읽을 수 없습니다.")
            else:
                print(f"[ERROR] 카메라 {i}번을 열 수 없습니다.")
        
        print("[ERROR] 사용 가능한 카메라를 찾을 수 없습니다.")
        return False
    except Exception as e:
        print(f"[ERROR] 카메라 초기화 중 오류 발생: {e}")
        return False

def process_pose_detection():
    """실시간 포즈 감지 처리"""
    global latest_pose_data, is_running, camera
    
    if camera is None:
        print("[ERROR] process_pose_detection: 카메라가 초기화되지 않았습니다.")
        return

    print("[START] 포즈 감지 스레드 시작")
    frame_count = 0
    
    while is_running:
        try:
            success, image = camera.read()
            if not success:
                print("[ERROR] 프레임을 읽을 수 없습니다. 카메라 연결을 확인하세요.")
                time.sleep(0.1)
                continue

            frame_count += 1
            
            # 이미지 밝기 확인 (평균 픽셀 값)
            avg_brightness = np.mean(image)
            
            # 10프레임마다 상태 출력
            if frame_count % 10 == 0:
                print(f"[INFO] 프레임 {frame_count}: 평균 밝기 {avg_brightness:.2f}")
                
                if avg_brightness < 30:
                    print("[WARNING] 이미지가 너무 어둡습니다! 조명을 확인해주세요.")
                elif avg_brightness > 200:
                    print("[WARNING] 이미지가 너무 밝습니다! 과노출을 확인해주세요.")
                else:
                    print("[OK] 이미지 밝기가 적절합니다.")

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
                
                if frame_count % 30 == 0:  # 30프레임마다 성공 메시지
                    print(f"[SUCCESS] 포즈 감지 성공: {len(pose_data['landmarks'])}개 랜드마크 감지됨")
            else:
                if frame_count % 30 == 0:  # 30프레임마다 실패 메시지
                    print("[FAIL] 포즈 감지 실패: 랜드마크 없음")
            
            latest_pose_data = pose_data
            time.sleep(0.05)  # 감지 빈도 조절 (약 20 FPS)
            
        except Exception as e:
            print(f"[ERROR] 포즈 감지 처리 중 오류 발생: {e}")
            latest_pose_data = {"landmarks": [], "connections": []}
            time.sleep(0.1)
    
    print("[STOP] 포즈 감지 스레드 종료")

@app.route('/start', methods=['POST'])
def start_detection():
    """포즈 감지 시작"""
    global is_running, camera
    
    print("포즈 감지 시작 요청 받음")
    
    if not is_running:
        print("카메라 초기화 시도...")
        if initialize_camera():
            is_running = True
            print("카메라 초기화 성공, 포즈 감지 시작")
            # 백그라운드에서 포즈 감지 실행
            thread = threading.Thread(target=process_pose_detection)
            thread.daemon = True
            thread.start()
            return jsonify({"status": "started", "message": "포즈 감지가 시작되었습니다."})
        else:
            print("카메라 초기화 실패")
            return jsonify({"status": "error", "message": "카메라를 초기화할 수 없습니다."})
    else:
        print("이미 실행 중")
        return jsonify({"status": "running", "message": "이미 실행 중입니다."})

@app.route('/stop', methods=['POST'])
def stop_detection():
    """포즈 감지 중지"""
    global is_running, camera
    
    is_running = False
    if camera is not None:
        camera.release()
        camera = None
    
    return jsonify({"status": "stopped", "message": "포즈 감지가 중지되었습니다."})

@app.route('/pose', methods=['GET'])
def get_pose():
    """현재 포즈 데이터 반환"""
    print(f"포즈 데이터 요청: {len(latest_pose_data.get('landmarks', []))}개 랜드마크")
    return jsonify(latest_pose_data)

@app.route('/status', methods=['GET'])
def get_status():
    """서버 상태 반환"""
    return jsonify({
        "is_running": is_running,
        "camera_available": camera is not None,
        "latest_pose_count": len(latest_pose_data.get("landmarks", []))
    })

if __name__ == '__main__':
    print("포즈 감지 서버를 시작합니다...")
    print("서버 주소: http://localhost:5000")
    print("API 엔드포인트:")
    print("  POST /start - 포즈 감지 시작")
    print("  POST /stop - 포즈 감지 중지")
    print("  GET /pose - 현재 포즈 데이터")
    print("  GET /status - 서버 상태")
    
    app.run(host='0.0.0.0', port=5000, debug=True)
