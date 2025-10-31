#!/usr/bin/env python3
"""
PT Pose Data에서 운동 정답 데이터를 추출하는 스크립트

사용법:
    python scripts/extract_reference_data.py \
        --input PT-Pose-Data/PT_Pose/1.Training/Labeling/맨몸운동_Labeling_new_220128/맨몸운동_01 \
        --output assets/exercise_reference.json \
        --exercise-id "001-1-1-01"
"""

import json
import argparse
import os
from pathlib import Path
from typing import List, Dict, Any
import math
import statistics

def load_3d_json_files(directory: str) -> List[Dict]:
    """3D JSON 파일들을 로드"""
    json_files = []
    directory_path = Path(directory)
    
    for json_file in directory_path.rglob('*-3d.json'):
        try:
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                json_files.append(data)
        except Exception as e:
            print(f"파일 로드 실패 {json_file}: {e}")
    
    return json_files

def calculate_angle(p1: Dict, p2: Dict, p3: Dict) -> float:
    """3점으로 각도 계산 (degree)"""
    # 벡터 계산
    radians = math.atan2(p3['y'] - p2['y'], p3['x'] - p2['x']) - \
              math.atan2(p1['y'] - p2['y'], p1['x'] - p2['x'])
    
    angle = abs(radians * 180.0 / math.pi)
    if angle > 180.0:
        angle = 360.0 - angle
    
    return angle

def extract_angles_from_frame(frame: Dict) -> Dict[str, float]:
    """프레임에서 주요 각도 추출"""
    pts = frame['pts']
    angles = {}
    
    try:
        # 좌측 상체 기울기
        if 'Left Shoulder' in pts and 'Waist' in pts and 'Right Shoulder' in pts:
            angles['left_body_tilt'] = calculate_angle(
                pts['Left Shoulder'], pts['Waist'], pts['Right Shoulder']
            )
        
        # 우측 상체 기울기
        if 'Right Shoulder' in pts and 'Waist' in pts and 'Left Shoulder' in pts:
            angles['right_body_tilt'] = calculate_angle(
                pts['Right Shoulder'], pts['Waist'], pts['Left Shoulder']
            )
        
        # 좌측 팔 각도
        if 'Left Shoulder' in pts and 'Left Elbow' in pts and 'Left Wrist' in pts:
            angles['left_arm_angle'] = calculate_angle(
                pts['Left Shoulder'], pts['Left Elbow'], pts['Left Wrist']
            )
        
        # 우측 팔 각도
        if 'Right Shoulder' in pts and 'Right Elbow' in pts and 'Right Wrist' in pts:
            angles['right_arm_angle'] = calculate_angle(
                pts['Right Shoulder'], pts['Right Elbow'], pts['Right Wrist']
            )
        
        # 좌측 무릎 각도
        if 'Left Hip' in pts and 'Left Knee' in pts and 'Left Ankle' in pts:
            angles['left_knee_angle'] = calculate_angle(
                pts['Left Hip'], pts['Left Knee'], pts['Left Ankle']
            )
        
        # 우측 무릎 각도
        if 'Right Hip' in pts and 'Right Knee' in pts and 'Right Ankle' in pts:
            angles['right_knee_angle'] = calculate_angle(
                pts['Right Hip'], pts['Right Knee'], pts['Right Ankle']
            )
    except Exception as e:
        print(f"각도 계산 오류: {e}")
    
    return angles

def analyze_exercises(json_files: List[Dict]) -> Dict[str, Any]:
    """운동 데이터 통계 분석"""
    all_angles = {
        'left_body_tilt': [],
        'right_body_tilt': [],
        'left_arm_angle': [],
        'right_arm_angle': [],
        'left_knee_angle': [],
        'right_knee_angle': [],
    }
    
    # 모든 프레임에서 각도 추출
    for json_data in json_files:
        if 'frames' not in json_data:
            continue
        
        for frame in json_data['frames']:
            angles = extract_angles_from_frame(frame)
            for key, value in angles.items():
                if key in all_angles:
                    all_angles[key].append(value)
    
    # 통계 계산
    stats = {}
    for angle_key, values in all_angles.items():
        if len(values) > 0:
            mean_val = statistics.mean(values)
            std_val = statistics.stdev(values) if len(values) > 1 else 0
            
            stats[angle_key] = {
                'mean': mean_val,
                'std': std_val,
                'min': min(values),
                'max': max(values),
                'count': len(values)
            }
    
    return stats

