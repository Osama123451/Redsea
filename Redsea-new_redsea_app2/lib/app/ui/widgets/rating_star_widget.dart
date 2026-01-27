import 'package:flutter/material.dart';

/// ويدجت عرض التقييم بالنجوم
/// يدعم وضع العرض فقط والوضع التفاعلي
class RatingStarWidget extends StatelessWidget {
  final double rating;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool interactive;
  final ValueChanged<double>? onRatingChanged;
  final bool showValue;

  const RatingStarWidget({
    super.key,
    required this.rating,
    this.size = 24,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.interactive = false,
    this.onRatingChanged,
    this.showValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          final starValue = index + 1;
          IconData icon;
          Color color;

          if (rating >= starValue) {
            icon = Icons.star;
            color = activeColor;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half;
            color = activeColor;
          } else {
            icon = Icons.star_border;
            color = inactiveColor;
          }

          return GestureDetector(
            onTap: interactive
                ? () => onRatingChanged?.call(starValue.toDouble())
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                icon,
                size: size,
                color: color,
              ),
            ),
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.7,
              fontWeight: FontWeight.bold,
              color: activeColor,
            ),
          ),
        ],
      ],
    );
  }
}

/// ويدجت تقييم تفاعلي كامل مع عنوان
class InteractiveRatingWidget extends StatefulWidget {
  final double initialRating;
  final ValueChanged<double> onRatingChanged;
  final String? label;

  const InteractiveRatingWidget({
    super.key,
    this.initialRating = 0,
    required this.onRatingChanged,
    this.label,
  });

  @override
  State<InteractiveRatingWidget> createState() =>
      _InteractiveRatingWidgetState();
}

class _InteractiveRatingWidgetState extends State<InteractiveRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _currentRating = starValue.toDouble();
                });
                widget.onRatingChanged(_currentRating);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  _currentRating >= starValue ? Icons.star : Icons.star_border,
                  size: 40,
                  color: _currentRating >= starValue
                      ? Colors.amber
                      : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _getRatingText(),
          style: TextStyle(
            fontSize: 14,
            color: _currentRating > 0 ? Colors.amber.shade700 : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _getRatingText() {
    switch (_currentRating.toInt()) {
      case 1:
        return 'ضعيف';
      case 2:
        return 'مقبول';
      case 3:
        return 'جيد';
      case 4:
        return 'جيد جداً';
      case 5:
        return 'ممتاز';
      default:
        return 'اختر تقييمك';
    }
  }
}
