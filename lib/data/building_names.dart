/// Contains mappings between building codes and their full names for search functionality
class BuildingName {
  final String code;
  final String name;
  final List<String> searchTerms; // Additional terms for easier searching

  const BuildingName({
    required this.code,
    required this.name,
    this.searchTerms = const [],
  });
}

BuildingName _building({
  required String code,
  String? name,
  List<String> searchTerms = const [],
}) {
  return BuildingName(
    code: code,
    name: name ?? code,
    searchTerms: searchTerms,
  );
}

BuildingName _annex(String code, List<String> searchTerms) {
  return _building(
    code: code,
    name: "$code annex",
    searchTerms: searchTerms,
  );
}

/// List of all Concordia buildings with their codes and full names
final List<BuildingName> concordiaBuildingNames = [
  // SGW Campus
  _building(code: "LB", name: "LB Building", searchTerms: ["lb"]),
  _building(code: "MB", name: "MB Building", searchTerms: ["mb"]),
  _building(code: "HALL", name: "Hall Building", searchTerms: ["hall", "h"]),
  _building(
    code: "EV",
    name: "EV Building",
    searchTerms: ["ev", "engineering", "visual arts"],
  ),
  _building(code: "GM", name: "GM Building", searchTerms: ["gm", "guy metro"]),
  _building(code: "FG", name: "Faubourg Building", searchTerms: ["faubourg", "fg"]),
  _annex("B", ["b", "annex"]),
  _annex("CI", ["ci", "annex"]),
  _annex("CL", ["cl", "annex"]),
  _annex("D", ["d", "annex"]),
  _annex("EN", ["en", "annex"]),
  _building(code: "ER", name: "ER building", searchTerms: ["er"]),
  _annex("FA", ["fa", "annex"]),
  _building(code: "FB", name: "FB - Faubourg Tower", searchTerms: ["fb", "faubourg", "tower"]),
  _building(code: "GN", name: "Grey Nuns Building", searchTerms: ["grey nuns", "gn"]),
  _building(code: "GS", searchTerms: ["gs"]),
  _building(code: "K", searchTerms: ["k"]),
  _building(code: "LD", searchTerms: ["ld"]),
  _building(code: "LS", name: "Learning Square", searchTerms: ["learning square", "ls"]),
  _building(code: "M", searchTerms: ["m"]),
  _building(code: "MI", searchTerms: ["mi"]),
  _building(code: "MU", searchTerms: ["mu"]),
  _building(code: "P", searchTerms: ["p"]),
  _building(code: "PR", searchTerms: ["pr"]),
  _building(code: "Q", searchTerms: ["q"]),
  _building(code: "R", searchTerms: ["r"]),
  _building(code: "RR", searchTerms: ["rr"]),
  _building(code: "S", searchTerms: ["s"]),
  _building(code: "SB", searchTerms: ["sb"]),
  _building(code: "T", searchTerms: ["t"]),
  _building(code: "TD", searchTerms: ["td"]),
  _building(code: "V", searchTerms: ["v"]),
  _building(code: "VA", searchTerms: ["va", "visual arts"]),

  // Loyola Campus
  _building(
    code: "AD",
    name: "Administration Building",
    searchTerms: ["administration", "ad", "admin"],
  ),
  _annex("BB", ["bb", "annex"]),
  _annex("BH", ["bh", "annex"]),
  _building(code: "CC", name: "Central Building", searchTerms: ["central", "cc"]),
  _building(
    code: "CJ",
    name: "Communication Studies and Journalism building",
    searchTerms: ["communication", "journalism", "cj", "comm"],
  ),
  _building(code: "DO", name: "Stinger Dome", searchTerms: ["stinger", "dome", "do"]),
  _building(code: "FC", name: "F.C. Smith building", searchTerms: ["fc", "smith"]),
  _building(
    code: "GE",
    name: "Center for structural and functional genomics",
    searchTerms: ["genomics", "ge", "center"],
  ),
  _building(code: "HA", name: "Hingston Hall, wing HA", searchTerms: ["hingston", "ha", "hall"]),
  _building(code: "HB", name: "Hingston Hall, wing HB", searchTerms: ["hingston", "hb", "hall"]),
  _building(code: "HC", name: "Hingston Hall, wing HC", searchTerms: ["hingston", "hc", "hall"]),
  _building(code: "HU", name: "Applied Science Hub", searchTerms: ["applied science", "hub", "hu"]),
  _building(code: "JR", name: "Jesuit Residence", searchTerms: ["jesuit", "residence", "jr"]),
  _building(code: "PC", name: "PERFORM center", searchTerms: ["perform", "pc", "center"]),
  _building(
    code: "PS",
    name: "Physical Services building",
    searchTerms: ["physical services", "ps"],
  ),
  _building(
    code: "PT",
    name: "Oscar Peterson Concert Hall",
    searchTerms: ["oscar peterson", "concert", "hall", "pt"],
  ),
  _building(code: "PY", name: "Psychology building", searchTerms: ["psychology", "py", "psych"]),
  _building(code: "QA", name: "Quadrangle", searchTerms: ["quadrangle", "qa", "quad"]),
  _building(
    code: "RA",
    name: "Recreation and Athletic Complex",
    searchTerms: ["recreation", "athletic", "ra", "rec"],
  ),
  _building(
    code: "RF",
    name: "Loyola Jesuit Hall and Conference Centre",
    searchTerms: ["loyola", "jesuit", "conference", "rf"],
  ),
  _building(
    code: "SC",
    name: "Student Centre",
    searchTerms: ["student", "centre", "center", "sc"],
  ),
  _building(
    code: "SH",
    name: "Future Buildings Laboratory",
    searchTerms: ["future buildings", "laboratory", "sh", "lab"],
  ),
  _building(
    code: "SI",
    name: "St. Ignatus of Loyola Church",
    searchTerms: ["st ignatus", "loyola", "church", "si", "saint"],
  ),
  _building(
    code: "SP",
    name: "Richard J. Renaud Science Complex",
    searchTerms: ["richard renaud", "science", "sp", "complex"],
  ),
  _building(code: "TA", name: "Terrebonne Building", searchTerms: ["terrebonne", "ta"]),
  _building(code: "VE", name: "Vanier Extension", searchTerms: ["vanier", "extension", "ve"]),
  _building(code: "VL", name: "Vanier Library", searchTerms: ["vanier", "library", "vl"]),
];
