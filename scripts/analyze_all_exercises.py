#!/usr/bin/env python3
"""
운동 02~07번 통합 분석 스크립트
- PT-Pose-Data에서 3D 포즈 데이터 추출
- 관절 각도 계산 및 통계 분석
- 미세한 떨림 보정 (Savitzky-Golay 필터)
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


def calculate_angle_3d(p1: Point3D, p2: Point3D, p3: Point3D) -> float:
    """3D 공간에서 3점으로 이루어진 각도 계산"""
    v1 = np.array([p1.x - p2.x, p1.y - p2.y, p1.z - p2.z])
    v2 = np.array([p3.x - p2.x, p3.y - p2.y, p3.z - p2.z])
    
    v1_mag = np.linalg.norm(v1)
    v2_mag = np.linalg.norm(v2)
    
    if v1_mag == 0 or v2_mag == 0:
        return 0.0
    
    cos_angle = np.dot(v1, v2) / (v1_mag * v2_mag)
    cos_angle = np.clip(cos_angle, -1.0, 1.0)
    
    angle = np.arccos(cos_angle)
    return np.degrees(angle)


def apply_smoothing(angles: List[float], window_size: int = 7) -> List[float]:
    """Savitzky-Golay 필터로 떨림 보정"""
    if len(angles) < window_size:
        return angles
    
    try:
        smoothed = savgol_filter(angles, window_size, 2)
        return smoothed.tolist()
    except:
        return angles


def parse_json_file(file_path: str) -> List[Dict]:
    """3D JSON 파일 파싱"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            return data.get('frames', [])
    except Exception as e:
        return []


def extract_point(frame: Dict, joint_name: str) -> Point3D:
    """프레임에서 특정 관절 좌표 추출"""
    pts = frame.get('pts', {})
    if joint_name not in pts:
        return None
    
    point = pts[joint_name]
    return Point3D(point['x'], point['y'], point['z'])


# 각 운동별 분석 함수
def analyze_exercise_02(data_dir: str) -> Dict:
    """02번 - 스탠딩 니업 (무릎 들어올리기)"""
    all_angles = {
        'left_hip_flexion': [],  # 왼쪽 힙 굴곡
        'right_hip_flexion': [],  # 오른쪽 힙 굴곡
        'left_knee_angle': [],  # 왼쪽 무릎 각도
        'right_knee_angle': [],  # 오른쪽 무릎 각도
        'standing_leg_knee': [],  # 지지 다리 무릎
    }
    
    json_files = list(Path(data_dir).glob('**/*-3d.json'))
    print(f"02번 운동: {len(json_files)} 파일 발견")
    
    for json_file in json_files[:150]:
        frames = parse_json_file(str(json_file))
        for frame in frames:
            back = extract_point(frame, 'Back')
            left_hip = extract_point(frame, 'Left Hip')
            right_hip = extract_point(frame, 'Right Hip')
            left_knee = extract_point(frame, 'Left Knee')
            right_knee = extract_point(frame, 'Right Knee')
            left_ankle = extract_point(frame, 'Left Ankle')
            right_ankle = extract_point(frame, 'Right Ankle')
            
            if all([back, left_hip, right_hip, left_knee, right_knee, left_ankle, right_ankle]):
                # 힙 굴곡 (Back - Hip - Knee)
                left_hip_flex = calculate_angle_3d(back, left_hip, left_knee)
                right_hip_flex = calculate_angle_3d(back, right_hip, right_knee)
                
                # 무릎 각도
                left_knee_ang = calculate_angle_3d(left_hip, left_knee, left_ankle)
                right_knee_ang = calculate_angle_3d(right_hip, right_knee, right_ankle)
                
                if 0 < left_hip_flex < 180:
                    all_angles['left_hip_flexion'].append(left_hip_flex)
                if 0 < right_hip_flex < 180:
                    all_angles['right_hip_flexion'].append(right_hip_flex)
                if 0 < left_knee_ang < 180:
                    all_angles['left_knee_angle'].append(left_knee_ang)
                if 0 < right_knee_ang < 180:
                    all_angles['right_knee_angle'].append(right_knee_ang)
    
    # 스무딩 적용
    for key in all_angles:
        if len(all_angles[key]) > 10:
            all_angles[key] = apply_smoothing(all_angles[key])
    
    return compute_statistics(all_angles)


