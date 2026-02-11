class BuildingInfo {
  final String code;
  final String name;
  final String campus;

  final String address;
  final String note;

  final List<String> floors;
  final List<String> facilities;
  final bool accessibility;
  final String department;
  final String link;

  const BuildingInfo({
    required this.code,
    required this.name,
    required this.campus,
    required this.address,
    this.note = '',
    required this.floors,
    required this.facilities,
    required this.accessibility,
    required this.department,
    required this.link,
  });

  String get description {
    final addr = address.trim();
    final dept = department.trim();
    final n = note.trim();

    final deptSentence = departmentSentence(dept);
    final noteSentence = ensurePeriod(n);

    final parts = <String>[
      'Located at $addr.',
      if (deptSentence.isNotEmpty) deptSentence,
      if (noteSentence.isNotEmpty) noteSentence,
    ];

    return parts.join(' ').trim();
  }

  String departmentSentence(String dept) {
    if (dept.isEmpty) return '';

    if (dept == Departments.various) {
      return 'Part of various departments.';
    }

    if (dept == Departments.residences || dept.toLowerCase() == 'residence') {
      return 'Hosts student residences.';
    }

    if (dept.endsWith('.')) {
      return dept;
    }

    return 'Part of $dept department.';
  }

  String ensurePeriod(String text) {
    if (text.isEmpty) return '';
    return text.endsWith('.') ? text : '$text.';
  }
}

class Campuses {
  static const sgw = 'SGW';
  static const loyola = 'Loyola';
}

class Facilities {
  static const washrooms = 'Washrooms';
  static const coffeeShop = 'Coffee Shop';
  static const restaurants = 'Restaurants';
  static const zenDen = 'Zen Den';
  static const metro = 'Metro';
  static const parking = 'Parking';
}

class Addresses {
  static const loyolaMain = '7141 Sherbrooke St. W.';
  static const loyolaOther = '7200 Sherbrooke St. W.';
}

class Departments {
  static const various = 'Various';
  static const research = 'Research';
  static const residences = 'Residences';
  static const philosophy = 'Philosophy';
  static const psychology = 'Psychology';
  static const education = 'Education';
  static const appliedHumanSciences = 'Applied Human Sciences';
  static const communicationStudiesJournalism =
      'Communication Studies and Journalism';
  static const athletics = 'Athletics';
  static const facultyArtsScience = 'Faculty of Arts and Science';
  static const engineeringComputerScience = 'Engineering & Computer Science';
  static const religionsCultures = 'Religions and Cultures';
  static const csuDaycareNursery = 'CSU Daycare & Nursery';
  static const artHistoryEducation = 'Art History and Education';
  static const liberalArtsCollege = 'Liberal Arts College';
}

const String linkBase = 'https://www.concordia.ca/maps/buildings/';

BuildingInfo building({
  required String code,
  required String name,
  required String campus,
  required String address,
  List<String> floors = const ['0'],
  List<String> facilities = const [Facilities.washrooms],
  bool accessibility = true,
  String department = Departments.various,
  String note = '',
  String? link,
}) {
  return BuildingInfo(
    code: code,
    name: name,
    campus: campus,
    address: address,
    note: note,
    floors: floors,
    facilities: facilities,
    accessibility: accessibility,
    department: department,
    link: link ?? '$linkBase${code.toLowerCase()}.html',
  );
}

