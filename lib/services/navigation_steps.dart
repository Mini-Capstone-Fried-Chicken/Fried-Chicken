import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A single navigation instruction row (like Google Maps steps).
class NavigationStep {
  final String instruction;
  final String? distanceText;
  final String? durationText;

  /// One of: walking, driving, bicycling, transit
  final String travelMode;
  final List<LatLng> points;

  /// Optional maneuver from Google (turn-left, turn-right, etc.)
  final String? maneuver;

  /// Transit extras (only for transit steps)
  final String? transitVehicleType; // BUS, SUBWAY, etc.
  final String? transitLineShortName; // e.g. 165
  final String? transitLineName; // e.g. "STM 165"
  final String? transitHeadsign; // destination direction

  const NavigationStep({
    required this.instruction,
    required this.travelMode,
    this.distanceText,
    this.durationText,
    this.maneuver,
    this.transitVehicleType,
    this.transitLineShortName,
    this.transitLineName,
    this.transitHeadsign,
    this.points = const [],
  });

  LatLng? get startPoint => points.isNotEmpty ? points.first : null;
  LatLng? get endPoint => points.isNotEmpty ? points.last : null;

  String get secondaryLine {
    final parts = <String>[];
    if (distanceText != null && distanceText!.trim().isNotEmpty) {
      parts.add(distanceText!.trim());
    }
    if (durationText != null && durationText!.trim().isNotEmpty) {
      parts.add(durationText!.trim());
    }
    return parts.join(' • ');
  }

  String get transitLabel {
    final fallbackLineName =
    transitLineName?.trim().isNotEmpty == true ? transitLineName!.trim() : null;
    final line = transitLineShortName?.trim().isNotEmpty == true
    ? transitLineShortName!.trim()
    : fallbackLineName;

    if (line == null) return 'Transit';
    final vehicle = transitVehicleType?.toUpperCase();
    if (vehicle == 'BUS') return 'Bus $line';
    if (_isRail(vehicle)) return 'Metro $line';
    return 'Transit $line';
  }

  static bool _isRail(String? t) {
    const railTypes = {
      'SUBWAY',
      'METRO_RAIL',
      'HEAVY_RAIL',
      'COMMUTER_TRAIN',
      'RAIL',
      'TRAM',
      'LIGHT_RAIL',
      'MONORAIL',
    };
    if (t == null) return false;
    return railTypes.contains(t.toUpperCase());
  }
}

/// A lightweight, UI-focused sheet/modal for navigation steps.
class NavigationStepsSheet extends StatelessWidget {
  final String title; // e.g. "Walking"
  final String? totalDuration;
  final String? totalDistance;
  final List<NavigationStep> steps;

  const NavigationStepsSheet({
    super.key,
    required this.title,
    required this.steps,
    this.totalDuration,
    this.totalDistance,
  });

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 10),

            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 10, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _HeaderBlock(
                      title: title,
                      subtitle: _headerSubtitle(totalDuration, totalDistance),
                      titleColor: burgundy,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: steps.isEmpty
                  ? const Center(
                      child: Text(
                        'No steps available',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                      itemCount: steps.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        return _StepTile(step: step);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _headerSubtitle(String? dur, String? dist) {
    final parts = <String>[];
    if (dur != null && dur.trim().isNotEmpty) parts.add(dur.trim());
    if (dist != null && dist.trim().isNotEmpty) parts.add(dist.trim());
    return parts.join(' • ');
  }
}

/// Call this to open the UI as a bottom sheet (recommended).
Future<void> showNavigationStepsModal(
  BuildContext context, {
  required String title,
  required List<NavigationStep> steps,
  String? totalDuration,
  String? totalDistance,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          // We wrap the sheet in a LayoutBuilder via Expanded ListView inside sheet,
          // so we don't need scrollController here.
          return NavigationStepsSheet(
            title: title,
            steps: steps,
            totalDuration: totalDuration,
            totalDistance: totalDistance,
          );
        },
      );
    },
  );
}

/// ---- UI bits ----

