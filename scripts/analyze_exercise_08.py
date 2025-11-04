#!/usr/bin/env python3
"""
운동 08번 (굿모닝 Good Morning) 데이터 분석 스크립트
- PT-Pose-Data에서 3D 포즈 데이터 추출
- 관절 각도 계산 및 통계 분석
- 미세한 떨림 보정 (Moving Average Filter)
- exercise_reference.json 업데이트
"""

import json
import numpy as np
import os
from pathlib import Path
from typing import Dict, List, Tuple
import math
from scipy.signal import savgol_filter


class Point3D:
    """3D 좌표 포인트"""
    def __init__(self, x: float, y: float, z: float):
        self.x = x
        self.y = y
        self.z = z
    
    def to_dict(self):
        return {"x": self.x, "y": self.y, "z": self.z}


def calculate_angle_3d(p1: Point3D, p2: Point3D, p3: Point3D) -> float:
    """
    3D 공간에서 3점으로 이루어진 각도 계산
    p2가 중심점 (vertex)
    """
    # 벡터 생성
    v1 = np.array([p1.x - p2.x, p1.y - p2.y, p1.z - p2.z])
    v2 = np.array([p3.x - p2.x, p3.y - p2.y, p3.z - p2.z])
    
    # 벡터의 크기
    v1_mag = np.linalg.norm(v1)
    v2_mag = np.linalg.norm(v2)
    
    if v1_mag == 0 or v2_mag == 0:
        return 0.0
    
    # 내적을 이용한 각도 계산
    cos_angle = np.dot(v1, v2) / (v1_mag * v2_mag)
    cos_angle = np.clip(cos_angle, -1.0, 1.0)  # 부동소수점 오차 방지
    
    angle = np.arccos(cos_angle)
    return np.degrees(angle)


def apply_smoothing(angles: List[float], window_size: int = 5) -> List[float]:
    """
    미세한 떨림 보정: Savitzky-Golay 필터 적용
    인간의 몸은 미세한 떨림이 있으므로 스무딩 처리
    """
    if len(angles) < window_size:
        return angles
    
    # Savitzky-Golay 필터: 데이터의 전체적인 경향은 유지하면서 노이즈 제거
    try:
        smoothed = savgol_filter(angles, window_size, 2)  # 2차 다항식
        return smoothed.tolist()
    except:
        # 필터 적용 실패시 단순 이동평균
        return moving_average(angles, window_size)