def analyze_exercise_03(data_dir: str) -> Dict:
    """03번 - 스쿼트 또는 무릎 굽히기 운동"""
    all_angles = {
        'left_knee_angle': [],
        'right_knee_angle': [],
        'left_hip_angle': [],
        'right_hip_angle': [],
        'back_angle': [],
    }
    
    json_files = list(Path(data_dir).glob('**/*-3d.json'))
    print(f"03번 운동: {len(json_files)} 파일 발견")
    
    for json_file in json_files[:150]:
        frames = parse_json_file(str(json_file))
        for frame in frames:
            neck = extract_point(frame, 'Neck')
            back = extract_point(frame, 'Back')
            waist = extract_point(frame, 'Waist')
            left_hip = extract_point(frame, 'Left Hip')
            right_hip = extract_point(frame, 'Right Hip')
            left_knee = extract_point(frame, 'Left Knee')
            right_knee = extract_point(frame, 'Right Knee')
            left_ankle = extract_point(frame, 'Left Ankle')
            right_ankle = extract_point(frame, 'Right Ankle')
            
            if all([left_hip, right_hip, left_knee, right_knee, left_ankle, right_ankle]):
                left_knee_ang = calculate_angle_3d(left_hip, left_knee, left_ankle)
                right_knee_ang = calculate_angle_3d(right_hip, right_knee, right_ankle)
                left_hip_ang = calculate_angle_3d(back, left_hip, left_knee)
                right_hip_ang = calculate_angle_3d(back, right_hip, right_knee)
                
                if 0 < left_knee_ang < 180:
                    all_angles['left_knee_angle'].append(left_knee_ang)
                if 0 < right_knee_ang < 180:
                    all_angles['right_knee_angle'].append(right_knee_ang)
                if 0 < left_hip_ang < 180:
                    all_angles['left_hip_angle'].append(left_hip_ang)
                if 0 < right_hip_ang < 180:
                    all_angles['right_hip_angle'].append(right_hip_ang)
            
            if neck and back and waist:
                back_ang = calculate_angle_3d(neck, back, waist)
                if 0 < back_ang < 180:
                    all_angles['back_angle'].append(back_ang)
    
    for key in all_angles:
        if len(all_angles[key]) > 10:
            all_angles[key] = apply_smoothing(all_angles[key])
    
    return compute_statistics(all_angles)


def analyze_exercise_04(data_dir: str) -> Dict:
    """04번 - 스탠딩 프론트 다이나믹 런지"""
    all_angles = {
        'front_knee_angle': [],
        'back_knee_angle': [],
        'front_hip_angle': [],
        'back_hip_angle': [],
        'trunk_angle': [],
    }
    
    json_files = list(Path(data_dir).glob('**/*-3d.json'))
    print(f"04번 운동: {len(json_files)} 파일 발견")
    
    for json_file in json_files[:150]:
        frames = parse_json_file(str(json_file))
        for frame in frames:
            back = extract_point(frame, 'Back')
            left_hip = extract_point(frame, 'Left Hip')
            right_hip = extract_point(frame, 'Right Hip')
            left_knee = extract_point(frame, 'Left Knee')
            right_knee = extract_point(frame, 'Right Knee')
            left_ankle = extract_point(frame, 'Left Ankle')
            right_ankle = extract_point(frame, 'Right Ankle')
            
            if all([back, left_hip, right_hip, left_knee, right_knee, left_ankle, right_ankle]):
                left_knee_ang = calculate_angle_3d(left_hip, left_knee, left_ankle)
                right_knee_ang = calculate_angle_3d(right_hip, right_knee, right_ankle)
                left_hip_ang = calculate_angle_3d(back, left_hip, left_knee)
                right_hip_ang = calculate_angle_3d(back, right_hip, right_knee)
                
                if 0 < left_knee_ang < 180:
                    all_angles['front_knee_angle'].append(left_knee_ang)
                if 0 < right_knee_ang < 180:
                    all_angles['back_knee_angle'].append(right_knee_ang)
                if 0 < left_hip_ang < 180:
                    all_angles['front_hip_angle'].append(left_hip_ang)
                if 0 < right_hip_ang < 180:
                    all_angles['back_hip_angle'].append(right_hip_ang)
    
    for key in all_angles:
        if len(all_angles[key]) > 10:
            all_angles[key] = apply_smoothing(all_angles[key])
    
    return compute_statistics(all_angles)


def analyze_exercise_05(data_dir: str) -> Dict:
    """05번 - 스탠딩 백워드 다이나믹 런지"""
    return analyze_exercise_04(data_dir)  # 런지 운동이므로 유사한 각도 측정


