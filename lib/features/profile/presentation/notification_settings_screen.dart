import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/color.dart';
import 'package:go_router/go_router.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  bool _workoutReminder = true;
  bool _mealReminder = true;
  bool _waterReminder = false;
  bool _achievementNotification = true;
  bool _weeklyReport = true;
  
  TimeOfDay _workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 18, minute: 30);
  
  int _waterReminderInterval = 2; // 시간 단위

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('알림 설정이 저장되었습니다'),
        backgroundColor: mainButtonColor,
      ),
    );
    context.pop();
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: backgroundColor,
        foregroundColor: mainButtonColor,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text(
              '저장',
              style: TextStyle(
                color: mainButtonColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 운동 알림
              const Text(
                '운동 알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('운동 시간 알림'),
                      subtitle: const Text('설정한 시간에 운동을 알려드립니다'),
                      value: _workoutReminder,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _workoutReminder = value;
                        });
                      },
                    ),
                    if (_workoutReminder) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('알림 시간'),
                        subtitle: Text(_formatTime(_workoutReminderTime)),
                        trailing: const Icon(Icons.access_time, color: subTextColor),
                        onTap: () => _selectTime(context, _workoutReminderTime, (time) {
                          setState(() {
                            _workoutReminderTime = time;
                          });
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 식사 알림
              const Text(
                '식사 알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('식사 시간 알림'),
                      subtitle: const Text('식사 시간을 알려드립니다'),
                      value: _mealReminder,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _mealReminder = value;
                        });
                      },
                    ),
                    if (_mealReminder) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('아침 식사'),
                        subtitle: Text(_formatTime(_breakfastTime)),
                        trailing: const Icon(Icons.access_time, color: subTextColor),
                        onTap: () => _selectTime(context, _breakfastTime, (time) {
                          setState(() {
                            _breakfastTime = time;
                          });
                        }),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('점심 식사'),
                        subtitle: Text(_formatTime(_lunchTime)),
                        trailing: const Icon(Icons.access_time, color: subTextColor),
                        onTap: () => _selectTime(context, _lunchTime, (time) {
                          setState(() {
                            _lunchTime = time;
                          });
                        }),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('저녁 식사'),
                        subtitle: Text(_formatTime(_dinnerTime)),
                        trailing: const Icon(Icons.access_time, color: subTextColor),
                        onTap: () => _selectTime(context, _dinnerTime, (time) {
                          setState(() {
                            _dinnerTime = time;
                          });
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 수분 섭취 알림
              const Text(
                '수분 섭취 알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('물 마시기 알림'),
                      subtitle: const Text('정기적으로 수분 섭취를 알려드립니다'),
                      value: _waterReminder,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _waterReminder = value;
                        });
                      },
                    ),
                    if (_waterReminder) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('알림 간격'),
                        subtitle: Text('$_waterReminderInterval시간마다'),
                        trailing: DropdownButton<int>(
                          value: _waterReminderInterval,
                          items: [1, 2, 3, 4].map((hour) {
                            return DropdownMenuItem(
                              value: hour,
                              child: Text('${hour}시간'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _waterReminderInterval = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 기타 알림
              const Text(
                '기타 알림',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: mainButtonColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('목표 달성 알림'),
                      subtitle: const Text('운동이나 식단 목표를 달성했을 때 알려드립니다'),
                      value: _achievementNotification,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _achievementNotification = value;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('주간 리포트'),
                      subtitle: const Text('매주 운동과 식단 결과를 요약해서 알려드립니다'),
                      value: _weeklyReport,
                      activeColor: mainButtonColor,
                      onChanged: (value) {
                        setState(() {
                          _weeklyReport = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // 저장 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  child: const Text(
                    '설정 저장하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
