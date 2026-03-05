import 'package:flutter/material.dart';
import '../../services/indoor_maps/indoor_map_repository.dart';

const Color validGreen = Color(0xFF4CAF50);
const Color invalidRed = Color(0xFFE53935);

class RoomFieldsSection extends StatefulWidget {
  final String? originBuildingCode;
  final String? destinationBuildingCode;
  final TextEditingController originRoomController;
  final TextEditingController destinationRoomController;
  final bool originEnabled;
  final bool destinationEnabled;

  final bool initialOriginValid;
  final bool initialDestinationValid;
  final IndoorMapRepository? indoorRepository;

  final Function(String buildingCode, String roomCode)? onOriginValid;
  final Function(String buildingCode, String roomCode)? onDestinationValid;
  final Function(String buildingCode, String roomCode)?
  onDestinationRoomSubmitted;
  final Function(String buildingCode, String roomCode)? onOriginRoomSubmitted;

  const RoomFieldsSection({
    super.key,
    required this.originBuildingCode,
    required this.destinationBuildingCode,
    required this.originRoomController,
    required this.destinationRoomController,
    required this.originEnabled,
    required this.destinationEnabled,
    this.initialOriginValid = false,
    this.initialDestinationValid = false,
    this.onOriginValid,
    this.onDestinationValid,
    this.onOriginRoomSubmitted,
    this.onDestinationRoomSubmitted,
    this.indoorRepository,
  });

  @override
  State<RoomFieldsSection> createState() => _RoomFieldsSectionState();
}

class _RoomFieldsSectionState extends State<RoomFieldsSection> {
  late bool _originValid;
  late bool _destinationValid;
  late IndoorMapRepository _indoorRepository;

  @override
  void initState() {
    super.initState();
    _originValid = widget.initialOriginValid;
    _destinationValid = widget.initialDestinationValid;
    _indoorRepository = widget.indoorRepository ?? IndoorMapRepository();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.originRoomController.text.isNotEmpty && widget.originEnabled) {
        _validateOriginRoom(widget.originRoomController.text);
      }
      if (widget.destinationRoomController.text.isNotEmpty &&
          widget.destinationEnabled) {
        _validateDestinationRoom(widget.destinationRoomController.text);
      }
    });
  }

  @override
  void didUpdateWidget(RoomFieldsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.originBuildingCode != widget.originBuildingCode) {
      _originValid = false;
    }

    if (oldWidget.destinationBuildingCode != widget.destinationBuildingCode) {
      _destinationValid = false;
    }

    if (!oldWidget.originEnabled &&
        widget.originEnabled &&
        widget.originRoomController.text.isNotEmpty) {
      _validateOriginRoom(widget.originRoomController.text);
    }

    if (!oldWidget.destinationEnabled &&
        widget.destinationEnabled &&
        widget.destinationRoomController.text.isNotEmpty) {
      _validateDestinationRoom(widget.destinationRoomController.text);
    }
  }

  Future<void> _validateRoom({
    required String? buildingCode,
    required bool enabled,
    required String room,
    required void Function(bool isValid) setValidState,
    void Function(String building, String room)? onValid,
    bool triggerSubmit = false,
  }) async {
    if (!enabled || buildingCode == null || room.isEmpty) {
      setState(() => setValidState(false));
      return;
    }

    try {
      final isValid = await _indoorRepository.roomExists(buildingCode, room);
      if (!mounted) return;
      setState(() => setValidState(isValid));
      if (!isValid) {
        return;
      }
      onValid?.call(buildingCode, room);
      if (triggerSubmit) {
        print(
          '[DEBUG] Calling onDestinationRoomSubmitted: $buildingCode, $room',
        );
        widget.onDestinationRoomSubmitted?.call(buildingCode, room);
      }
    } catch (e) {
      print('[ERROR] Validation error: $e');
      if (mounted) {
        setState(() => setValidState(false));
      }
    }
  }

  Future<void> _validateOriginRoom(String room) {
    return _validateRoom(
      buildingCode: widget.originBuildingCode,
      enabled: widget.originEnabled,
      room: room,
      setValidState: (val) => _originValid = val,
      onValid: widget.onOriginValid,
    );
  }

  Future<void> _validateDestinationRoom(String room) {
    return _validateRoom(
      buildingCode: widget.destinationBuildingCode,
      enabled: widget.destinationEnabled,
      room: room,
      setValidState: (val) => _destinationValid = val,
      onValid: widget.onDestinationValid,
      triggerSubmit: false,
    );
  }

  Color _getBorderColor(bool isValid, bool hasInput) {
    if (!hasInput) return Colors.grey;
    return isValid ? validGreen : invalidRed;
  }

  Future<void> _handleOriginRoomSubmit(String val) async {
    if (val.isEmpty || !widget.originEnabled) return;

    await _validateOriginRoom(val);

    if (!_originValid) {
      widget.originRoomController.clear();
      return;
    }

    if (widget.onOriginRoomSubmitted != null &&
        widget.originBuildingCode != null) {
      widget.onOriginRoomSubmitted!(widget.originBuildingCode!, val);
    }
  }

  Future<void> _handleDestinationRoomSubmit(String val) async {
    if (val.isEmpty || !widget.destinationEnabled) return;

    await _validateDestinationRoom(val);

    if (!_destinationValid) {
      widget.destinationRoomController.clear();
      return;
    }

    if (widget.onDestinationRoomSubmitted != null &&
        widget.destinationBuildingCode != null) {
      widget.onDestinationRoomSubmitted!(widget.destinationBuildingCode!, val);
    }
  }

  Future<void> _handleTextFieldSubmit({
    required String val,
    required TextEditingController controller,
  }) async {
    final isOrigin = controller == widget.originRoomController;

    if (isOrigin) {
      await _handleOriginRoomSubmit(val);
    } else {
      await _handleDestinationRoomSubmit(val);
    }
  }

  InputBorder _buildOutlineInputBorder(bool isValid, bool hasInput) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(
        color: _getBorderColor(isValid, hasInput),
        width: 2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required bool enabled,
    required String label,
    required bool isValid,
    required Future<void> Function(String) onChanged,
  }) {
    final hasInput = controller.text.isNotEmpty;
    final suffixIcon = _buildSuffixIcon(hasInput, isValid);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          onChanged: (val) async => onChanged(val),
          onSubmitted: (val) async =>
              _handleTextFieldSubmit(val: val, controller: controller),
          style: TextStyle(color: enabled ? Colors.black87 : Colors.grey[700]),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
            hintText: enabled ? 'Room #' : 'N/A',
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[300],
            suffixIcon: suffixIcon,
            border: _buildOutlineInputBorder(isValid, hasInput),
            enabledBorder: _buildOutlineInputBorder(isValid, hasInput),
            focusedBorder: _buildOutlineInputBorder(isValid, hasInput),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon(bool hasInput, bool isValid) {
    if (!hasInput) return null;

    return Icon(
      isValid ? Icons.check_circle : Icons.cancel,
      color: isValid ? validGreen : invalidRed,
      size: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            controller: widget.originRoomController,
            enabled: widget.originEnabled,
            label: 'Origin Room',
            isValid: _originValid,
            onChanged: _validateOriginRoom,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTextField(
            controller: widget.destinationRoomController,
            enabled: widget.destinationEnabled,
            label: 'Destination Room',
            isValid: _destinationValid,
            onChanged: _validateDestinationRoom,
          ),
        ),
      ],
    );
  }
}
