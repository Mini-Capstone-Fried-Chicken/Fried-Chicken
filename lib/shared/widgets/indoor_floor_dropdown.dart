import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../../services/indoor_maps/indoor_floor_config.dart';

class IndoorFloorDropdown extends StatelessWidget {
  final bool visible;
  final List<IndoorFloorOption> floors;
  final String? selectedAssetPath;
  final ValueChanged<String> onChanged;

  const IndoorFloorDropdown({
    super.key,
    required this.visible,
    required this.floors,
    required this.selectedAssetPath,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible || floors.isEmpty) return const SizedBox.shrink();

    final value = selectedAssetPath ?? floors.first.assetPath;

    return Align(
      alignment: Alignment.centerRight,
      child: PointerInterceptor(
        child: IntrinsicWidth(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1D3B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isDense: true,
                  dropdownColor: const Color(0xFF8B1D3B),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  items: floors
                      .map(
                        (f) => DropdownMenuItem<String>(
                          value: f.assetPath,
                          child: Text(
                            f.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (asset) {
                    if (asset == null) return;
                    onChanged(asset);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}