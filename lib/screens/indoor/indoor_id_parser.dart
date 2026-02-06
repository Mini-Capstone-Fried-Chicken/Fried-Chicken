class IndoorIdInfo {
  final String buildingCode;
  final String? floor;

  const IndoorIdInfo(this.buildingCode, this.floor);
}

IndoorIdInfo parseIndoorId(String id) {
  final clean = id.trim();
  if (clean.isEmpty) {
    return const IndoorIdInfo("UNKNOWN", null);
  }

  // Special shorthand
  if (clean.toLowerCase() == "h8") {
    return const IndoorIdInfo("HALL", "8");
  }

  // Hyphenated
  if (clean.contains("-")) {
    final parts = clean.split("-").where((p) => p.isNotEmpty).toList();
    final building = parts.first.toUpperCase();
    final floor =
        parts.length > 1 ? parts.sublist(1).join("-").toUpperCase() : null;

    return IndoorIdInfo(building, floor);
  }

  // Compact
  final match = RegExp(r"^([A-Za-z]+)(\d+)$").firstMatch(clean);
  if (match != null) {
    return IndoorIdInfo(
      match.group(1)!.toUpperCase(),
      match.group(2),
    );
  }

  // Fallback
  return IndoorIdInfo(clean.toUpperCase(), null);
}
