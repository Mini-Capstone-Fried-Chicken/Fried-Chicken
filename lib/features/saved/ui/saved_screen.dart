import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:campus_app/features/settings/app_settings.dart';
import 'package:campus_app/features/saved/saved_directions_controller.dart';
import 'package:campus_app/features/saved/saved_place.dart';
import 'package:campus_app/features/saved/saved_places_controller.dart';
import 'package:campus_app/shared/widgets/app_widgets.dart';

class SavedScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SavedScreen({super.key, required this.isLoggedIn});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenStyles {
  final Color cardBackground;
  final Color cardBorder;
  final Color headingColor;
  final Color textColor;
  final Color subTextColor;
  final Color inputFill;
  final Color buttonBg;
  final Color buttonText;

  const _SavedScreenStyles({
    required this.cardBackground,
    required this.cardBorder,
    required this.headingColor,
    required this.textColor,
    required this.subTextColor,
    required this.inputFill,
    required this.buttonBg,
    required this.buttonText,
  });
}

class _SavedBodyData {
  final List<SavedPlace> savedPlaces;
  final List<SavedPlace> visiblePlaces;
  final List<String> filters;
  final String effectiveFilter;
  final String radiusLabel;
  final _SavedScreenStyles styles;

  const _SavedBodyData({
    required this.savedPlaces,
    required this.visiblePlaces,
    required this.filters,
    required this.effectiveFilter,
    required this.radiusLabel,
    required this.styles,
  });
}

class _SavedScreenState extends State<SavedScreen> {
  int _radiusOptionIndex = 19;
  String _selectedFilter = 'all';
  Position? _currentPosition;

  static const List<int?> _radiusOptions = <int?>[
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    90,
    100,
    null,
  ];