def analyze_exercise_06(data_dir: str) -> Dict:
    """06번 - 팔 운동 (추정)"""
    all_angles = {
        'left_shoulder_angle': [],
        'right_shoulder_angle': [],
        'left_elbow_angle': [],
        'right_elbow_angle': [],
    }
    
    json_files = list(Path(data_dir).glob('**/*-3d.json'))
    print(f"06번 운동: {len(json_files)} 파일 발견")
    
    for json_file in json_files[:150]:
        frames = parse_json_file(str(json_file))
        for frame in frames:
            neck = extract_point(frame, 'Neck')
            left_shoulder = extract_point(frame, 'Left Shoulder')
            right_shoulder = extract_point(frame, 'Right Shoulder')
            left_elbow = extract_point(frame, 'Left Elbow')
            right_elbow = extract_point(frame, 'Right Elbow')
            left_wrist = extract_point(frame, 'Left Wrist')
            right_wrist = extract_point(frame, 'Right Wrist')
            left_hip = extract_point(frame, 'Left Hip')
            right_hip = extract_point(frame, 'Right Hip')
            
            if all([left_shoulder, right_shoulder, left_elbow, right_elbow, left_wrist, right_wrist]):
                left_elbow_ang = calculate_angle_3d(left_shoulder, left_elbow, left_wrist)
                right_elbow_ang = calculate_angle_3d(right_shoulder, right_elbow, right_wrist)
                
                if 0 < left_elbow_ang < 180:
                    all_angles['left_elbow_angle'].append(left_elbow_ang)
                if 0 < right_elbow_ang < 180:
                    all_angles['right_elbow_angle'].append(right_elbow_ang)
            
            if neck and left_shoulder and left_elbow:
                left_shoulder_ang = calculate_angle_3d(neck, left_shoulder, left_elbow)
                if 0 < left_shoulder_ang < 180:
                    all_angles['left_shoulder_angle'].append(left_shoulder_ang)
            
            if neck and right_shoulder and right_elbow:
                right_shoulder_ang = calculate_angle_3d(neck, right_shoulder, right_elbow)
                if 0 < right_shoulder_ang < 180:
                    all_angles['right_shoulder_angle'].append(right_shoulder_ang)
    
    for key in all_angles:
        if len(all_angles[key]) > 10:
            all_angles[key] = apply_smoothing(all_angles[key])
    
    return compute_statistics(all_angles)


def analyze_exercise_07(data_dir: str) -> Dict:
    """07번 - 복합 운동"""
    all_angles = {
        'left_hip_angle': [],
        'right_hip_angle': [],
        'left_knee_angle': [],
        'right_knee_angle': [],
        'left_ankle_angle': [],
        'right_ankle_angle': [],
    }
    
    json_files = list(Path(data_dir).glob('**/*-3d.json'))
    print(f"07번 운동: {len(json_files)} 파일 발견")
    
    for json_file in json_files[:150]:
        frames = parse_json_file(str(json_file))
        for frame in frames:
            back = extract_point(frame, 'Back')
            left_hip = extract_point(frame, 'Left Hip')
            right_hip = extract_point(frame, 'Right Hip')
            left_knee = extract_point(frame, 'Left Knee')
            right_knee = extract_point(frame, 'Right Knee')
            left_ankle = extract_point(frame, 'Left Ankle')
            right_ankle = extract_point(frame, 'Right Ankle')
            left_foot = extract_point(frame, 'Left Foot')
            right_foot = extract_point(frame, 'Right Foot')
            
            if all([back, left_hip, right_hip, left_knee, right_knee, left_ankle, right_ankle]):
                left_hip_ang = calculate_angle_3d(back, left_hip, left_knee)
                right_hip_ang = calculate_angle_3d(back, right_hip, right_knee)
                left_knee_ang = calculate_angle_3d(left_hip, left_knee, left_ankle)
                right_knee_ang = calculate_angle_3d(right_hip, right_knee, right_ankle)
                
                if 0 < left_hip_ang < 180:
                    all_angles['left_hip_angle'].append(left_hip_ang)
                if 0 < right_hip_ang < 180:
                    all_angles['right_hip_angle'].append(right_hip_ang)
                if 0 < left_knee_ang < 180:
                    all_angles['left_knee_angle'].append(left_knee_ang)
                if 0 < right_knee_ang < 180:
                    all_angles['right_knee_angle'].append(right_knee_ang)
            
            if left_knee and left_ankle and left_foot:
                left_ankle_ang = calculate_angle_3d(left_knee, left_ankle, left_foot)
                if 0 < left_ankle_ang < 180:
                    all_angles['left_ankle_angle'].append(left_ankle_ang)
            
            if right_knee and right_ankle and right_foot:
                right_ankle_ang = calculate_angle_3d(right_knee, right_ankle, right_foot)
                if 0 < right_ankle_ang < 180:
                    all_angles['right_ankle_angle'].append(right_ankle_ang)
    
    for key in all_angles:
        if len(all_angles[key]) > 10:
            all_angles[key] = apply_smoothing(all_angles[key])
    
    return compute_statistics(all_angles)


