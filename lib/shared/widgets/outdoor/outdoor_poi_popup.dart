import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../../services/nearby_poi_service.dart';
import '../../../features/settings/app_settings.dart';

class OutdoorPoiPopup extends StatelessWidget {
  final PoiPlace poi;
  final VoidCallback onClose;
  final Future<void> Function() onGetDirections;
  final bool highContrastMode;

  const OutdoorPoiPopup({
    super.key,
    required this.poi,
    required this.onClose,
    required this.onGetDirections,
    this.highContrastMode = false,
  });

  IconData _categoryIcon(PoiCategory category) {
    switch (category) {
      case PoiCategory.cafe:
        return Icons.local_cafe;
      case PoiCategory.restaurant:
        return Icons.restaurant;
      case PoiCategory.pharmacy:
        return Icons.local_pharmacy;
      case PoiCategory.depanneur:
        return Icons.store;
    }
  }

  String _categoryLabel(PoiCategory category) {
    switch (category) {
      case PoiCategory.cafe:
        return 'Cafe';
      case PoiCategory.restaurant:
        return 'Restaurant';
      case PoiCategory.pharmacy:
        return 'Pharmacy';
      case PoiCategory.depanneur:
        return 'Dépanneur';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = highContrastMode ? Colors.black : const Color(0xFF76263D);
    final popupBackground = highContrastMode
        ? AppUiColors.highContrastPrimary
        : Colors.white;
    const primaryText = Colors.black;
    const secondaryText = Colors.black54;

    return Positioned(
      bottom: 160,
      left: 16,
      right: 16,
      child: Center(
        child: PointerInterceptor(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 300,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              decoration: BoxDecoration(
                color: popupBackground,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        key: const Key('poi_popup_close'),
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                        color: accent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                  Icon(_categoryIcon(poi.category), color: accent, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    poi.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _categoryLabel(poi.category),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const Key('poi_get_directions_button'),
                      onPressed: onGetDirections,
                      icon: const Icon(Icons.directions, size: 20),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: highContrastMode
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
