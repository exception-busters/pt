import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../../auth/application/auth_providers.dart';

class MealData {
  final String food;
  final String calories;

  MealData({required this.food, required this.calories});
}

class DietData {
  final String date;
  final MealData? breakfast;
  final MealData? lunch;
  final MealData? dinner;

  DietData({
    required this.date,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  DietData copyWith({
    String? date,
    MealData? breakfast,
    MealData? lunch,
    MealData? dinner,
  }) {
    return DietData(
      date: date ?? this.date,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
    );
  }

  int get totalCalories {
    int total = 0;
    if (breakfast != null) {
      total += int.tryParse(breakfast!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    if (lunch != null) {
      total += int.tryParse(lunch!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    if (dinner != null) {
      total += int.tryParse(dinner!.calories.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }
    return total;
  }
}

class DietController extends StateNotifier<DietData> {
  DietController(this._ref) : super(_getInitialData()) {
    _loadDietData();
    
    // 인증 상태 변화 감지
    _ref.listen(authControllerProvider, (previous, next) {
      if (previous?.isLoggedIn == true && !next.isLoggedIn) {
        // 로그아웃 시 상태 초기화
        state = _getInitialData();
      } else if (previous?.isLoggedIn == false && next.isLoggedIn) {
        // 로그인 시 해당 사용자의 다이어트 데이터 로드
        _loadDietData();
      }
    });
  }

  final Ref _ref;

  static DietData _getInitialData() {
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return DietData(date: dateString);
  }

  String _getUserDietKey() {
    final user = Supabase.instance.client.auth.currentUser;
    final today = DateTime.now();
    final dateString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return user != null ? 'diet_data_${user.id}_$dateString' : 'diet_data_default_$dateString';
  }

  Future<void> _loadDietData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dietJson = prefs.getString(_getUserDietKey());
      if (dietJson != null) {
        final dietMap = json.decode(dietJson);
        state = DietData(
          date: dietMap['date'],
          breakfast: dietMap['breakfast'] != null 
              ? MealData(food: dietMap['breakfast']['food'], calories: dietMap['breakfast']['calories'])
              : null,
          lunch: dietMap['lunch'] != null 
              ? MealData(food: dietMap['lunch']['food'], calories: dietMap['lunch']['calories'])
              : null,
          dinner: dietMap['dinner'] != null 
              ? MealData(food: dietMap['dinner']['food'], calories: dietMap['dinner']['calories'])
              : null,
        );
      }
    } catch (e) {
      print('다이어트 데이터 로드 실패: $e');
    }
  }

  Future<void> _saveDietData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dietMap = {
        'date': state.date,
        'breakfast': state.breakfast != null 
            ? {'food': state.breakfast!.food, 'calories': state.breakfast!.calories}
            : null,
        'lunch': state.lunch != null 
            ? {'food': state.lunch!.food, 'calories': state.lunch!.calories}
            : null,
        'dinner': state.dinner != null 
            ? {'food': state.dinner!.food, 'calories': state.dinner!.calories}
            : null,
      };
      await prefs.setString(_getUserDietKey(), json.encode(dietMap));
    } catch (e) {
      print('다이어트 데이터 저장 실패: $e');
    }
  }

  void updateMeal(String mealType, String food, String calories) {
    final mealData = MealData(food: food, calories: calories);
    
    switch (mealType) {
      case '아침':
        state = state.copyWith(breakfast: mealData);
        break;
      case '점심':
        state = state.copyWith(lunch: mealData);
        break;
      case '저녁':
        state = state.copyWith(dinner: mealData);
        break;
    }
    
    // 데이터 저장
    _saveDietData();
  }

  void checkAndResetIfNewDay() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    if (state.date != today) {
      state = DietData(date: today);
      _saveDietData();
    }
  }

  MealData? getMealData(String mealType) {
    switch (mealType) {
      case '아침':
        return state.breakfast;
      case '점심':
        return state.lunch;
      case '저녁':
        return state.dinner;
      default:
        return null;
    }
  }
}

final dietControllerProvider = StateNotifierProvider<DietController, DietData>(
  (ref) => DietController(ref),
);