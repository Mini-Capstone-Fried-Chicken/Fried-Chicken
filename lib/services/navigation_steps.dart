import 'package:campus_app/features/settings/app_settings.dart';
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
  final String? indoorFloorAssetPath;
  final String? indoorFloorLabel;
  final String? indoorTransitionMode;

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
    this.indoorFloorAssetPath,
    this.indoorFloorLabel,
    this.indoorTransitionMode,
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
    final fallbackLineName = transitLineName?.trim().isNotEmpty == true
        ? transitLineName!.trim()
        : null;
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
  final bool highContrastMode;

  const NavigationStepsSheet({
    super.key,
    required this.title,
    required this.steps,
    this.totalDuration,
    this.totalDistance,
    this.highContrastMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = highContrastMode
        ? Colors.black
        : const Color(0xFF76263D);
    final sheetBackground = highContrastMode
        ? const Color(0xFF89D9C2)
        : Colors.white;
    final dividerColor = highContrastMode ? Colors.black26 : null;
    final emptyTextColor = highContrastMode ? Colors.black54 : Colors.black54;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: sheetBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
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
                color: Colors.black.withValues(alpha: 0.12),
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
                      titleColor: titleColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            Divider(height: 1, color: dividerColor),

            // Content
            Expanded(
              child: steps.isEmpty
                  ? Center(
                      child: Text(
                        'No steps available',
                        style: TextStyle(color: emptyTextColor),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                      itemCount: steps.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        return _StepTile(
                          step: step,
                          highContrastMode: highContrastMode,
                        );
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
  bool highContrastMode = false,
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
            highContrastMode: highContrastMode,
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
  final bool highContrastMode;

  const _StepTile({required this.step, this.highContrastMode = false});

  @override
  Widget build(BuildContext context) {
    const burgundy = Color(0xFF76263D);

    final icon = _iconFor(step);
    final iconBg = highContrastMode
        ? Colors.black.withValues(alpha: 0.08)
        : step.travelMode == 'transit'
        ? Colors.black.withValues(alpha: 0.06)
        : burgundy.withValues(alpha: 0.12);
    final iconColor = highContrastMode
        ? Colors.black
        : step.travelMode == 'transit'
        ? Colors.black87
        : burgundy;
    final tileBackground = highContrastMode
        ? const Color(0xFF6CCEB5)
        : Colors.white;
    final tileBorder = highContrastMode
        ? Colors.black.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.06);
    final mainTextColor = highContrastMode ? Colors.black : Colors.black87;
    final secondaryTextColor = highContrastMode
        ? Colors.black.withValues(alpha: 0.72)
        : Colors.black.withValues(alpha: 0.6);

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
        color: tileBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tileBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mainTextColor,
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
                            color: secondaryTextColor,
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
    final indoorTransitionMode = s.indoorTransitionMode?.toLowerCase();
    if (indoorTransitionMode == 'stairs') {
      return Icons.stairs;
    }
    if (indoorTransitionMode == 'elevator') {
      return Icons.elevator;
    }
    if (indoorTransitionMode == 'escalator') {
      return Icons.escalator;
    }

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
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final bool canGoPrevious;
  final bool canGoNext;
  final String? progressLabel;
  final bool highContrastMode;

  const NavigationNextStepHeader({
    super.key,
    required this.modeLabel,
    required this.nextStep,
    required this.onStop,
    required this.onShowSteps,
    this.onPrevious,
    this.onNext,
    this.canGoPrevious = false,
    this.canGoNext = false,
    this.progressLabel,
    this.nextDistance,
    this.highContrastMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = highContrastMode
        ? AppUiColors.highContrastPrimary
        : const Color(0xFF76263D);
    final primaryText = highContrastMode ? Colors.black : Colors.white;
    final secondaryText = highContrastMode ? Colors.black54 : Colors.white70;
    final chipBg = highContrastMode
        ? const Color(0xFF5EBFA7)
        : Colors.white.withValues(alpha: 0.14);

    final step = nextStep;
    final stepLabel = step != null && step.travelMode == 'transit'
        ? step.transitLabel
        : step?.instruction;
    final primary = stepLabel ?? 'Continue';

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
    if (step?.indoorFloorLabel?.trim().isNotEmpty == true) {
      secondaryParts.add('Floor ${step!.indoorFloorLabel!.trim()}');
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.navigation, color: primaryText),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: primaryText,
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
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        TextButton(
                          onPressed: onShowSteps,
                          style: TextButton.styleFrom(
                            foregroundColor: primaryText,
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
                            foregroundColor: primaryText,
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
                if (onPrevious != null || onNext != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: canGoPrevious ? onPrevious : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryText,
                            side: BorderSide(color: secondaryText),
                          ),
                          child: const Text('Previous'),
                        ),
                      ),
                      if (progressLabel != null) ...[
                        const SizedBox(width: 10),
                        Text(
                          progressLabel!,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ] else
                        const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canGoNext ? onNext : null,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: highContrastMode
                                ? Colors.black
                                : const Color(0xFF76263D),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text('Next Step'),
                        ),
                      ),
                    ],
                  ),
                ],
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
