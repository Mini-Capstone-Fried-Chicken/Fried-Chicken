import 'package:flutter/foundation.dart';

import 'saved_place.dart';

class SavedDirectionsController {
  SavedDirectionsController._();

  static final ValueNotifier<SavedPlace?> notifier = ValueNotifier<SavedPlace?>(null);

  static void requestDirections(SavedPlace place) {
    notifier.value = place;
  }

  static void clear() {
    notifier.value = null;
  }
}
