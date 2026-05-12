import 'package:flutter/material.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

class PointsBanner extends StatelessWidget {
  const PointsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: SupabaseService.myPointsStream(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.firstOrNull;
        final points  = profile?['total_points'] as int? ?? 0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, Color(0xFF388E3C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,          // ← no unbounded height
            children: [
              // Label row
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Total Verified Points',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Big animated number
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  '$points',
                  key: ValueKey(points),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
              ),

              Text(
                'pts',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white60,
                      fontSize: 16,
                    ),
              ),

              const SizedBox(height: 14),

              // Live badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Live updates',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
