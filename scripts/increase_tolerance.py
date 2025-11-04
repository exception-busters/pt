#!/usr/bin/env python3
"""
exercise_reference.json의 모든 tolerance 값을 더 관대하게 조정
- 10.0 → 20.0 (2배)
- 12.0 → 24.0 (2배)
- 15.0 → 30.0 (2배)
- 20.0 → 35.0 (1.75배)
"""

import json

def increase_tolerance(file_path: str):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    total_updates = 0
    
    for exercise in data['exercises']:
        exercise_id = exercise['exercise_id']
        print(f"\n운동 {exercise_id}번 ({exercise['exercise_name']})")
        
        for angle_key, angle_info in exercise['key_angles'].items():
            old_tolerance = angle_info['tolerance']
            
            # tolerance 증가 (2배로)
            if old_tolerance <= 10.0:
                new_tolerance = 20.0
            elif old_tolerance <= 12.0:
                new_tolerance = 24.0
            elif old_tolerance <= 15.0:
                new_tolerance = 30.0
            elif old_tolerance <= 20.0:
                new_tolerance = 35.0
            else:
                new_tolerance = old_tolerance * 2.0
            
            angle_info['tolerance'] = new_tolerance
            total_updates += 1
            
            print(f"  - {angle_info['name']}: {old_tolerance}° → {new_tolerance}°")
    
    # 파일 저장
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✓ 총 {total_updates}개 각도의 tolerance 업데이트 완료!")
    print(f"✓ 점수 계산도 더 관대해졌습니다:")
    print(f"  - tolerance 내: 100점")
    print(f"  - tolerance의 2배: 100점 → 50점 (완만한 곡선)")
    print(f"  - tolerance의 3배: 50점 → 10점")
    print(f"  - 그 이상: 최소 10점 보장")

if __name__ == "__main__":
    increase_tolerance("assets/exercise_reference.json")

