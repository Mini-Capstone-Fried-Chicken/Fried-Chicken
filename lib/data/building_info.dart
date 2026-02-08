class BuildingInfo {
  final String code;
  final String name;
  final String campus;
  final String description;
  final List<String> floors;

  const BuildingInfo({
    required this.code,
    required this.name,
    required this.campus,
    required this.description,
    required this.floors,
  });
}

const Map<String, BuildingInfo> buildingInfoByCode = {
  "MB": BuildingInfo(
    code: "MB",
    name: "MB (John Molson Building)",
    campus: "SGW",
    description:
        "Business building. Indoor floor plans available for floors 1 and S2.",
    floors: ["1", "S2"],
  ),
  "HALL": BuildingInfo(
    code: "HALL",
    name: "Hall Building",
    campus: "SGW",
    description:
        "Engineering & Computer Science building. Floor plans available.",
    floors: ["1", "2", "8", "9"],
  ),
  "CC": BuildingInfo(
    code: "CC",
    name: "Central Building",
    campus: "Loyola",
    description: "Loyola campus building. Floor plans available.",
    floors: [],
  ),
  "VE": BuildingInfo(
    code: "VE",
    name: "Vanier Extension",
    campus: "Loyola",
    description: "Loyola campus building. Floor plans available.",
    floors: ["1", "2"],
  ),
  "VL": BuildingInfo(
    code: "VL",
    name: "Vanier Library",
    campus: "Loyola",
    description: "Library building. Floor plans available.",
    floors: ["1", "2"],
  ),
  "LB": BuildingInfo(
    code: "LB",
    name: "Webster Library",
    campus: "SGW",
    description: "Library floors available (LB2–LB5).",
    floors: ["2", "3", "4", "5"],
  ),
};
