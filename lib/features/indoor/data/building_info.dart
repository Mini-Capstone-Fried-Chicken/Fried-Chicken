const String linkBase = 'https://www.concordia.ca/maps/buildings/';

class BuildingCore {
  final String code;
  final String name;
  final String campus;
  final String address;
  final String? link;

  const BuildingCore({
    required this.code,
    required this.name,
    required this.campus,
    required this.address,
    this.link,
  });
}

class BuildingDetails {
  final List<String> floors;
  final List<String> facilities;
  final bool accessibility;
  final String department;

  const BuildingDetails({
    this.floors = const ['0'],
    this.facilities = const [Facilities.washrooms],
    this.accessibility = true,
    this.department = Departments.various,
  });
}

class BuildingInfo {
  final BuildingCore core;
  final BuildingDetails details;

  const BuildingInfo({
    required this.core,
    required this.details,
  });

  String get code => core.code;
  String get name => core.name;
  String get campus => core.campus;
  String get address => core.address;

  List<String> get floors => details.floors;
  List<String> get facilities => details.facilities;
  bool get accessibility => details.accessibility;
  String get department => details.department;

  String get link => core.link ?? '$linkBase${code.toLowerCase()}.html';

  String get description {
    final addr = address.trim();
    final deptSentence = departmentSentence(department.trim());

    if (deptSentence.isEmpty) return 'Located at $addr.';
    return 'Located at $addr. $deptSentence';
  }