def generate_exercise_reference(stats: Dict, exercise_id: str) -> Dict:
    """정답 JSON 생성"""
    
    # 각도 이름 매핑
    angle_names = {
        'left_body_tilt': '좌측 상체 기울기',
        'right_body_tilt': '우측 상체 기울기',
        'left_arm_angle': '좌측 팔 각도',
        'right_arm_angle': '우측 팔 각도',
        'left_knee_angle': '좌측 무릎 각도',
        'right_knee_angle': '우측 무릎 각도',
    }
    
    # 각도 포인트 매핑
    angle_points = {
        'left_body_tilt': ['Left Shoulder', 'Waist', 'Right Shoulder'],
        'right_body_tilt': ['Right Shoulder', 'Waist', 'Left Shoulder'],
        'left_arm_angle': ['Left Shoulder', 'Left Elbow', 'Left Wrist'],
        'right_arm_angle': ['Right Shoulder', 'Right Elbow', 'Right Wrist'],
        'left_knee_angle': ['Left Hip', 'Left Knee', 'Left Ankle'],
        'right_knee_angle': ['Right Hip', 'Right Knee', 'Right Ankle'],
    }
    
    # 가중치 설정
    angle_weights = {
        'left_body_tilt': 1.0,
        'right_body_tilt': 1.0,
        'left_arm_angle': 0.5,
        'right_arm_angle': 0.5,
        'left_knee_angle': 0.3,
        'right_knee_angle': 0.3,
    }
    
    # key_angles 생성
    key_angles = {}
    for angle_key, stat in stats.items():
        mean_val = stat['mean']
        std_val = stat['std']
        tolerance = max(10.0, std_val * 2)  # 최소 10도 tolerance
        
        key_angles[angle_key] = {
            'name': angle_names.get(angle_key, angle_key),
            'points': angle_points.get(angle_key, []),
            'ideal_mean': round(mean_val, 1),
            'ideal_range': [
                round(mean_val - tolerance, 1),
                round(mean_val + tolerance, 1)
            ],
            'tolerance': round(tolerance, 1),
            'weight': angle_weights.get(angle_key, 0.5)
        }
    
    return {
        'version': '1.0',
        'last_updated': '2025-10-31',
        'exercises': [
            {
                'exercise_id': exercise_id,
                'exercise_code': exercise_id,
                'exercise_name': '스탠딩 사이드 크런치',
                'category': '맨몸운동',
                'posture': '선 자세',
                'difficulty': '초급',
                'description': '서서 상체를 좌우로 기울여 복사근을 자극하는 운동',
                'key_joints': [
                    'Left Shoulder', 'Right Shoulder',
                    'Left Elbow', 'Right Elbow',
                    'Waist', 'Neck',
                    'Left Hip', 'Right Hip',
                    'Left Knee', 'Right Knee'
                ],
                'key_angles': key_angles,
                'motion_phases': [
                    {
                        'phase_id': 1,
                        'phase_name': '시작 자세',
                        'description': '양발을 어깨 너비로 벌리고 서서 양손을 머리 뒤로',
                        'duration_sec': 1.0,
                        'key_checks': ['body_upright', 'arms_raised', 'feet_stable']
                    },
                    {
                        'phase_id': 2,
                        'phase_name': '좌측 굽히기',
                        'description': '상체를 왼쪽으로 천천히 기울이기',
                        'duration_sec': 1.5,
                        'key_checks': ['left_tilt_active', 'no_forward_bend', 'knee_stable']
                    },
                    {
                        'phase_id': 3,
                        'phase_name': '중앙 복귀',
                        'description': '천천히 시작 자세로 돌아오기',
                        'duration_sec': 1.0,
                        'key_checks': ['body_upright', 'smooth_motion']
                    },
                    {
                        'phase_id': 4,
                        'phase_name': '우측 굽히기',
                        'description': '상체를 오른쪽으로 천천히 기울이기',
                        'duration_sec': 1.5,
                        'key_checks': ['right_tilt_active', 'no_forward_bend', 'knee_stable']
                    },
                    {
                        'phase_id': 5,
                        'phase_name': '완료',
                        'description': '시작 자세로 복귀',
                        'duration_sec': 1.0,
                        'key_checks': ['body_upright']
                    }
                ],
                'feedback_rules': [
                    {
                        'condition': 'left_body_tilt < 145',
                        'feedback': '좌측으로 너무 많이 기울였습니다',
                        'severity': 'warning'
                    },
                    {
                        'condition': 'left_body_tilt > 175',
                        'feedback': '좌측으로 더 기울여주세요',
                        'severity': 'info'
                    },
                    {
                        'condition': 'left_knee_angle < 160',
                        'feedback': '무릎을 쭉 펴주세요',
                        'severity': 'warning'
                    }
                ],
                'common_mistakes': [
                    '무릎을 구부림',
                    '앞으로 숙임',
                    '양손이 머리에서 떨어짐',
                    '골반이 틀어짐'
                ]
            }
        ]
    }

def main():
    parser = argparse.ArgumentParser(description='PT Pose Data 정답 추출')
    parser.add_argument('--input', required=True, help='입력 디렉토리 경로')
    parser.add_argument('--output', required=True, help='출력 JSON 파일 경로')
    parser.add_argument('--exercise-id', required=True, help='운동 ID (예: 001-1-1-01)')
    
    args = parser.parse_args()
    
    print(f"데이터 로드 중: {args.input}")
    json_files = load_3d_json_files(args.input)
    print(f"로드된 파일 수: {len(json_files)}")
    
    if len(json_files) == 0:
        print("⚠ 3D JSON 파일을 찾을 수 없습니다!")
        return
    
    print("각도 통계 분석 중...")
    stats = analyze_exercises(json_files)
    
    print("\n=== 분석 결과 ===")
    for angle_key, stat in stats.items():
        print(f"{angle_key}:")
        print(f"  평균: {stat['mean']:.1f}°")
        print(f"  표준편차: {stat['std']:.1f}°")
        print(f"  범위: {stat['min']:.1f}° ~ {stat['max']:.1f}°")
        print(f"  샘플 수: {stat['count']}")
    
    print(f"\n정답 JSON 생성 중...")
    reference_data = generate_exercise_reference(stats, args.exercise_id)
    
    # 출력 디렉토리 생성
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # JSON 저장
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(reference_data, f, ensure_ascii=False, indent=2)
    
    print(f"✓ 정답 데이터 저장 완료: {args.output}")

if __name__ == '__main__':
    main()