final Map<String, BuildingInfo> buildingInfoByCode = {
  "LB": building(
    code: "LB",
    name: "LB Building",
    campus: Campuses.sgw,
    address: "1400 De Maisonneuve Blvd. W.",
    floors: const ["1", "2", "3", "4", "5"],
    facilities: const [
      Facilities.washrooms,
      Facilities.coffeeShop,
      Facilities.metro
    ],
  ),
  "MB": building(
    code: "MB",
    name: "John Molson Building",
    campus: Campuses.sgw,
    address: "1450 Guy St.",
    floors: const ["1", "S2"],
    facilities: const [Facilities.washrooms, Facilities.metro, Facilities.zenDen],
  ),
  "H": building(
    code: "H",
    name: "Hall Building",
    campus: Campuses.sgw,
    address: "1455 De Maisonneuve Blvd. W.",
    floors: const ["1", "2", "8", "9"],
    facilities: const [
      Facilities.washrooms,
      Facilities.metro,
      Facilities.restaurants,
      Facilities.coffeeShop,
      Facilities.zenDen,
    ],
    department: Departments.engineeringComputerScience,
  ),
  "EV": building(
    code: "EV",
    name: "Engineering, Computer Science and Visual Arts Integrated Complex",
    campus: Campuses.sgw,
    address: "1515 Ste-Catherine St. W.",
    floors: const ["1", "2", "3"],
    facilities: const [
      Facilities.washrooms,
      Facilities.zenDen,
      Facilities.coffeeShop,
      Facilities.metro,
    ],
  ),
  "GM": building(
    code: "GM",
    name: "Guy-De Maisonneuve Building",
    campus: Campuses.sgw,
    address: "1550 De Maisonneuve Blvd. W.",
    facilities: const [
      Facilities.washrooms,
      Facilities.zenDen,
      Facilities.metro,
      Facilities.coffeeShop,
    ],
  ),
  "FG": building(
    code: "FG",
    name: "Faubourg Building",
    campus: Campuses.sgw,
    address: "1610 Ste-Catherine St. W.",
    floors: const ["1", "2"],
    facilities: const [Facilities.washrooms, Facilities.restaurants],
    department: Departments.education,
  ),
  "B": building(
    code: "B",
    name: "B annex",
    campus: Campuses.sgw,
    address: "2160 Bishop St.",
    floors: const ["1", "2"],
    accessibility: false,
    department: Departments.engineeringComputerScience,
  ),
  "CI": building(
    code: "CI",
    name: "CI annex",
    campus: Campuses.sgw,
    address: "2149 Mackay St.",
    floors: const ["1"],
    accessibility: false,
  ),
  "CL": building(
    code: "CL",
    name: "CL annex",
    campus: Campuses.sgw,
    address: "1665 Ste-Catherine St. W.",
  ),
  "D": building(
    code: "D",
    name: "D annex",
    campus: Campuses.sgw,
    address: "2140 Bishop St.",
    floors: const ["1"],
    accessibility: false,
  ),
  "EN": building(
    code: "EN",
    name: "EN annex",
    campus: Campuses.sgw,
    address: "2070 Mackay St.",
    floors: const ["1"],
    accessibility: false,
  ),
  "ER": building(
    code: "ER",
    name: "ER building",
    campus: Campuses.sgw,
    address: "2155 Guy St.",
    floors: const ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"],
  ),
  "FA": building(
    code: "FA",
    name: "FA annex",
    campus: Campuses.sgw,
    address: "2060 Mackay St.",
    floors: const ["1", "2", "3"],
    accessibility: false,
    department: Departments.religionsCultures,
  ),
  "FB": building(
    code: "FB",
    name: "FB - Faubourg Tower",
    campus: Campuses.sgw,
    address: "1250 Guy St. (main entrance), 1600 Ste-Catherine St. W.",
    floors: const ["1", "2", "3"],
    facilities: const [Facilities.washrooms, Facilities.parking],
  ),
  "GN": building(
    code: "GN",
    name: "Grey Nuns Building",
    campus: Campuses.sgw,
    address:
        "1190 Guy St. (main entrance) / 1175 St-Mathieu St. / 1185 St-Mathieu St.",
    department: Departments.philosophy,
  ),
  "GS": building(
    code: "GS",
    name: "GS",
    campus: Campuses.sgw,
    address: "1538 Sherbrooke St. W.",
  ),
  "K": building(
    code: "K",
    name: "K Annex",
    campus: Campuses.sgw,
    address: "2150 Bishop St.",
    accessibility: false,
  ),
  "LD": building(
    code: "LD",
    name: "LD",
    campus: Campuses.sgw,
    address: "1424 Bishop St.",
    facilities: const [Facilities.washrooms, Facilities.parking],
    department: Departments.csuDaycareNursery,
  ),
  "LS": building(
    code: "LS",
    name: "Learning Square",
    campus: Campuses.sgw,
    address: "1535 De Maisonneuve Blvd. W.",
    floors: const ["1", "2"],
  ),
  "M": building(
    code: "M",
    name: "M Annex",
    campus: Campuses.sgw,
    address: "2135 Mackay St.",
    accessibility: false,
  ),
  "MI": building(
    code: "MI",
    name: "MI Annex",
    campus: Campuses.sgw,
    address: "2130 Bishop St.",
    floors: const ["1", "2"],
    accessibility: false,
  ),
  "MU": building(
    code: "MU",
    name: "MU",
    campus: Campuses.sgw,
    address: "2170 Bishop St.",
    floors: const ["1", "2"],
    accessibility: false,
  ),
  "P": building(
    code: "P",
    name: "P",
    campus: Campuses.sgw,
    address: "2020 Mackay St.",
    accessibility: false,
  ),
  "PR": building(
    code: "PR",
    name: "PR Annex",
    campus: Campuses.sgw,
    address: "2100 Mackay St.",
    accessibility: false,
  ),
  "Q": building(
    code: "Q",
    name: "Q Annex",
    campus: Campuses.sgw,
    address: "2010 Mackay St.",
    accessibility: false,
  ),
  "R": building(
    code: "R",
    name: "R Annex",
    campus: Campuses.sgw,
    address: "2050 Mackay St.",
    accessibility: false,
  ),
  "RR": building(
    code: "RR",
    name: "RR Annex",
    campus: Campuses.sgw,
    address: "2040 Mackay St.",
    accessibility: false,
    department: Departments.liberalArtsCollege,
  ),
  "S": building(
    code: "S",
    name: "S Annex",
    campus: Campuses.sgw,
    address: "2145 Mackay St.",
    accessibility: false,
    department: Departments.philosophy,
  ),
  "SB": building(
    code: "SB",
    name: "Samuel Bronfman Building",
    campus: Campuses.sgw,
    address: "1590 Docteur Penfield",
  ),
  "T": building(
    code: "T",
    name: "T Annex",
    campus: Campuses.sgw,
    address: "2030 Mackay St.",
    accessibility: false,
  ),
  "TD": building(
    code: "TD",
    name: "Toronto-Dominion Building",
    campus: Campuses.sgw,
    address: "1410 Guy St.",
    accessibility: false,
  ),
  "V": building(
    code: "V",
    name: "V Annex",
    campus: Campuses.sgw,
    address: "2110 Mackay St.",
    accessibility: false,
  ),
  "VA": building(
    code: "VA",
    name: "Visual Arts Building",
    campus: Campuses.sgw,
    address: "1395 René-Lévesque Blvd. W.",
    department: Departments.artHistoryEducation,
  ),
  "X": building(
    code: "X",
    name: "X Annex",
    campus: Campuses.sgw,
    address: "2080 Mackay St.",
    accessibility: false,
  ),
  "Z": building(
    code: "Z",
    name: "Z Annex",
    campus: Campuses.sgw,
    address: "2090 Mackay St.",
    accessibility: false,
  ),

  // Loyola
  "AD": building(
    code: "AD",
    name: "Administration Building",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    department: Departments.facultyArtsScience,
  ),
  "BB": building(
    code: "BB",
    name: "BB Annex",
    campus: Campuses.loyola,
    address: "3502 Belmore Ave.",
    accessibility: false,
  ),
  "BH": building(
    code: "BH",
    name: "BH Annex",
    campus: Campuses.loyola,
    address: "3500 Belmore Ave.",
    accessibility: false,
  ),
  "CC": building(
    code: "CC",
    name: "Central Building",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    facilities: const [Facilities.washrooms, Facilities.zenDen],
  ),
  "CJ": building(
    code: "CJ",
    name: "Communication Studies and Journalism Building",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    department: Departments.communicationStudiesJournalism,
  ),
  "DO": building(
    code: "DO",
    name: "Stinger Dome",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    accessibility: false,
    department: Departments.athletics,
  ),
  "FC": building(
    code: "FC",
    name: "F.C. Smith Building",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
  ),
  "GE": building(
    code: "GE",
    name: "Centre for Structural and Functional Genomics",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    department: Departments.research,
  ),
  "HA": building(
    code: "HA",
    name: "Hingston Hall, wing HA",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    facilities: const [Facilities.washrooms, Facilities.parking],
    department: Departments.residences,
  ),
  "HB": building(
    code: "HB",
    name: "Hingston Hall, wing HB",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    facilities: const [Facilities.washrooms, Facilities.parking],
    accessibility: false,
    department: Departments.residences,
  ),
  "HC": building(
    code: "HC",
    name: "Hingston Hall, wing HC",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    facilities: const [Facilities.washrooms, Facilities.parking],
    department: Departments.residences,
  ),
  "HU": building(
    code: "HU",
    name: "Applied Science Hub",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
  ),
  "JR": building(
    code: "JR",
    name: "Jesuit Residence",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    facilities: const [Facilities.washrooms, Facilities.parking],
    department: Departments.residences,
  ),
  "PC": building(
    code: "PC",
    name: "PERFORM Centre",
    campus: Campuses.loyola,
    address: Addresses.loyolaOther,
    facilities: const [Facilities.washrooms, Facilities.parking],
  ),
  "PS": building(
    code: "PS",
    name: "Physical Services Building",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    accessibility: false,
  ),
  "PT": building(
    code: "PT",
    name: "Oscar Peterson Concert Hall",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
  ),
  "PY": building(
    code: "PY",
    name: "Psychology Building",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    department: Departments.psychology,
  ),
  "QA": building(
    code: "QA",
    name: "Quadrangle",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
  ),
  "RA": building(
    code: "RA",
    name: "Recreation and Athletics Complex",
    campus: Campuses.loyola,
    address: Addresses.loyolaOther,
    facilities: const [Facilities.washrooms, Facilities.parking],
  ),
  "RF": building(
    code: "RF",
    name: "Loyola Jesuit Hall and Conference Centre",
    campus: Campuses.loyola,
    address: Addresses.loyolaOther,
  ),
  "SC": building(
    code: "SC",
    name: "Student Centre",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    facilities: const [
      Facilities.washrooms,
      Facilities.coffeeShop,
      Facilities.restaurants
    ],
  ),
  "SH": building(
    code: "SH",
    name: "Future Buildings Laboratory",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    department: Departments.research,
  ),
  "SI": building(
    code: "SI",
    name: "St. Ignatius of Loyola Church",
    campus: Campuses.loyola,
    address: "4455 Broadway St.",
    accessibility: false,
  ),
  "SP": building(
    code: "SP",
    name: "Richard J. Renaud Science Complex",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    facilities: const [Facilities.washrooms, Facilities.coffeeShop],
  ),
  "TA": building(
    code: "TA",
    name: "Terrebonne Building",
    campus: Campuses.loyola,
    address: "7079 Terrebonne St.",
    facilities: const [Facilities.washrooms, Facilities.parking],
    accessibility: false,
  ),
  "VE": building(
    code: "VE",
    name: "Vanier Extension",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    department: Departments.appliedHumanSciences,
  ),
  "VL": building(
    code: "VL",
    name: "Vanier Library",
    campus: Campuses.loyola,
    address: Addresses.loyolaMain,
    note: "Library on Loyola campus",
  ),
};
