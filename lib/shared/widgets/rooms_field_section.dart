import 'package:flutter/material.dart';
import '../../services/indoor_maps/indoor_map_repository.dart';

const Color validGreen = Color(0xFF4CAF50);
const Color invalidRed = Color(0xFFE53935);

class RoomFieldsSection extends StatefulWidget {
  final String? buildingCode;
  final TextEditingController originRoomController;
  final TextEditingController destinationRoomController;
  final Function(String buildingCode, String roomCode)? onDestinationValid;
  final Function(String buildingCode, String roomCode)? onStartValid;
  final Function(String buildingCode, String roomCode)?
  onDestinationRoomSubmitted;
  final bool? initialDestinationValid;
  final bool? initialStartValid;
  final bool showOriginRoom;
  final bool showDestinationRoom;
  final bool enabled;

  const RoomFieldsSection({
    super.key,
    required this.buildingCode,
    required this.originRoomController,
    required this.destinationRoomController,
    this.onDestinationValid,
    this.onStartValid,
    this.onDestinationRoomSubmitted,
    this.initialDestinationValid,
    this.initialStartValid,
    this.showDestinationRoom = false,
    this.showOriginRoom = false,
    this.enabled = true,
  });

  @override
  State<RoomFieldsSection> createState() => _RoomFieldsSectionState();
}

class _RoomFieldsSectionState extends State<RoomFieldsSection> {
  bool _startRoomIsValid = false;
  bool _destinationRoomIsValid = false;

  final _indoorRepository = IndoorMapRepository();

  @override
  void initState() {
    super.initState();
    // Initialize with passed validation state if available
    _startRoomIsValid = widget.initialStartValid ?? false;
    _destinationRoomIsValid = widget.initialDestinationValid ?? false;
    // Listen to destination room controller changes
    widget.destinationRoomController.addListener(_onDestinationRoomChanged);
  }

  void _onDestinationRoomChanged() {
    final text = widget.destinationRoomController.text;

    // If the field is now empty, clear the validation and marker
    if (text.isEmpty) {
      setState(() {
        _destinationRoomIsValid = false;
      });
      // Call the callback with empty values to clear the marker
      widget.onDestinationRoomSubmitted?.call('', '');
    }
  }

  bool get _hasBuilding =>
      widget.buildingCode != null && widget.buildingCode!.isNotEmpty;

  /// Checks room validity when user presses Enter
  Future<void> _checkStartRoom(String roomCode) async {
    if (!_hasBuilding || roomCode.isEmpty) return;

    final isValid = await _indoorRepository.roomExists(
      widget.buildingCode!,
      roomCode,
    );

    if (mounted) {
      setState(() => _startRoomIsValid = isValid);
    }

    if (isValid) {
      widget.onStartValid?.call(widget.buildingCode!, roomCode);
    } else {
      // Clear if invalid
      widget.originRoomController.clear();
    }
  }

  Future<void> _checkDestinationRoom(String roomCode) async {
    print('[DEBUG RoomFieldsSection] _checkDestinationRoom called');
    print('[DEBUG RoomFieldsSection] roomCode: $roomCode');
    print('[DEBUG RoomFieldsSection] buildingCode: ${widget.buildingCode}');
    print('[DEBUG RoomFieldsSection] _hasBuilding: $_hasBuilding');
    if (!_hasBuilding || roomCode.isEmpty) {
      print('[DEBUG RoomFieldsSection] Early return');
      return;
    }

    final isValid = await _indoorRepository.roomExists(
      widget.buildingCode!,
      roomCode,
    );

    print('[DEBUG RoomFieldsSection] Room validation result: $isValid');

    if (mounted) {
      setState(() => _destinationRoomIsValid = isValid);
    }

    if (isValid) {
      print('[DEBUG RoomFieldsSection] Room is valid, calling callbacks');
      print('[DEBUG RoomFieldsSection] Calling onDestinationValid');
      widget.onDestinationValid?.call(widget.buildingCode!, roomCode);
      print('[DEBUG RoomFieldsSection] Calling onDestinationRoomSubmitted');
      widget.onDestinationRoomSubmitted?.call(widget.buildingCode!, roomCode);
      print('[DEBUG RoomFieldsSection] Callbacks called successfully');
    } else {
      // Clear if invalid
      print('[DEBUG RoomFieldsSection] Room is invalid');
      widget.destinationRoomController.clear();
      widget.onDestinationRoomSubmitted?.call('', '');
    }
  }

  Color _getBorderColor(bool isValid, bool hasInput) {
    if (!hasInput) return Colors.grey[400]!;
    return isValid ? validGreen : invalidRed;
  }

  Widget _buildSuffixIcon(bool isValid, bool hasInput) {
    if (!hasInput) return const SizedBox.shrink();
    return Icon(
      isValid ? Icons.check_circle : Icons.cancel,
      color: isValid ? validGreen : invalidRed,
      size: 20,
    );
  }

  @override
  void didUpdateWidget(RoomFieldsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialDestinationValid != widget.initialDestinationValid &&
        widget.initialDestinationValid != null) {
      setState(() {
        _destinationRoomIsValid = widget.initialDestinationValid!;
      });
    }
    if (oldWidget.initialStartValid != widget.initialStartValid &&
        widget.initialStartValid != null) {
      setState(() {
        _startRoomIsValid = widget.initialStartValid!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider line above the fields
        Container(height: 1.5, color: const Color.fromARGB(175, 179, 133, 133)),
        const SizedBox(height: 12),
        Row(
          children: [
            // Origin room
            Expanded(
              child: _RoomTextField(
                controller: widget.originRoomController,
                hint: "Origin room",
                borderColor: _getBorderColor(
                  _startRoomIsValid,
                  widget.originRoomController.text.isNotEmpty,
                ),
                suffixIcon: _buildSuffixIcon(
                  _startRoomIsValid,
                  widget.originRoomController.text.isNotEmpty,
                ),
                onSubmitted: _checkStartRoom,
                enabled: widget.showOriginRoom,
              ),
            ),
            const SizedBox(width: 8),
            // Destination room
            Expanded(
              child: _RoomTextField(
                controller: widget.destinationRoomController,
                hint: "Destination room",
                borderColor: _getBorderColor(
                  _destinationRoomIsValid,
                  widget.destinationRoomController.text.isNotEmpty,
                ),
                suffixIcon: _buildSuffixIcon(
                  _destinationRoomIsValid,
                  widget.destinationRoomController.text.isNotEmpty,
                ),
                onSubmitted: _checkDestinationRoom,
                enabled: widget.showDestinationRoom,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color borderColor;
  final Function(String) onSubmitted;
  final Widget? suffixIcon;
  final bool enabled;

  const _RoomTextField({
    required this.controller,
    required this.hint,
    required this.borderColor,
    required this.onSubmitted,
    this.suffixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: enabled ? onSubmitted : (_) {},
      enabled: enabled,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
        hintText: enabled ? hint : "Not Applicable",
        filled: true,
        fillColor: enabled ? Colors.grey[200] : Colors.grey[400],
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}
