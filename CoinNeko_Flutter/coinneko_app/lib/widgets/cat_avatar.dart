// frontend/lib/widgets/cat_avatar.dart
import 'package:flutter/material.dart';

class CatAvatar extends StatelessWidget {
  final String? imageUrl;
  final String emoji;
  final double size;

  const CatAvatar({
    super.key,
    required this.imageUrl,
    required this.emoji,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.2),
          child: Image.network(
            imageUrl!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE8FA),
                  borderRadius: BorderRadius.circular(size * 0.2),
                ),
                child: Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF7C5CBF),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              // 圖片載入失敗就 fallback 回 emoji
              return Text(
                emoji,
                style: TextStyle(fontSize: size * 0.8),
              );
            },
          ),
        ),
      );
    }

    // 沒有圖片就直接顯示 emoji
    return Text(
      emoji,
      style: TextStyle(fontSize: size),
    );
  }
}