def moving_average(values: List[float], window_size: int = 5) -> List[float]:
    """
    단순 이동 평균 필터
    """
    if len(values) < window_size:
        return values
    
    result = []
    for i in range(len(values)):
        start_idx = max(0, i - window_size // 2)
        end_idx = min(len(values), i + window_size // 2 + 1)
        result.append(np.mean(values[start_idx:end_idx]))
    
    return result


def parse_json_file(file_path: str) -> List[Dict]:
    """3D JSON 파일 파싱"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return data.get('frames', [])
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return []


def extract_point(frame: Dict, joint_name: str) -> Point3D:
    """프레임에서 특정 관절 좌표 추출"""
    pts = frame.get('pts', {})
    if joint_name not in pts:
        return None
    
    point = pts[joint_name]
    return Point3D(point['x'], point['y'], point['z'])


def analyze_good_morning_exercise(data_dir: str) -> Dict:
    """
    굿모닝 운동 데이터 분석
    - 상체를 앞으로 숙이는 운동
    - 주요 각도: 힙 각도, 무릎 각도, 상체 각도
    """
    
    all_angles = {
        'hip_angle_left': [],
        'hip_angle_right': [],
        'knee_angle_left': [],
        'knee_angle_right': [],
        'back_angle': [],
        'torso_forward_bend': [],
    }
    
    # 모든 3D JSON 파일 읽기
    json_files = list(Path(data_dir).glob('*-3d.json'))
    print(f"Found {len(json_files)} 3D JSON files")
    
    frame_count = 0
    for json_file in json_files[:200]:  # 샘플링: 처음 200개 파일만 분석
        frames = parse_json_file(str(json_file))
        
        for frame in frames:
            # 필요한 관절 포인트 추출
            nose = extract_point(frame, 'Nose')
            neck = extract_point(frame, 'Neck')
            back = extract_point(frame, 'Back')
            waist = extract_point(frame, 'Waist')
            
            left_shoulder = extract_point(frame, 'Left Shoulder')
            right_shoulder = extract_point(frame, 'Right Shoulder')
            
            left_hip = extract_point(frame, 'Left Hip')
            right_hip = extract_point(frame, 'Right Hip')
            
            left_knee = extract_point(frame, 'Left Knee')
            right_knee = extract_point(frame, 'Right Knee')
            
            left_ankle = extract_point(frame, 'Left Ankle')
            right_ankle = extract_point(frame, 'Right Ankle')
            
            # 모든 필수 포인트가 있는지 확인
            if all([left_shoulder, right_shoulder, left_hip, right_hip, 
                   left_knee, right_knee, left_ankle, right_ankle, 
                   neck, back, waist]):
                
                # 1. 힙 각도 (Back - Hip - Knee)
                hip_angle_left = calculate_angle_3d(back, left_hip, left_knee)
                hip_angle_right = calculate_angle_3d(back, right_hip, right_knee)
                
                # 2. 무릎 각도 (Hip - Knee - Ankle)
                knee_angle_left = calculate_angle_3d(left_hip, left_knee, left_ankle)
                knee_angle_right = calculate_angle_3d(right_hip, right_knee, right_ankle)
                
                # 3. 등 각도 (Neck - Back - Waist)
                back_angle = calculate_angle_3d(neck, back, waist)
                
                # 4. 상체 숙임 각도 (Shoulder - Hip - Knee) - 전체 상체의 앞으로 숙임 정도
                # 왼쪽과 오른쪽 평균
                torso_left = calculate_angle_3d(left_shoulder, left_hip, left_knee)
                torso_right = calculate_angle_3d(right_shoulder, right_hip, right_knee)
                torso_forward_bend = (torso_left + torso_right) / 2
                
                # 유효한 각도만 저장 (0~180도)
                if 0 < hip_angle_left < 180:
                    all_angles['hip_angle_left'].append(hip_angle_left)
                if 0 < hip_angle_right < 180:
                    all_angles['hip_angle_right'].append(hip_angle_right)
                if 0 < knee_angle_left < 180:
                    all_angles['knee_angle_left'].append(knee_angle_left)
                if 0 < knee_angle_right < 180:
                    all_angles['knee_angle_right'].append(knee_angle_right)
                if 0 < back_angle < 180:
                    all_angles['back_angle'].append(back_angle)
                if 0 < torso_forward_bend < 180:
                    all_angles['torso_forward_bend'].append(torso_forward_bend)
                
                frame_count += 1
    
    print(f"Analyzed {frame_count} frames")
    
    # 미세한 떨림 보정 적용
    for angle_key in all_angles:
        if len(all_angles[angle_key]) > 10:
            all_angles[angle_key] = apply_smoothing(all_angles[angle_key], window_size=7)
    
    # 통계 계산
    statistics = {}
    for angle_name, angles in all_angles.items():
        if len(angles) > 0:
            angles_array = np.array(angles)
            statistics[angle_name] = {
                'mean': float(np.mean(angles_array)),
                'std': float(np.std(angles_array)),
                'min': float(np.min(angles_array)),
                'max': float(np.max(angles_array)),
                'median': float(np.median(angles_array)),
                'count': len(angles)
            }
    
    return statistics


def create_exercise_08_entry(statistics: Dict) -> Dict:
    """
    운동 08번 (굿모닝) exercise_reference.json 항목 생성
    """
    
    # 굿모닝 운동의 주요 동작 단계
    # 1. 시작 자세: 서서 상체를 곧게 펴기
    # 2. 상체 숙이기: 힙을 중심으로 상체를 앞으로 숙이기
    # 3. 원위치 복귀: 천천히 시작 자세로 돌아오기
    
    # 힙 각도 통계
    hip_left = statistics.get('hip_angle_left', {})
    hip_right = statistics.get('hip_angle_right', {})
    
    # 무릎 각도 통계 (거의 펴진 상태 유지)
    knee_left = statistics.get('knee_angle_left', {})
    knee_right = statistics.get('knee_angle_right', {})
    
    # 등 각도 통계
    back = statistics.get('back_angle', {})
    
    # 상체 숙임 각도 통계
    torso = statistics.get('torso_forward_bend', {})
    
    return {
        "exercise_id": "008",
        "exercise_code": "001-1-1-08",
        "exercise_name": "굿모닝",
        "category": "맨몸운동",
        "posture": "서기",
        "difficulty": "중급",
        "description": "힙을 중심으로 상체를 앞으로 숙여 햄스트링과 허리를 강화하는 운동",
        "key_joints": [
            "Neck",
            "Back",
            "Waist",
            "Left Shoulder",
            "Right Shoulder",
            "Left Hip",
            "Right Hip",
            "Left Knee",
            "Right Knee",
            "Left Ankle",
            "Right Ankle"
        ],
        "key_angles": {
            "hip_angle_left": {
                "name": "좌측 힙 각도",
                "points": ["Back", "Left Hip", "Left Knee"],
                "ideal_mean": round(hip_left.get('mean', 85.0), 1),
                "ideal_range": [
                    round(max(50.0, hip_left.get('mean', 85.0) - 25), 1),
                    round(min(120.0, hip_left.get('mean', 85.0) + 25), 1)
                ],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "hip_angle_right": {
                "name": "우측 힙 각도",
                "points": ["Back", "Right Hip", "Right Knee"],
                "ideal_mean": round(hip_right.get('mean', 85.0), 1),
                "ideal_range": [
                    round(max(50.0, hip_right.get('mean', 85.0) - 25), 1),
                    round(min(120.0, hip_right.get('mean', 85.0) + 25), 1)
                ],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "knee_angle_left": {
                "name": "좌측 무릎 각도",
                "points": ["Left Hip", "Left Knee", "Left Ankle"],
                "ideal_mean": round(knee_left.get('mean', 175.0), 1),
                "ideal_range": [
                    round(max(165.0, knee_left.get('mean', 175.0) - 10), 1),
                    180.0
                ],
                "tolerance": 10.0,
                "weight": 0.8
            },
            "knee_angle_right": {
                "name": "우측 무릎 각도",
                "points": ["Right Hip", "Right Knee", "Right Ankle"],
                "ideal_mean": round(knee_right.get('mean', 175.0), 1),
                "ideal_range": [
                    round(max(165.0, knee_right.get('mean', 175.0) - 10), 1),
                    180.0
                ],
                "tolerance": 10.0,
                "weight": 0.8
            },
            "back_angle": {
                "name": "등 각도",
                "points": ["Neck", "Back", "Waist"],
                "ideal_mean": round(back.get('mean', 165.0), 1),
                "ideal_range": [
                    round(max(150.0, back.get('mean', 165.0) - 15), 1),
                    180.0
                ],
                "tolerance": 12.0,
                "weight": 1.2
            },
            "torso_forward_bend": {
                "name": "상체 숙임 각도",
                "points": ["Shoulder", "Hip", "Knee"],
                "ideal_mean": round(torso.get('mean', 70.0), 1),
                "ideal_range": [
                    round(max(45.0, torso.get('mean', 70.0) - 20), 1),
                    round(min(100.0, torso.get('mean', 70.0) + 20), 1)
                ],
                "tolerance": 15.0,
                "weight": 1.8
            }
        },
        "motion_phases": [
            {
                "phase_id": 1,
                "phase_name": "시작 자세",
                "description": "양발을 어깨 너비로 벌리고 서서 상체를 곧게 펴세요",
                "duration_sec": 2.0,
                "key_checks": [
                    "상체를 자연스럽게 곧게 펴기",
                    "무릎은 자연스럽게 펴기 (175도 이상)",
                    "시선은 정면"
                ]
            },
            {
                "phase_id": 2,
                "phase_name": "상체 숙이기",
                "description": "힙을 중심으로 상체를 천천히 앞으로 숙이세요. 등은 곧게 유지하세요",
                "duration_sec": 2.5,
                "key_checks": [
                    "힙 각도 60~100도",
                    "등을 곧게 유지 (등 각도 150도 이상)",
                    "무릎은 펴진 상태 유지",
                    "햄스트링 스트레칭 느끼기"
                ]
            },
            {
                "phase_id": 3,
                "phase_name": "최대 숙임 유지",
                "description": "상체를 숙인 상태에서 1초간 유지하세요",
                "duration_sec": 1.0,
                "key_checks": [
                    "등을 곧게 유지",
                    "호흡 유지"
                ]
            },
            {
                "phase_id": 4,
                "phase_name": "원위치 복귀",
                "description": "천천히 시작 자세로 돌아오세요",
                "duration_sec": 2.5,
                "key_checks": [
                    "등을 곧게 유지하면서 복귀",
                    "힙을 중심으로 상체 세우기"
                ]
            },
            {
                "phase_id": 5,
                "phase_name": "운동 완료",
                "description": "시작 자세로 돌아와 호흡을 정리하세요",
                "duration_sec": 2.0,
                "key_checks": [
                    "시작 자세로 복귀",
                    "호흡 정리"
                ]
            }
        ],
        "feedback_rules": [
            {
                "condition": "back_angle < 150",
                "feedback": "등이 구부러졌습니다. 등을 곧게 펴세요",
                "severity": "warning"
            },
            {
                "condition": "knee_angle_left < 165",
                "feedback": "왼쪽 무릎을 펴세요",
                "severity": "warning"
            },
            {
                "condition": "knee_angle_right < 165",
                "feedback": "오른쪽 무릎을 펴세요",
                "severity": "warning"
            },
            {
                "condition": "hip_angle_left < 50",
                "feedback": "너무 깊게 숙였습니다",
                "severity": "warning"
            },
            {
                "condition": "hip_angle_left > 120",
                "feedback": "더 깊게 숙여주세요",
                "severity": "info"
            },
            {
                "condition": "abs(hip_angle_left - hip_angle_right) > 15",
                "feedback": "좌우 균형을 맞춰주세요",
                "severity": "warning"
            }
        ],
        "common_mistakes": [
            "등을 둥글게 구부리는 경우",
            "무릎을 구부리는 경우",
            "너무 빠르게 동작하는 경우",
            "힙이 아닌 허리로 숙이는 경우",
            "호흡을 멈추는 경우"
        ]
    }


def main():
    # 데이터 경로 설정
    data_dir = "PT-Pose-Data/PT_Pose/1.Training/Labeling/맨몸운동_Labeling_new_220128/맨몸운동_08/Day33_201105_F"
    
    if not os.path.exists(data_dir):
        print(f"Error: Data directory not found: {data_dir}")
        return
    
    print("=" * 60)
    print("운동 08번 (굿모닝) 데이터 분석 시작")
    print("=" * 60)
    
    # 데이터 분석
    print("\n1. 데이터 분석 중...")
    statistics = analyze_good_morning_exercise(data_dir)
    
    print("\n2. 통계 결과:")
    for angle_name, stats in statistics.items():
        print(f"\n{angle_name}:")
        print(f"  평균: {stats['mean']:.2f}°")
        print(f"  표준편차: {stats['std']:.2f}°")
        print(f"  범위: {stats['min']:.2f}° ~ {stats['max']:.2f}°")
        print(f"  중앙값: {stats['median']:.2f}°")
        print(f"  샘플 수: {stats['count']}")
    
    # exercise_reference.json 항목 생성
    print("\n3. exercise_reference.json 항목 생성 중...")
    exercise_08 = create_exercise_08_entry(statistics)
    
    # 기존 exercise_reference.json 읽기
    reference_file = "assets/exercise_reference.json"
    if os.path.exists(reference_file):
        with open(reference_file, 'r', encoding='utf-8') as f:
            reference_data = json.load(f)
    else:
        reference_data = {
            "version": "1.0.0",
            "last_updated": "2025-11-03",
            "exercises": []
        }
    
    # 08번 운동이 이미 있는지 확인
    existing_ids = [ex['exercise_id'] for ex in reference_data['exercises']]
    if "008" in existing_ids:
        # 기존 항목 업데이트
        for i, ex in enumerate(reference_data['exercises']):
            if ex['exercise_id'] == "008":
                reference_data['exercises'][i] = exercise_08
                print("   기존 운동 08번 항목 업데이트")
                break
    else:
        # 새 항목 추가
        reference_data['exercises'].append(exercise_08)
        print("   새로운 운동 08번 항목 추가")
    
    # 날짜 업데이트
    reference_data['last_updated'] = "2025-11-03"
    
    # 파일 저장
    with open(reference_file, 'w', encoding='utf-8') as f:
        json.dump(reference_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✓ 완료! {reference_file} 업데이트됨")
    print("\n" + "=" * 60)
    print("운동 08번 (굿모닝) 추가 완료")
    print("=" * 60)


if __name__ == "__main__":
    main()

