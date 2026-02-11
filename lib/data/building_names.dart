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

/// List of all Concordia buildings with their codes and full names
const List<BuildingName> concordiaBuildingNames = [
  // SGW Campus
  BuildingName(
    code: "LB",
    name: "LB Building",
    searchTerms: ["lb"],
  ),
  BuildingName(
    code: "MB",
    name: "MB Building",
    searchTerms: ["mb"],
  ),
  BuildingName(
    code: "HALL",
    name: "Hall Building",
    searchTerms: ["hall", "h"],
  ),
  BuildingName(
    code: "EV",
    name: "EV Building",
    searchTerms: ["ev", "engineering", "visual arts"],
  ),
  BuildingName(
    code: "GM",
    name: "GM Building",
    searchTerms: ["gm", "guy metro"],
  ),
  BuildingName(
    code: "FG",
    name: "Faubourg Building",
    searchTerms: ["faubourg", "fg"],
  ),
  BuildingName(
    code: "B",
    name: "B annex",
    searchTerms: ["b", "annex"],
  ),
  BuildingName(
    code: "CI",
    name: "CI annex",
    searchTerms: ["ci", "annex"],
  ),
  BuildingName(
    code: "CL",
    name: "CL annex",
    searchTerms: ["cl", "annex"],
  ),
  BuildingName(
    code: "D",
    name: "D annex",
    searchTerms: ["d", "annex"],
  ),
  BuildingName(
    code: "EN",
    name: "EN annex",
    searchTerms: ["en", "annex"],
  ),
  BuildingName(
    code: "ER",
    name: "ER building",
    searchTerms: ["er"],
  ),
  BuildingName(
    code: "FA",
    name: "FA annex",
    searchTerms: ["fa", "annex"],
  ),
  BuildingName(
    code: "FB",
    name: "FB - Faubourg Tower",
    searchTerms: ["fb", "faubourg", "tower"],
  ),
  BuildingName(
    code: "GN",
    name: "Grey Nuns Building",
    searchTerms: ["grey nuns", "gn"],
  ),
  BuildingName(
    code: "GS",
    name: "GS",
    searchTerms: ["gs"],
  ),
  BuildingName(
    code: "K",
    name: "K",
    searchTerms: ["k"],
  ),
  BuildingName(
    code: "LD",
    name: "LD",
    searchTerms: ["ld"],
  ),
  BuildingName(
    code: "LS",
    name: "Learning Square",
    searchTerms: ["learning square", "ls"],
  ),
  BuildingName(
    code: "M",
    name: "M",
    searchTerms: ["m"],
  ),
  BuildingName(
    code: "MI",
    name: "MI",
    searchTerms: ["mi"],
  ),
  BuildingName(
    code: "MU",
    name: "MU",
    searchTerms: ["mu"],
  ),
  BuildingName(
    code: "P",
    name: "P",
    searchTerms: ["p"],
  ),
  BuildingName(
    code: "PR",
    name: "PR",
    searchTerms: ["pr"],
  ),
  BuildingName(
    code: "Q",
    name: "Q",
    searchTerms: ["q"],
  ),
  BuildingName(
    code: "R",
    name: "R",
    searchTerms: ["r"],
  ),
  BuildingName(
    code: "RR",
    name: "RR",
    searchTerms: ["rr"],
  ),
  BuildingName(
    code: "S",
    name: "S",
    searchTerms: ["s"],
  ),
  BuildingName(
    code: "SB",
    name: "SB",
    searchTerms: ["sb"],
  ),
  BuildingName(
    code: "T",
    name: "T",
    searchTerms: ["t"],
  ),
  BuildingName(
    code: "TD",
    name: "TD",
    searchTerms: ["td"],
  ),
  BuildingName(
    code: "V",
    name: "V",
    searchTerms: ["v"],
  ),
  BuildingName(
    code: "VA",
    name: "VA",
    searchTerms: ["va", "visual arts"],
  ),

  // Loyola Campus
  BuildingName(
    code: "AD",
    name: "Administration Building",
    searchTerms: ["administration", "ad", "admin"],
  ),
  BuildingName(
    code: "BB",
    name: "BB annex",
    searchTerms: ["bb", "annex"],
  ),
  BuildingName(
    code: "BH",
    name: "BH annex",
    searchTerms: ["bh", "annex"],
  ),
  BuildingName(
    code: "CC",
    name: "Central Building",
    searchTerms: ["central", "cc"],
  ),
  BuildingName(
    code: "CJ",
    name: "Communication Studies and Journalism building",
    searchTerms: ["communication", "journalism", "cj", "comm"],
  ),
  BuildingName(
    code: "DO",
    name: "Stinger Dome",
    searchTerms: ["stinger", "dome", "do"],
  ),
  BuildingName(
    code: "FC",
    name: "F.C. Smith building",
    searchTerms: ["fc", "smith"],
  ),
  BuildingName(
    code: "GE",
    name: "Center for structural and functional genomics",
    searchTerms: ["genomics", "ge", "center"],
  ),
  BuildingName(
    code: "HA",
    name: "Hingston Hall, wing HA",
    searchTerms: ["hingston", "ha", "hall"],
  ),
  BuildingName(
    code: "HB",
    name: "Hingston Hall, wing HB",
    searchTerms: ["hingston", "hb", "hall"],
  ),
  BuildingName(
    code: "HC",
    name: "Hingston Hall, wing HC",
    searchTerms: ["hingston", "hc", "hall"],
  ),
  BuildingName(
    code: "HU",
    name: "Applied Science Hub",
    searchTerms: ["applied science", "hub", "hu"],
  ),
  BuildingName(
    code: "JR",
    name: "Jesuit Residence",
    searchTerms: ["jesuit", "residence", "jr"],
  ),
  BuildingName(
    code: "PC",
    name: "PERFORM center",
    searchTerms: ["perform", "pc", "center"],
  ),
  BuildingName(
    code: "PS",
    name: "Physical Services building",
    searchTerms: ["physical services", "ps"],
  ),
  BuildingName(
    code: "PT",
    name: "Oscar Peterson Concert Hall",
    searchTerms: ["oscar peterson", "concert", "hall", "pt"],
  ),
  BuildingName(
    code: "PY",
    name: "Psychology building",
    searchTerms: ["psychology", "py", "psych"],
  ),
  BuildingName(
    code: "QA",
    name: "Quadrangle",
    searchTerms: ["quadrangle", "qa", "quad"],
  ),
  BuildingName(
    code: "RA",
    name: "Recreation and Athletic Complex",
    searchTerms: ["recreation", "athletic", "ra", "rec"],
  ),
  BuildingName(
    code: "RF",
    name: "Loyola Jesuit Hall and Conference Centre",
    searchTerms: ["loyola", "jesuit", "conference", "rf"],
  ),
  BuildingName(
    code: "SC",
    name: "Student Centre",
    searchTerms: ["student", "centre", "center", "sc"],
  ),
  BuildingName(
    code: "SH",
    name: "Future Buildings Laboratory",
    searchTerms: ["future buildings", "laboratory", "sh", "lab"],
  ),
  BuildingName(
    code: "SI",
    name: "St. Ignatus of Loyola Church",
    searchTerms: ["st ignatus", "loyola", "church", "si", "saint"],
  ),
  BuildingName(
    code: "SP",
    name: "Richard J. Renaud Science Complex",
    searchTerms: ["richard renaud", "science", "sp", "complex"],
  ),
  BuildingName(
    code: "TA",
    name: "Terrebonne Building",
    searchTerms: ["terrebonne", "ta"],
  ),
  BuildingName(
    code: "VE",
    name: "Vanier Extension",
    searchTerms: ["vanier", "extension", "ve"],
  ),
  BuildingName(
    code: "VL",
    name: "Vanier Library",
    searchTerms: ["vanier", "library", "vl"],
  ),
];