  String departmentSentence(String dept) {
    if (dept.isEmpty) return '';

    if (dept == Departments.various) {
      return 'Part of various departments.';
    }

    final lower = dept.toLowerCase();
    if (dept == Departments.residences || lower == 'residence') {
      return 'Hosts student residences.';
    }

    if (dept.endsWith('.')) return dept;

    if (lower.contains('department')) {
      return 'Part of $dept.';
    }

    return 'Part of $dept department.';
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

const List<BuildingCore> buildingCores = [
  // SGW
  BuildingCore(code: 'LB', name: 'LB Building', campus: Campuses.sgw, address: '1400 De Maisonneuve Blvd. W.'),
  BuildingCore(code: 'MB', name: 'John Molson Building', campus: Campuses.sgw, address: '1450 Guy St.'),
  BuildingCore(code: 'H', name: 'Hall Building', campus: Campuses.sgw, address: '1455 De Maisonneuve Blvd. W.'),
  BuildingCore(code: 'EV', name: 'Engineering, Computer Science and Visual Arts Integrated Complex', campus: Campuses.sgw, address: '1515 Ste-Catherine St. W.'),
  BuildingCore(code: 'GM', name: 'Guy-De Maisonneuve Building', campus: Campuses.sgw, address: '1550 De Maisonneuve Blvd. W.'),
  BuildingCore(code: 'FG', name: 'Faubourg Building', campus: Campuses.sgw, address: '1610 Ste-Catherine St. W.'),
  BuildingCore(code: 'B', name: 'B annex', campus: Campuses.sgw, address: '2160 Bishop St.'),
  BuildingCore(code: 'CI', name: 'CI annex', campus: Campuses.sgw, address: '2149 Mackay St.'),
  BuildingCore(code: 'CL', name: 'CL annex', campus: Campuses.sgw, address: '1665 Ste-Catherine St. W.'),
  BuildingCore(code: 'D', name: 'D annex', campus: Campuses.sgw, address: '2140 Bishop St.'),
  BuildingCore(code: 'EN', name: 'EN annex', campus: Campuses.sgw, address: '2070 Mackay St.'),
  BuildingCore(code: 'ER', name: 'ER building', campus: Campuses.sgw, address: '2155 Guy St.'),
  BuildingCore(code: 'FA', name: 'FA annex', campus: Campuses.sgw, address: '2060 Mackay St.'),
  BuildingCore(code: 'FB', name: 'FB - Faubourg Tower', campus: Campuses.sgw, address: '1250 Guy St. (main entrance), 1600 Ste-Catherine St. W.'),
  BuildingCore(code: 'GN', name: 'Grey Nuns Building', campus: Campuses.sgw, address: '1190 Guy St. (main entrance) / 1175 St-Mathieu St. / 1185 St-Mathieu St.'),
  BuildingCore(code: 'GS', name: 'GS', campus: Campuses.sgw, address: '1538 Sherbrooke St. W.'),
  BuildingCore(code: 'K', name: 'K Annex', campus: Campuses.sgw, address: '2150 Bishop St.'),
  BuildingCore(code: 'LD', name: 'LD', campus: Campuses.sgw, address: '1424 Bishop St.'),
  BuildingCore(code: 'LS', name: 'Learning Square', campus: Campuses.sgw, address: '1535 De Maisonneuve Blvd. W.'),
  BuildingCore(code: 'M', name: 'M Annex', campus: Campuses.sgw, address: '2135 Mackay St.'),
  BuildingCore(code: 'MI', name: 'MI Annex', campus: Campuses.sgw, address: '2130 Bishop St.'),
  BuildingCore(code: 'MU', name: 'MU', campus: Campuses.sgw, address: '2170 Bishop St.'),
  BuildingCore(code: 'P', name: 'P', campus: Campuses.sgw, address: '2020 Mackay St.'),
  BuildingCore(code: 'PR', name: 'PR Annex', campus: Campuses.sgw, address: '2100 Mackay St.'),
  BuildingCore(code: 'Q', name: 'Q Annex', campus: Campuses.sgw, address: '2010 Mackay St.'),
  BuildingCore(code: 'R', name: 'R Annex', campus: Campuses.sgw, address: '2050 Mackay St.'),
  BuildingCore(code: 'RR', name: 'RR Annex', campus: Campuses.sgw, address: '2040 Mackay St.'),
  BuildingCore(code: 'S', name: 'S Annex', campus: Campuses.sgw, address: '2145 Mackay St.'),
  BuildingCore(code: 'SB', name: 'Samuel Bronfman Building', campus: Campuses.sgw, address: '1590 Docteur Penfield'),
  BuildingCore(code: 'T', name: 'T Annex', campus: Campuses.sgw, address: '2030 Mackay St.'),
  BuildingCore(code: 'TD', name: 'Toronto-Dominion Building', campus: Campuses.sgw, address: '1410 Guy St.'),
  BuildingCore(code: 'V', name: 'V Annex', campus: Campuses.sgw, address: '2110 Mackay St.'),
  BuildingCore(code: 'VA', name: 'Visual Arts Building', campus: Campuses.sgw, address: '1395 René-Lévesque Blvd. W.'),
  BuildingCore(code: 'X', name: 'X Annex', campus: Campuses.sgw, address: '2080 Mackay St.'),
  BuildingCore(code: 'Z', name: 'Z Annex', campus: Campuses.sgw, address: '2090 Mackay St.'),

  // Loyola
  BuildingCore(code: 'AD', name: 'Administration Building', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'BB', name: 'BB Annex', campus: Campuses.loyola, address: '3502 Belmore Ave.'),
  BuildingCore(code: 'BH', name: 'BH Annex', campus: Campuses.loyola, address: '3500 Belmore Ave.'),
  BuildingCore(code: 'CC', name: 'Central Building', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'CJ', name: 'Communication Studies and Journalism Building', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'DO', name: 'Stinger Dome', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'FC', name: 'F.C. Smith Building', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'GE', name: 'Centre for Structural and Functional Genomics', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'HA', name: 'Hingston Hall, wing HA', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'HB', name: 'Hingston Hall, wing HB', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'HC', name: 'Hingston Hall, wing HC', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'HU', name: 'Applied Science Hub', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'JR', name: 'Jesuit Residence', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'PC', name: 'PERFORM Centre', campus: Campuses.loyola, address: Addresses.loyolaOther),
  BuildingCore(code: 'PS', name: 'Physical Services Building', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'PT', name: 'Oscar Peterson Concert Hall', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'PY', name: 'Psychology Building', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'QA', name: 'Quadrangle', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'RA', name: 'Recreation and Athletics Complex', campus: Campuses.loyola, address: Addresses.loyolaOther),
  BuildingCore(code: 'RF', name: 'Loyola Jesuit Hall and Conference Centre', campus: Campuses.loyola, address: Addresses.loyolaOther),
  BuildingCore(code: 'SC', name: 'Student Centre', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'SH', name: 'Future Buildings Laboratory', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'SI', name: 'St. Ignatius of Loyola Church', campus: Campuses.loyola, address: '4455 Broadway St.'),
  BuildingCore(code: 'SP', name: 'Richard J. Renaud Science Complex', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'TA', name: 'Terrebonne Building', campus: Campuses.loyola, address: '7079 Terrebonne St.'),
  BuildingCore(code: 'VE', name: 'Vanier Extension', campus: Campuses.loyola, address: Addresses.loyolaMain),
  BuildingCore(code: 'VL', name: 'Vanier Library', campus: Campuses.loyola, address: Addresses.loyolaMain),
];

const Map<String, List<String>> floorsByCode = {
  'LB': ['1', '2', '3', '4', '5'],
  'MB': ['1', 'S2'],
  'H': ['1', '2', '8', '9'],
  'EV': ['1', '2', '3'],
  'FG': ['1', '2'],
  'B': ['1', '2'],
  'CI': ['1'],
  'D': ['1'],
  'EN': ['1'],
  'ER': ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
  'FA': ['1', '2', '3'],
  'FB': ['1', '2', '3'],
  'LS': ['1', '2'],
  'MI': ['1', '2'],
  'MU': ['1', '2'],
};

const Map<String, List<String>> facilitiesByCode = {
  'LB': [Facilities.washrooms, Facilities.coffeeShop, Facilities.metro],
  'MB': [Facilities.washrooms, Facilities.metro, Facilities.zenDen],
  'H': [
    Facilities.washrooms,
    Facilities.metro,
    Facilities.restaurants,
    Facilities.coffeeShop,
    Facilities.zenDen,
  ],
  'EV': [Facilities.washrooms, Facilities.zenDen, Facilities.coffeeShop, Facilities.metro],
  'GM': [Facilities.washrooms, Facilities.zenDen, Facilities.metro, Facilities.coffeeShop],
  'FG': [Facilities.washrooms, Facilities.restaurants],
  'FB': [Facilities.washrooms, Facilities.parking],
  'LD': [Facilities.washrooms, Facilities.parking],
  'CC': [Facilities.washrooms, Facilities.zenDen],
  'HA': [Facilities.washrooms, Facilities.parking],
  'HB': [Facilities.washrooms, Facilities.parking],
  'HC': [Facilities.washrooms, Facilities.parking],
  'JR': [Facilities.washrooms, Facilities.parking],
  'PC': [Facilities.washrooms, Facilities.parking],
  'RA': [Facilities.washrooms, Facilities.parking],
  'SC': [Facilities.washrooms, Facilities.coffeeShop, Facilities.restaurants],
  'SP': [Facilities.washrooms, Facilities.coffeeShop],
  'TA': [Facilities.washrooms, Facilities.parking],
};

const Set<String> notAccessibleCodes = {
  // SGW
  'B', 'CI', 'D', 'EN', 'FA', 'K', 'M', 'MI', 'MU', 'P', 'PR', 'Q', 'R', 'RR', 'S', 'T', 'TD', 'V', 'X', 'Z',
  // Loyola
  'BB', 'BH', 'DO', 'HB', 'PS', 'SI', 'TA',
};

const Map<String, String> departmentByCode = {
  // SGW
  'H': Departments.engineeringComputerScience,
  'FG': Departments.education,
  'B': Departments.engineeringComputerScience,
  'FA': Departments.religionsCultures,
  'GN': Departments.philosophy,
  'LD': Departments.csuDaycareNursery,
  'RR': Departments.liberalArtsCollege,
  'S': Departments.philosophy,
  'VA': Departments.artHistoryEducation,

  // Loyola
  'AD': Departments.facultyArtsScience,
  'CJ': Departments.communicationStudiesJournalism,
  'DO': Departments.athletics,
  'GE': Departments.research,
  'HA': Departments.residences,
  'HB': Departments.residences,
  'HC': Departments.residences,
  'JR': Departments.residences,
  'PY': Departments.psychology,
  'SH': Departments.research,
  'VE': Departments.appliedHumanSciences,
};

Map<String, BuildingInfo> buildBuildingInfoByCode() {
  final map = <String, BuildingInfo>{};

  for (final core in buildingCores) {
    final code = core.code;

    final details = BuildingDetails(
      floors: floorsByCode[code] ?? const ['0'],
      facilities: facilitiesByCode[code] ?? const [Facilities.washrooms],
      accessibility: !notAccessibleCodes.contains(code),
      department: departmentByCode[code] ?? Departments.various,
    );

    map[code] = BuildingInfo(core: core, details: details);
  }

  return map;
}

final Map<String, BuildingInfo> buildingInfoByCode = buildBuildingInfoByCode();
