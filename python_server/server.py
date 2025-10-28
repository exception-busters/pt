import cv2
import mediapipe as mp
import json
import socket
import threading
import time
import base64
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# MediaPipe Pose 모델 불러오기
mp_pose = mp.solutions.pose
pose = mp_pose.Pose(
    static_image_mode=False,
    model_complexity=1,
    enable_segmentation=False,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
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
                    print(f"카메라 {i}번을 사용합니다.")
                    return True
                else:
                    test_cap.release()
        return False
    except Exception as e:
        print(f"카메라 초기화 오류: {e}")
        return False

def process_pose_detection():
    """실시간 포즈 감지 처리"""
    global latest_pose_data, is_running
    
    while is_running:
        try:
            if camera is not None:
                ret, frame = camera.read()
                if ret:
                    # BGR에서 RGB로 변환
                    image_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                    
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
                    
                    latest_pose_data = pose_data
                else:
                    time.sleep(0.1)
            else:
                time.sleep(0.1)
        except Exception as e:
            print(f"포즈 감지 오류: {e}")
            time.sleep(0.1)

@app.route('/start', methods=['POST'])
def start_detection():
    """포즈 감지 시작"""
    global is_running, camera
    
    if not is_running:
        if initialize_camera():
            is_running = True
            # 백그라운드에서 포즈 감지 실행
            thread = threading.Thread(target=process_pose_detection)
            thread.daemon = True
            thread.start()
            return jsonify({"status": "started", "message": "포즈 감지가 시작되었습니다."})
        else:
            return jsonify({"status": "error", "message": "카메라를 초기화할 수 없습니다."})
    else:
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
