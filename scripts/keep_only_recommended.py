#!/usr/bin/env python3
"""
추천된 5개 운동만 남기고 나머지 삭제
- 유지: 01, 02, 03, 04, 08
- 삭제: 05, 06, 07
"""

import json

def keep_only_recommended(file_path: str):
    with open(file_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # 유지할 운동 ID
    keep_ids = ["001", "002", "003", "004", "008"]
    
    # 원본 운동 수
    original_count = len(data['exercises'])
    
    # 필터링
    filtered_exercises = [
        ex for ex in data['exercises']
        if ex['exercise_id'] in keep_ids
    ]
    
    # ID 순으로 정렬
    filtered_exercises.sort(key=lambda x: x['exercise_id'])
    
    print("=" * 60)
    print("추천 5개 운동만 유지")
    print("=" * 60)
    print(f"\n원본: {original_count}개 운동")
    print(f"유지: {len(filtered_exercises)}개 운동")
    print(f"삭제: {original_count - len(filtered_exercises)}개 운동")
    
    print("\n✅ 유지되는 운동:")
    for ex in filtered_exercises:
        print(f"  - {ex['exercise_id']}: {ex['exercise_name']} ({ex['difficulty']})")
    
    print("\n❌ 삭제되는 운동:")
    deleted = [ex for ex in data['exercises'] if ex['exercise_id'] not in keep_ids]
    for ex in deleted:
        print(f"  - {ex['exercise_id']}: {ex['exercise_name']} ({ex['difficulty']})")
    
    # 업데이트
    data['exercises'] = filtered_exercises
    data['last_updated'] = "2025-11-03"
    
    # 저장
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"\n✓ 완료! {file_path} 업데이트됨")
    print(f"최종 운동 수: {len(filtered_exercises)}개")
    print("=" * 60)

if __name__ == "__main__":
    keep_only_recommended("assets/exercise_reference.json")

