import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';

enum WalkState { idle, active, stopped }

class WalkScreen extends StatefulWidget {
  const WalkScreen({super.key});

  @override
  State<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends State<WalkScreen> {
  WalkState _state = WalkState.idle;
  double _distanceKm = 0.0;
  int _durationSeconds = 0;
  bool _saving = false;

  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;
  Timer? _timer;

  int get _points => (_distanceKm * 10).floor();

  @override
  void dispose() {
    _positionSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<bool> _checkPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission denied. Enable it in Settings.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return false;
    }
    return perm == LocationPermission.whileInUse ||
        perm == LocationPermission.always;
  }

  Future<void> _startWalk() async {
    final ok = await _checkPermission();
    if (!ok) return;

    setState(() {
      _state = WalkState.active;
      _distanceKm = 0.0;
      _durationSeconds = 0;
      _lastPosition = null;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _durationSeconds++);
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen((pos) {
      if (_lastPosition != null) {
        final delta = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          pos.latitude,
          pos.longitude,
        );
        if (mounted) setState(() => _distanceKm += delta / 1000.0);
      }
      _lastPosition = pos;
    });
  }

  Future<void> _stopWalk() async {
    _positionSub?.cancel();
    _timer?.cancel();
    setState(() => _state = WalkState.stopped);
  }

  Future<void> _saveWalk() async {
    if (_points == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Walk at least 100 m to earn points.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await SupabaseService.insertWalkActivity(
        distanceKm: _distanceKm,
        points: _points,
        durationSeconds: _durationSeconds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 +$_points points saved!'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving walk: $e'),
              backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDuration(int s) {
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk'),
        leading: BackButton(onPressed: () {
          if (_state == WalkState.active) _stopWalk();
          context.pop();
        }),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Stats row — equal width, no overflow ───────────────────────
              IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Distance',
                        value: '${_distanceKm.toStringAsFixed(2)} km',
                        icon: Icons.route_rounded,
                        color: AppTheme.walkBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Time',
                        value: _formatDuration(_durationSeconds),
                        icon: Icons.timer_rounded,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),

              const SizedBox(height: 16),

              // ── Points card ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 28, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, Color(0xFF388E3C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Points Earned',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        '$_points',
                        key: ValueKey(_points),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      'pts',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms),

              const Spacer(),

              // ── Buttons ────────────────────────────────────────────────────
              if (_state == WalkState.idle)
                _BigButton(
                  label: 'Start Walking',
                  icon: Icons.play_arrow_rounded,
                  color: AppTheme.walkBlue,
                  onTap: _startWalk,
                ).animate().fadeIn(delay: 300.ms)
              else if (_state == WalkState.active) ...[
                const _PulsingIndicator(),
                const SizedBox(height: 20),
                _BigButton(
                  label: 'Stop Walking',
                  icon: Icons.stop_rounded,
                  color: AppTheme.errorRed,
                  onTap: _stopWalk,
                ),
              ] else ...[
                _BigButton(
                  label: _saving ? 'Saving…' : 'Save & Earn Points',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen,
                  onTap: _saving ? null : _saveWalk,
                ).animate().fadeIn(),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      'Discard',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: color, fontSize: 20),
            overflow: TextOverflow.ellipsis,
          ),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        icon: Icon(icon, size: 26),
        label: Text(
          label,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PulsingIndicator extends StatefulWidget {
  const _PulsingIndicator();

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _anim,
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.walkBlue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_walk_rounded,
              color: AppTheme.walkBlue, size: 40),
        ),
      ),
    );
  }
}
