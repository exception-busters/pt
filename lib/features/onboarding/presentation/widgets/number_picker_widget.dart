import 'package:flutter/material.dart';
import 'package:flutter_application_1/color.dart';

class NumberPickerWidget extends StatefulWidget {
  final String label;
  final String unit;
  final int minValue;
  final int maxValue;
  final int initialValue;
  final ValueChanged<int> onChanged;

  const NumberPickerWidget({
    super.key,
    required this.label,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<NumberPickerWidget> createState() => _NumberPickerWidgetState();
}

class _NumberPickerWidgetState extends State<NumberPickerWidget> {
  late int currentValue;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    currentValue = widget.initialValue;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateValue(int newValue) {
    if (newValue >= widget.minValue && newValue <= widget.maxValue) {
      setState(() {
        currentValue = newValue;
      });
      widget.onChanged(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: mainButtonColor,
            ),
          ),
          const SizedBox(height: 12),
          
          // 숫자 선택 영역
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: mainButtonColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // 감소 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateValue(currentValue - 1),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: borderColor),
                        ),
                      ),
                      child: const Icon(
                        Icons.remove,
                        color: mainButtonColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                
                // 현재 값 표시
                Expanded(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$currentValue',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: mainButtonColor,
                          ),
                        ),
                        Text(
                          widget.unit,
                          style: const TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // 증가 버튼
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateValue(currentValue + 1),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: borderColor),
                        ),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: mainButtonColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 범위 표시
          Text(
            '${widget.minValue} - ${widget.maxValue} ${widget.unit}',
            style: const TextStyle(
              fontSize: 10,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}