  @override
  void initState() {
    super.initState();
    SavedPlacesController.ensureInitialized();
    _updateCurrentLocation();
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentPosition = position;
      });
    } catch (_) {
      // Keep distance unavailable if location cannot be obtained.
    }
  }

  double? _distanceKmFor(SavedPlace place) {
    final current = _currentPosition;
    if (current == null) return null;
    final meters = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      place.latitude,
      place.longitude,
    );
    return meters / 1000;
  }

  List<SavedPlace> _filteredPlaces(
    List<SavedPlace> places, {
    required String selectedFilter,
    required int? selectedRadiusKm,
  }) {
    final filtered = places.where((place) {
      if (selectedFilter != 'all' && place.category != selectedFilter) {
        return false;
      }
      final distance = _distanceKmFor(place);
      if (distance == null) return true;
      if (selectedRadiusKm == null) return true;
      return distance <= selectedRadiusKm;
    }).toList();

    filtered.sort((a, b) {
      final aDistance = _distanceKmFor(a);
      final bDistance = _distanceKmFor(b);
      if (aDistance == null && bDistance == null) return 0;
      if (aDistance == null) return 1;
      if (bDistance == null) return -1;
      return aDistance.compareTo(bDistance);
    });

    return filtered;
  }

  String _formatCategoryLabel(String category) {
    final normalized = category
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .toLowerCase();
    if (normalized.isEmpty) return category;

    final words = normalized
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .toList();
    if (words.isEmpty) return category;
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettingsState>(
      valueListenable: AppSettingsController.notifier,
      builder: _buildWithSettings,
    );
  }

  Widget _buildWithSettings(
    BuildContext context,
    AppSettingsState settings,
    Widget? _,
  ) {
    final isHighContrast = settings.highContrastModeEnabled;
    final pageBackground = isHighContrast ? Colors.black : Colors.white;
    final cardBackground = isHighContrast
        ? const Color(0xFF121212)
        : Colors.white;
    final cardBorder = isHighContrast
        ? AppUiColors.highContrastPrimary.withValues(alpha: 0.85)
        : const Color(0xFFDADADA);
    final headingColor = isHighContrast
        ? AppUiColors.highContrastPrimary
        : const Color(0xFF76263D);
    final textColor = isHighContrast ? Colors.white : Colors.black87;
    final subTextColor = isHighContrast ? Colors.white70 : Colors.black54;
    final inputFill = isHighContrast
        ? const Color(0xFF1D1D1D)
        : const Color(0xFFF6F6F6);
    final buttonBg = isHighContrast
        ? AppUiColors.highContrastPrimary
        : const Color(0xFF76263D);
    final buttonText = isHighContrast ? Colors.black : Colors.white;

    return ValueListenableBuilder<List<SavedPlace>>(
      valueListenable: SavedPlacesController.notifier,
      builder: (context, savedPlaces, __) {
        final dynamicCategories = _collectDynamicCategories(savedPlaces);
        final filters = <String>{'all', ...dynamicCategories}.toList();
        final effectiveFilter = _resolveEffectiveFilter(filters);
        final selectedRadiusKm = _radiusOptions[_radiusOptionIndex];
        final visiblePlaces = _filteredPlaces(
          savedPlaces,
          selectedFilter: effectiveFilter,
          selectedRadiusKm: selectedRadiusKm,
        );
        final radiusLabel = _radiusLabel(selectedRadiusKm);
        final styles = _SavedScreenStyles(
          cardBackground: cardBackground,
          cardBorder: cardBorder,
          headingColor: headingColor,
          textColor: textColor,
          subTextColor: subTextColor,
          inputFill: inputFill,
          buttonBg: buttonBg,
          buttonText: buttonText,
        );
        final bodyData = _SavedBodyData(
          savedPlaces: savedPlaces,
          visiblePlaces: visiblePlaces,
          filters: filters,
          effectiveFilter: effectiveFilter,
          radiusLabel: radiusLabel,
          styles: styles,
        );

        return Scaffold(
          backgroundColor: pageBackground,
          body: SafeArea(
            child: _buildSavedBody(context: context, data: bodyData),
          ),
        );
      },
    );
  }

  List<String> _collectDynamicCategories(List<SavedPlace> savedPlaces) {
    final categories = <String>{
      for (final place in savedPlaces)
        if (place.category.trim().isNotEmpty &&
            place.category.trim().toLowerCase() != 'all')
          place.category,
    }.toList()..sort();

    return categories;
  }

  String _resolveEffectiveFilter(List<String> filters) {
    return filters.contains(_selectedFilter) ? _selectedFilter : 'all';
  }

  String _radiusLabel(int? selectedRadiusKm) {
    return selectedRadiusKm == null ? 'All' : '$selectedRadiusKm km';
  }

  Widget _buildSavedBody({
    required BuildContext context,
    required _SavedBodyData data,
  }) {
    final styles = data.styles;

    return Column(
      children: [
        const SizedBox(height: 8),
        const SizedBox(height: 72, child: Center(child: AppLogo())),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRadiusSection(
                  context: context,
                  radiusLabel: data.radiusLabel,
                  headingColor: styles.headingColor,
                  subTextColor: styles.subTextColor,
                ),
                const SizedBox(height: 10),
                _buildFilterDropdown(
                  filters: data.filters,
                  effectiveFilter: data.effectiveFilter,
                  inputFill: styles.inputFill,
                  cardBorder: styles.cardBorder,
                  textColor: styles.textColor,
                  headingColor: styles.headingColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Saved places',
                  style: TextStyle(
                    color: styles.headingColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                if (data.visiblePlaces.isEmpty)
                  _buildEmptyStateMessage(
                    savedPlaces: data.savedPlaces,
                    subTextColor: styles.subTextColor,
                  ),
                ...data.visiblePlaces.map(
                  (place) => _buildPlaceCard(place: place, styles: styles),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadiusSection({
    required BuildContext context,
    required String radiusLabel,
    required Color headingColor,
    required Color subTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search by radius: $radiusLabel',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: headingColor,
            thumbColor: headingColor,
            inactiveTrackColor: headingColor.withValues(alpha: 0.25),
            overlayColor: headingColor.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: _radiusOptionIndex.toDouble(),
            min: 0,
            max: (_radiusOptions.length - 1).toDouble(),
            divisions: _radiusOptions.length - 1,
            label: radiusLabel,
            onChanged: (value) {
              setState(() {
                _radiusOptionIndex = value.round();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Text('1 km', style: TextStyle(color: subTextColor, fontSize: 12)),
              const Spacer(),
              Text('All', style: TextStyle(color: subTextColor, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required List<String> filters,
    required String effectiveFilter,
    required Color inputFill,
    required Color cardBorder,
    required Color textColor,
    required Color headingColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveFilter,
          isExpanded: true,
          dropdownColor: inputFill,
          style: TextStyle(color: textColor, fontSize: 15),
          iconEnabledColor: headingColor,
          items: filters
              .map(
                (filter) => DropdownMenuItem<String>(
                  value: filter,
                  child: Text(
                    filter == 'all' ? 'All' : _formatCategoryLabel(filter),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedFilter = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildEmptyStateMessage({
    required List<SavedPlace> savedPlaces,
    required Color subTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Text(
        savedPlaces.isEmpty
            ? 'No saved places yet. Save a place from the map.'
            : 'No places match the selected radius/filter.',
        style: TextStyle(color: subTextColor, fontSize: 14),
      ),
    );
  }

  Widget _buildPlaceCard({
    required SavedPlace place,
    required _SavedScreenStyles styles,
  }) {
    final distanceKm = _distanceKmFor(place);
    final distanceLabel = distanceKm == null
        ? 'Distance unavailable'
        : '${distanceKm.toStringAsFixed(2)} km away';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: styles.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: styles.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  place.name,
                  style: TextStyle(
                    color: styles.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove from saved',
                icon: Icon(
                  Icons.bookmark_remove_outlined,
                  size: 20,
                  color: styles.headingColor,
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {
                  SavedPlacesController.removePlace(place.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Category: ${_formatCategoryLabel(place.category)}',
            style: TextStyle(color: styles.subTextColor, fontSize: 13.5),
          ),
          const SizedBox(height: 2),
          Text(
            'Distance: $distanceLabel',
            style: TextStyle(color: styles.subTextColor, fontSize: 13.5),
          ),
          const SizedBox(height: 2),
          Text(
            place.openingHoursToday,
            style: TextStyle(color: styles.subTextColor, fontSize: 13.5),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                SavedDirectionsController.requestDirections(place);
              },
              icon: const Icon(Icons.directions),
              label: const Text('Get directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: styles.buttonBg,
                foregroundColor: styles.buttonText,
                minimumSize: const Size(0, 42),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