def compute_statistics(all_angles: Dict) -> Dict:
    """통계 계산"""
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


# 각 운동별 JSON 생성 함수들
def create_exercise_02_entry(stats: Dict) -> Dict:
    """02번 - 스탠딩 니업"""
    left_hip = stats.get('left_hip_flexion', {})
    right_hip = stats.get('right_hip_flexion', {})
    left_knee = stats.get('left_knee_angle', {})
    right_knee = stats.get('right_knee_angle', {})
    
    return {
        "exercise_id": "002",
        "exercise_code": "001-1-1-02",
        "exercise_name": "스탠딩 니업",
        "category": "맨몸운동",
        "posture": "서기",
        "difficulty": "초급",
        "description": "서서 무릎을 교대로 가슴 쪽으로 들어올리는 유산소 운동",
        "key_joints": ["Back", "Left Hip", "Right Hip", "Left Knee", "Right Knee", "Left Ankle", "Right Ankle"],
        "key_angles": {
            "left_hip_flexion": {
                "name": "좌측 힙 굴곡",
                "points": ["Back", "Left Hip", "Left Knee"],
                "ideal_mean": round(left_hip.get('mean', 90.0), 1),
                "ideal_range": [round(max(60.0, left_hip.get('mean', 90.0) - 30), 1), 
                                round(min(120.0, left_hip.get('mean', 90.0) + 30), 1)],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "right_hip_flexion": {
                "name": "우측 힙 굴곡",
                "points": ["Back", "Right Hip", "Right Knee"],
                "ideal_mean": round(right_hip.get('mean', 90.0), 1),
                "ideal_range": [round(max(60.0, right_hip.get('mean', 90.0) - 30), 1), 
                                round(min(120.0, right_hip.get('mean', 90.0) + 30), 1)],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "left_knee_angle": {
                "name": "좌측 무릎 각도",
                "points": ["Left Hip", "Left Knee", "Left Ankle"],
                "ideal_mean": round(left_knee.get('mean', 90.0), 1),
                "ideal_range": [round(max(60.0, left_knee.get('mean', 90.0) - 30), 1), 
                                round(min(120.0, left_knee.get('mean', 90.0) + 30), 1)],
                "tolerance": 15.0,
                "weight": 1.0
            },
            "right_knee_angle": {
                "name": "우측 무릎 각도",
                "points": ["Right Hip", "Right Knee", "Right Ankle"],
                "ideal_mean": round(right_knee.get('mean', 90.0), 1),
                "ideal_range": [round(max(60.0, right_knee.get('mean', 90.0) - 30), 1), 
                                round(min(120.0, right_knee.get('mean', 90.0) + 30), 1)],
                "tolerance": 15.0,
                "weight": 1.0
            }
        },
        "motion_phases": [
            {"phase_id": 1, "phase_name": "시작 자세", "description": "양발을 어깨 너비로 벌리고 서세요", "duration_sec": 1.0, "key_checks": ["자연스러운 서기 자세"]},
            {"phase_id": 2, "phase_name": "왼쪽 무릎 들기", "description": "왼쪽 무릎을 가슴 쪽으로 들어올리세요", "duration_sec": 1.5, "key_checks": ["무릎을 90도까지 굴곡", "균형 유지"]},
            {"phase_id": 3, "phase_name": "왼쪽 내리기", "description": "천천히 왼발을 내려놓으세요", "duration_sec": 1.0, "key_checks": ["부드럽게 착지"]},
            {"phase_id": 4, "phase_name": "오른쪽 무릎 들기", "description": "오른쪽 무릎을 가슴 쪽으로 들어올리세요", "duration_sec": 1.5, "key_checks": ["무릎을 90도까지 굴곡", "균형 유지"]},
            {"phase_id": 5, "phase_name": "완료", "description": "시작 자세로 돌아가세요", "duration_sec": 1.0, "key_checks": ["양발 지면에 고정"]}
        ],
        "feedback_rules": [
            {"condition": "left_hip_flexion < 60", "feedback": "왼쪽 무릎을 더 높이 들어올리세요", "severity": "info"},
            {"condition": "right_hip_flexion < 60", "feedback": "오른쪽 무릎을 더 높이 들어올리세요", "severity": "info"}
        ],
        "common_mistakes": ["무릎을 충분히 들지 않음", "상체가 앞으로 기울어짐", "너무 빠른 동작"]
    }


def create_exercise_03_entry(stats: Dict) -> Dict:
    """03번 - 스쿼트"""
    return {
        "exercise_id": "003",
        "exercise_code": "001-1-1-03",
        "exercise_name": "스쿼트",
        "category": "맨몸운동",
        "posture": "서기",
        "difficulty": "초급",
        "description": "하체 근력을 강화하는 기본 운동",
        "key_joints": ["Back", "Waist", "Left Hip", "Right Hip", "Left Knee", "Right Knee", "Left Ankle", "Right Ankle"],
        "key_angles": {
            "left_knee_angle": {
                "name": "좌측 무릎 각도",
                "points": ["Left Hip", "Left Knee", "Left Ankle"],
                "ideal_mean": round(stats.get('left_knee_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [70.0, 110.0],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "right_knee_angle": {
                "name": "우측 무릎 각도",
                "points": ["Right Hip", "Right Knee", "Right Ankle"],
                "ideal_mean": round(stats.get('right_knee_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [70.0, 110.0],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "left_hip_angle": {
                "name": "좌측 힙 각도",
                "points": ["Back", "Left Hip", "Left Knee"],
                "ideal_mean": round(stats.get('left_hip_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [70.0, 110.0],
                "tolerance": 15.0,
                "weight": 1.2
            },
            "right_hip_angle": {
                "name": "우측 힙 각도",
                "points": ["Back", "Right Hip", "Right Knee"],
                "ideal_mean": round(stats.get('right_hip_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [70.0, 110.0],
                "tolerance": 15.0,
                "weight": 1.2
            }
        },
        "motion_phases": [
            {"phase_id": 1, "phase_name": "시작 자세", "description": "양발을 어깨 너비로 벌리고 서세요", "duration_sec": 1.0, "key_checks": ["자연스러운 서기"]},
            {"phase_id": 2, "phase_name": "하강", "description": "엉덩이를 뒤로 빼며 무릎을 구부리세요", "duration_sec": 2.0, "key_checks": ["무릎 90도 굴곡", "등 곧게 유지"]},
            {"phase_id": 3, "phase_name": "유지", "description": "최하단에서 1초간 유지하세요", "duration_sec": 1.0, "key_checks": ["자세 유지"]},
            {"phase_id": 4, "phase_name": "상승", "description": "천천히 시작 자세로 돌아오세요", "duration_sec": 2.0, "key_checks": ["무릎 펴기"]},
            {"phase_id": 5, "phase_name": "완료", "description": "시작 자세로 복귀", "duration_sec": 1.0, "key_checks": ["완전히 서기"]}
        ],
        "feedback_rules": [
            {"condition": "left_knee_angle < 70", "feedback": "너무 깊게 앉았습니다", "severity": "warning"},
            {"condition": "right_knee_angle < 70", "feedback": "너무 깊게 앉았습니다", "severity": "warning"}
        ],
        "common_mistakes": ["무릎이 발끝을 넘어감", "등이 구부러짐", "너무 빠른 동작"]
    }


def create_exercise_04_entry(stats: Dict) -> Dict:
    """04번 - 스탠딩 프론트 다이나믹 런지"""
    return {
        "exercise_id": "004",
        "exercise_code": "001-1-1-04",
        "exercise_name": "스탠딩 프론트 다이나믹 런지",
        "category": "맨몸운동",
        "posture": "서기",
        "difficulty": "중급",
        "description": "앞으로 나가며 런지하여 하체 근력과 균형을 강화하는 운동",
        "key_joints": ["Back", "Left Hip", "Right Hip", "Left Knee", "Right Knee", "Left Ankle", "Right Ankle"],
        "key_angles": {
            "front_knee_angle": {
                "name": "앞쪽 무릎 각도",
                "points": ["Left Hip", "Left Knee", "Left Ankle"],
                "ideal_mean": round(stats.get('front_knee_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [75.0, 105.0],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "back_knee_angle": {
                "name": "뒤쪽 무릎 각도",
                "points": ["Right Hip", "Right Knee", "Right Ankle"],
                "ideal_mean": round(stats.get('back_knee_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [80.0, 120.0],
                "tolerance": 15.0,
                "weight": 1.2
            },
            "front_hip_angle": {
                "name": "앞쪽 힙 각도",
                "points": ["Back", "Left Hip", "Left Knee"],
                "ideal_mean": round(stats.get('front_hip_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [80.0, 110.0],
                "tolerance": 15.0,
                "weight": 1.3
            }
        },
        "motion_phases": [
            {"phase_id": 1, "phase_name": "시작 자세", "description": "양발을 모으고 서세요", "duration_sec": 1.0, "key_checks": ["자연스러운 서기"]},
            {"phase_id": 2, "phase_name": "앞으로 나가기", "description": "한 발을 앞으로 크게 내디디세요", "duration_sec": 1.5, "key_checks": ["큰 보폭"]},
            {"phase_id": 3, "phase_name": "하강", "description": "무릎을 구부려 내려가세요", "duration_sec": 2.0, "key_checks": ["앞 무릎 90도", "뒤 무릎 지면 가까이"]},
            {"phase_id": 4, "phase_name": "상승", "description": "힘차게 일어나며 시작 자세로", "duration_sec": 1.5, "key_checks": ["발 모으기"]},
            {"phase_id": 5, "phase_name": "완료", "description": "반대쪽 다리 준비", "duration_sec": 1.0, "key_checks": ["균형 잡기"]}
        ],
        "feedback_rules": [
            {"condition": "front_knee_angle < 75", "feedback": "앞 무릎이 너무 굽혀졌습니다", "severity": "warning"},
            {"condition": "front_knee_angle > 105", "feedback": "더 깊게 내려가세요", "severity": "info"}
        ],
        "common_mistakes": ["앞 무릎이 발끝을 넘어감", "상체가 앞으로 기울어짐", "보폭이 너무 좁음"]
    }


def create_exercise_05_entry(stats: Dict) -> Dict:
    """05번 - 스탠딩 백워드 다이나믹 런지"""
    return {
        "exercise_id": "005",
        "exercise_code": "001-1-1-05",
        "exercise_name": "스탠딩 백워드 다이나믹 런지",
        "category": "맨몸운동",
        "posture": "서기",
        "difficulty": "중급",
        "description": "뒤로 물러나며 런지하여 하체 근력과 균형을 강화하는 운동",
        "key_joints": ["Back", "Left Hip", "Right Hip", "Left Knee", "Right Knee", "Left Ankle", "Right Ankle"],
        "key_angles": {
            "front_knee_angle": {
                "name": "앞쪽 무릎 각도",
                "points": ["Left Hip", "Left Knee", "Left Ankle"],
                "ideal_mean": round(stats.get('front_knee_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [75.0, 105.0],
                "tolerance": 15.0,
                "weight": 1.5
            },
            "back_knee_angle": {
                "name": "뒤쪽 무릎 각도",
                "points": ["Right Hip", "Right Knee", "Right Ankle"],
                "ideal_mean": round(stats.get('back_knee_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [80.0, 120.0],
                "tolerance": 15.0,
                "weight": 1.2
            },
            "front_hip_angle": {
                "name": "앞쪽 힙 각도",
                "points": ["Back", "Left Hip", "Left Knee"],
                "ideal_mean": round(stats.get('front_hip_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [80.0, 110.0],
                "tolerance": 15.0,
                "weight": 1.3
            }
        },
        "motion_phases": [
            {"phase_id": 1, "phase_name": "시작 자세", "description": "양발을 모으고 서세요", "duration_sec": 1.0, "key_checks": ["자연스러운 서기"]},
            {"phase_id": 2, "phase_name": "뒤로 물러나기", "description": "한 발을 뒤로 크게 내디디세요", "duration_sec": 1.5, "key_checks": ["큰 보폭"]},
            {"phase_id": 3, "phase_name": "하강", "description": "무릎을 구부려 내려가세요", "duration_sec": 2.0, "key_checks": ["앞 무릎 90도", "뒤 무릎 지면 가까이"]},
            {"phase_id": 4, "phase_name": "상승", "description": "힘차게 일어나며 시작 자세로", "duration_sec": 1.5, "key_checks": ["발 모으기"]},
            {"phase_id": 5, "phase_name": "완료", "description": "반대쪽 다리 준비", "duration_sec": 1.0, "key_checks": ["균형 잡기"]}
        ],
        "feedback_rules": [
            {"condition": "front_knee_angle < 75", "feedback": "앞 무릎이 너무 굽혀졌습니다", "severity": "warning"},
            {"condition": "back_knee_angle < 80", "feedback": "뒤 무릎이 너무 굽혀졌습니다", "severity": "warning"}
        ],
        "common_mistakes": ["앞 무릎이 발끝을 넘어감", "상체가 앞으로 기울어짐", "보폭이 너무 좁음"]
    }


def create_exercise_06_entry(stats: Dict) -> Dict:
    """06번 - 팔 운동"""
    return {
        "exercise_id": "006",
        "exercise_code": "001-1-1-06",
        "exercise_name": "스탠딩 암 서클",
        "category": "맨몸운동",
        "posture": "서기",
        "difficulty": "초급",
        "description": "팔을 원을 그리며 돌려 어깨 가동성을 향상시키는 운동",
        "key_joints": ["Neck", "Left Shoulder", "Right Shoulder", "Left Elbow", "Right Elbow", "Left Wrist", "Right Wrist"],
        "key_angles": {
            "left_shoulder_angle": {
                "name": "좌측 어깨 각도",
                "points": ["Neck", "Left Shoulder", "Left Elbow"],
                "ideal_mean": round(stats.get('left_shoulder_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [60.0, 180.0],
                "tolerance": 20.0,
                "weight": 1.3
            },
            "right_shoulder_angle": {
                "name": "우측 어깨 각도",
                "points": ["Neck", "Right Shoulder", "Right Elbow"],
                "ideal_mean": round(stats.get('right_shoulder_angle', {}).get('mean', 90.0), 1),
                "ideal_range": [60.0, 180.0],
                "tolerance": 20.0,
                "weight": 1.3
            },
            "left_elbow_angle": {
                "name": "좌측 팔꿈치 각도",
                "points": ["Left Shoulder", "Left Elbow", "Left Wrist"],
                "ideal_mean": round(stats.get('left_elbow_angle', {}).get('mean', 170.0), 1),
                "ideal_range": [150.0, 180.0],
                "tolerance": 15.0,
                "weight": 0.8
            },
            "right_elbow_angle": {
                "name": "우측 팔꿈치 각도",
                "points": ["Right Shoulder", "Right Elbow", "Right Wrist"],
                "ideal_mean": round(stats.get('right_elbow_angle', {}).get('mean', 170.0), 1),
                "ideal_range": [150.0, 180.0],
                "tolerance": 15.0,
                "weight": 0.8
            }
        },
        "motion_phases": [
            {"phase_id": 1, "phase_name": "시작 자세", "description": "양팔을 옆으로 벌리세요", "duration_sec": 1.0, "key_checks": ["팔 일직선"]},
            {"phase_id": 2, "phase_name": "전방 서클", "description": "팔을 앞으로 원을 그리세요", "duration_sec": 3.0, "key_checks": ["부드러운 원운동"]},
            {"phase_id": 3, "phase_name": "중립", "description": "팔을 옆으로", "duration_sec": 1.0, "key_checks": ["팔 일직선"]},
            {"phase_id": 4, "phase_name": "후방 서클", "description": "팔을 뒤로 원을 그리세요", "duration_sec": 3.0, "key_checks": ["부드러운 원운동"]},
            {"phase_id": 5, "phase_name": "완료", "description": "팔을 내리세요", "duration_sec": 1.0, "key_checks": ["자연스러운 자세"]}
        ],
        "feedback_rules": [
            {"condition": "left_elbow_angle < 150", "feedback": "왼팔을 펴세요", "severity": "info"},
            {"condition": "right_elbow_angle < 150", "feedback": "오른팔을 펴세요", "severity": "info"}
        ],
        "common_mistakes": ["팔꿈치가 굽혀짐", "너무 빠른 동작", "어깨가 올라감"]
    }


def create_exercise_07_entry(stats: Dict) -> Dict:
    """07번 - 다리 운동"""
    return {
        "exercise_id": "007",
        "exercise_code": "001-1-1-07",
        "exercise_name": "스탠딩 레그 스윙",
        "category": "맨몸운동",
        "posture": "서기",
        "difficulty": "초급",
        "description": "다리를 앞뒤로 흔들어 고관절 가동성을 향상시키는 운동",
        "key_joints": ["Back", "Left Hip", "Right Hip", "Left Knee", "Right Knee", "Left Ankle", "Right Ankle"],
        "key_angles": {
            "left_hip_angle": {
                "name": "좌측 힙 각도",
                "points": ["Back", "Left Hip", "Left Knee"],
                "ideal_mean": round(stats.get('left_hip_angle', {}).get('mean', 120.0), 1),
                "ideal_range": [90.0, 160.0],
                "tolerance": 20.0,
                "weight": 1.5
            },
            "right_hip_angle": {
                "name": "우측 힙 각도",
                "points": ["Back", "Right Hip", "Right Knee"],
                "ideal_mean": round(stats.get('right_hip_angle', {}).get('mean', 120.0), 1),
                "ideal_range": [90.0, 160.0],
                "tolerance": 20.0,
                "weight": 1.5
            },
            "left_knee_angle": {
                "name": "좌측 무릎 각도",
                "points": ["Left Hip", "Left Knee", "Left Ankle"],
                "ideal_mean": round(stats.get('left_knee_angle', {}).get('mean', 175.0), 1),
                "ideal_range": [165.0, 180.0],
                "tolerance": 10.0,
                "weight": 0.8
            },
            "right_knee_angle": {
                "name": "우측 무릎 각도",
                "points": ["Right Hip", "Right Knee", "Right Ankle"],
                "ideal_mean": round(stats.get('right_knee_angle', {}).get('mean', 175.0), 1),
                "ideal_range": [165.0, 180.0],
                "tolerance": 10.0,
                "weight": 0.8
            }
        },
        "motion_phases": [
            {"phase_id": 1, "phase_name": "시작 자세", "description": "한 발로 서세요", "duration_sec": 1.0, "key_checks": ["균형 잡기"]},
            {"phase_id": 2, "phase_name": "앞으로 스윙", "description": "다리를 앞으로 흔드세요", "duration_sec": 1.5, "key_checks": ["무릎 펴기"]},
            {"phase_id": 3, "phase_name": "뒤로 스윙", "description": "다리를 뒤로 흔드세요", "duration_sec": 1.5, "key_checks": ["무릎 펴기"]},
            {"phase_id": 4, "phase_name": "반복", "description": "리드미컬하게 반복하세요", "duration_sec": 3.0, "key_checks": ["부드러운 동작"]},
            {"phase_id": 5, "phase_name": "완료", "description": "다리를 내리세요", "duration_sec": 1.0, "key_checks": ["양발 지면에"]}
        ],
        "feedback_rules": [
            {"condition": "left_knee_angle < 165", "feedback": "왼쪽 무릎을 펴세요", "severity": "info"},
            {"condition": "right_knee_angle < 165", "feedback": "오른쪽 무릎을 펴세요", "severity": "info"}
        ],
        "common_mistakes": ["무릎이 굽혀짐", "너무 빠른 스윙", "균형을 잃음"]
    }


def main():
    base_dir = "PT-Pose-Data/PT_Pose/1.Training/Labeling/맨몸운동_Labeling_new_220128"
    
    exercises = {
        "02": ("맨몸운동_02", analyze_exercise_02, create_exercise_02_entry),
        "03": ("맨몸운동_03", analyze_exercise_03, create_exercise_03_entry),
        "04": ("맨몸운동_04", analyze_exercise_04, create_exercise_04_entry),
        "05": ("맨몸운동_05", analyze_exercise_05, create_exercise_05_entry),
        "06": ("맨몸운동_06", analyze_exercise_06, create_exercise_06_entry),
        "07": ("맨몸운동_07", analyze_exercise_07, create_exercise_07_entry),
    }
    
    print("=" * 60)
    print("운동 02~07번 통합 분석 시작")
    print("=" * 60)
    
    # 기존 exercise_reference.json 읽기
    reference_file = "assets/exercise_reference.json"
    with open(reference_file, 'r', encoding='utf-8') as f:
        reference_data = json.load(f)
    
    existing_ids = [ex['exercise_id'] for ex in reference_data['exercises']]
    
    # 각 운동 분석 및 추가
    for ex_num, (folder_name, analyze_func, create_func) in exercises.items():
        print(f"\n{'='*60}")
        print(f"운동 {ex_num}번 분석 중...")
        print(f"{'='*60}")
        
        data_dir = f"{base_dir}/{folder_name}"
        
        if not os.path.exists(data_dir):
            print(f"⚠️  경로를 찾을 수 없습니다: {data_dir}")
            continue
        
        # 데이터 분석
        statistics = analyze_func(data_dir)
        
        print(f"\n통계 결과:")
        for angle_name, stats in statistics.items():
            print(f"  {angle_name}: 평균 {stats['mean']:.1f}°, "
                  f"범위 {stats['min']:.1f}°~{stats['max']:.1f}°, "
                  f"샘플 {stats['count']}개")
        
        # JSON 항목 생성
        exercise_entry = create_func(statistics)
        
        # 기존 항목 확인 및 추가/업데이트
        if f"00{ex_num}" in existing_ids:
            for i, ex in enumerate(reference_data['exercises']):
                if ex['exercise_id'] == f"00{ex_num}":
                    reference_data['exercises'][i] = exercise_entry
                    print(f"✓ 운동 {ex_num}번 업데이트 완료")
                    break
        else:
            reference_data['exercises'].append(exercise_entry)
            print(f"✓ 운동 {ex_num}번 추가 완료")
    
    # 날짜 업데이트
    reference_data['last_updated'] = "2025-11-03"
    
    # 파일 저장
    with open(reference_file, 'w', encoding='utf-8') as f:
        json.dump(reference_data, f, ensure_ascii=False, indent=2)
    
    print(f"\n{'='*60}")
    print(f"✓ 완료! {reference_file} 업데이트됨")
    print(f"총 {len(reference_data['exercises'])}개 운동 등록")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()