class _HeaderBlock extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color titleColor;

  const _HeaderBlock({
    required this.title,
    required this.subtitle,
    required this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle.isEmpty ? ' ' : subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final NavigationStep step;

  const _StepTile({required this.step});

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);

    final icon = _iconFor(step);
    final iconBg = step.travelMode == 'transit'
        ? Colors.black.withOpacity(0.06)
        : burgundy.withOpacity(0.12);
    final iconColor = step.travelMode == 'transit' ? Colors.black87 : burgundy;

    // For transit steps, prefer a transit label + headsign line.
    final mainText = step.travelMode == 'transit'
        ? step.transitLabel
        : step.instruction;

    final subLines = <String>[];
    if (step.travelMode == 'transit' &&
        step.transitHeadsign != null &&
        step.transitHeadsign!.trim().isNotEmpty) {
      subLines.add(step.transitHeadsign!.trim());
    }

    final secondary = step.secondaryLine;
    if (secondary.isNotEmpty) subLines.add(secondary);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon bubble
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.15,
                    ),
                  ),
                  if (subLines.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    for (final line in subLines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.60),
                            height: 1.15,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(NavigationStep s) {
    final mode = s.travelMode.toLowerCase();

    if (mode == 'walking') {
      // try to reflect maneuver a bit for walking too
      return _maneuverIcon(s.maneuver) ?? Icons.directions_walk;
    }
    if (mode == 'bicycling') {
      return _maneuverIcon(s.maneuver) ?? Icons.directions_bike;
    }
    if (mode == 'driving') {
      return _maneuverIcon(s.maneuver) ?? Icons.directions_car;
    }
    if (mode == 'transit') {
      final t = s.transitVehicleType?.toUpperCase();
      if (t == 'BUS') return Icons.directions_bus;
      if (NavigationStep._isRail(t)) return Icons.directions_subway;
      return Icons.directions_transit;
    }

    return Icons.navigation;
  }

  IconData? _maneuverIcon(String? m) {
    if (m == null) return null;
    final v = m.toLowerCase();

    if (v.contains('uturn')) return Icons.u_turn_left;
    if (v.contains('roundabout')) return Icons.roundabout_right;
    if (v.contains('merge')) return Icons.merge;
    if (v.contains('fork')) return Icons.call_split;

    if (v.contains('turn-left')) return Icons.turn_left;
    if (v.contains('turn-right')) return Icons.turn_right;
    if (v.contains('turn-sharp-left')) return Icons.turn_sharp_left;
    if (v.contains('turn-sharp-right')) return Icons.turn_sharp_right;
    if (v.contains('turn-slight-left')) return Icons.turn_slight_left;
    if (v.contains('turn-slight-right')) return Icons.turn_slight_right;

    if (v.contains('straight')) return Icons.straight;
    return null;
  }
}

class NavigationNextStepHeader extends StatelessWidget {
  final String modeLabel;
  final NavigationStep? nextStep;
  final String? nextDistance; // optional override
  final VoidCallback onStop;
  final VoidCallback onShowSteps;

  const NavigationNextStepHeader({
    super.key,
    required this.modeLabel,
    required this.nextStep,
    required this.onStop,
    required this.onShowSteps,
    this.nextDistance,
  });

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);

    final step = nextStep;
    final stepText = step != null
    ? (step.travelMode == 'transit' ? step.transitLabel : step.instruction)
    : null;
    final primary = stepText ?? 'Continue';

    final secondaryParts = <String>[];
    if (step != null &&
        step.travelMode == 'transit' &&
        step.transitHeadsign != null &&
        step.transitHeadsign!.trim().isNotEmpty) {
      secondaryParts.add(step.transitHeadsign!.trim());
    }
    final fallback = step?.distanceText;
    final dist = (nextDistance?.trim().isNotEmpty == true)
        ? nextDistance
        : fallback;
    if (dist != null && dist.trim().isNotEmpty) secondaryParts.add(dist.trim());

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Container(
          decoration: BoxDecoration(
            color: burgundy,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.navigation, color: Colors.white),
                ),
                const SizedBox(width: 10),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        secondaryParts.isEmpty
                            ? modeLabel
                            : secondaryParts.join(' • '),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    TextButton(
                      onPressed: onShowSteps,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Steps',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 2),
                    TextButton(
                      onPressed: onStop,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Stop',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---- Helpers for parsing Directions API step text ----

String stripHtml(String html) {
  // Remove tags
  final noTags = html.replaceAll(RegExp(r'<[^>]+>'), ' ');
  // Collapse spaces
  final collapsed = noTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  // Decode common entities (enough for Google instructions)
  return collapsed
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}
