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

  const BuildingInfo({required this.core, required this.details});

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

BuildingCore sgw(String code, String name, String address, {String? link}) {
  return BuildingCore(
    code: code,
    name: name,
    campus: Campuses.sgw,
    address: address,
    link: link,
  );
}

BuildingCore loyola(String code, String name, String address, {String? link}) {
  return BuildingCore(
    code: code,
    name: name,
    campus: Campuses.loyola,
    address: address,
    link: link,
  );
}

final List<BuildingCore> buildingCores = [
  // SGW
  sgw('LB', 'LB Building', '1400 De Maisonneuve Blvd. W.'),
  sgw('MB', 'John Molson Building', '1450 Guy St.'),
  sgw('HALL', 'Hall Building', '1455 De Maisonneuve Blvd. W.'),
  sgw(
    'EV',
    'Engineering, Computer Science and Visual Arts Integrated Complex',
    '1515 Ste-Catherine St. W.',
  ),
  sgw('GM', 'Guy-De Maisonneuve Building', '1550 De Maisonneuve Blvd. W.'),
  sgw('FG', 'Faubourg Building', '1610 Ste-Catherine St. W.'),
  sgw('B', 'B annex', '2160 Bishop St.'),
  sgw('CI', 'CI annex', '2149 Mackay St.'),
  sgw('CL', 'CL annex', '1665 Ste-Catherine St. W.'),
  sgw('D', 'D annex', '2140 Bishop St.'),
  sgw('EN', 'EN annex', '2070 Mackay St.'),
  sgw('ER', 'ER building', '2155 Guy St.'),
  sgw('FA', 'FA annex', '2060 Mackay St.'),
  sgw(
    'FB',
    'FB - Faubourg Tower',
    '1250 Guy St. (main entrance), 1600 Ste-Catherine St. W.',
  ),
  sgw(
    'GN',
    'Grey Nuns Building',
    '1190 Guy St. (main entrance) / 1175 St-Mathieu St. / 1185 St-Mathieu St.',
  ),
  sgw('GS', 'GS', '1538 Sherbrooke St. W.'),
  sgw('K', 'K Annex', '2150 Bishop St.'),
  sgw('LD', 'LD', '1424 Bishop St.'),
  sgw('LS', 'Learning Square', '1535 De Maisonneuve Blvd. W.'),
  sgw('M', 'M Annex', '2135 Mackay St.'),
  sgw('MI', 'MI Annex', '2130 Bishop St.'),
  sgw('MU', 'MU', '2170 Bishop St.'),
  sgw('P', 'P', '2020 Mackay St.'),
  sgw('PR', 'PR Annex', '2100 Mackay St.'),
  sgw('Q', 'Q Annex', '2010 Mackay St.'),
  sgw('R', 'R Annex', '2050 Mackay St.'),
  sgw('RR', 'RR Annex', '2040 Mackay St.'),
  sgw('S', 'S Annex', '2145 Mackay St.'),
  sgw('SB', 'Samuel Bronfman Building', '1590 Docteur Penfield'),
  sgw('T', 'T Annex', '2030 Mackay St.'),
  sgw('TD', 'Toronto-Dominion Building', '1410 Guy St.'),
  sgw('V', 'V Annex', '2110 Mackay St.'),
  sgw('VA', 'Visual Arts Building', '1395 René-Lévesque Blvd. W.'),
  sgw('X', 'X Annex', '2080 Mackay St.'),
  sgw('Z', 'Z Annex', '2090 Mackay St.'),

  // Loyola
  loyola('AD', 'Administration Building', Addresses.loyolaMain),
  loyola('BB', 'BB Annex', '3502 Belmore Ave.'),
  loyola('BH', 'BH Annex', '3500 Belmore Ave.'),
  loyola('CC', 'Central Building', Addresses.loyolaMain),
  loyola(
    'CJ',
    'Communication Studies and Journalism Building',
    Addresses.loyolaMain,
  ),
  loyola('DO', 'Stinger Dome', Addresses.loyolaMain),
  loyola('FC', 'F.C. Smith Building', Addresses.loyolaMain),
  loyola(
    'GE',
    'Centre for Structural and Functional Genomics',
    Addresses.loyolaMain,
  ),
  loyola('HA', 'Hingston Hall, wing HA', Addresses.loyolaMain),
  loyola('HB', 'Hingston Hall, wing HB', Addresses.loyolaMain),
  loyola('HC', 'Hingston Hall, wing HC', Addresses.loyolaMain),
  loyola('HU', 'Applied Science Hub', Addresses.loyolaMain),
  loyola('JR', 'Jesuit Residence', Addresses.loyolaMain),
  loyola('PC', 'PERFORM Centre', Addresses.loyolaOther),
  loyola('PS', 'Physical Services Building', Addresses.loyolaMain),
  loyola('PT', 'Oscar Peterson Concert Hall', Addresses.loyolaMain),
  loyola('PY', 'Psychology Building', Addresses.loyolaMain),
  loyola('QA', 'Quadrangle', Addresses.loyolaMain),
  loyola('RA', 'Recreation and Athletics Complex', Addresses.loyolaOther),
  loyola(
    'RF',
    'Loyola Jesuit Hall and Conference Centre',
    Addresses.loyolaOther,
  ),
  loyola('SC', 'Student Centre', Addresses.loyolaMain),
  loyola('SH', 'Future Buildings Laboratory', Addresses.loyolaMain),
  loyola('SI', 'St. Ignatius of Loyola Church', '4455 Broadway St.'),
  loyola('SP', 'Richard J. Renaud Science Complex', Addresses.loyolaMain),
  loyola('TA', 'Terrebonne Building', '7079 Terrebonne St.'),
  loyola('VE', 'Vanier Extension', Addresses.loyolaMain),
  loyola('VL', 'Vanier Library', Addresses.loyolaMain),
];

const Map<String, List<String>> floorsByCode = {
  'LB': ['1', '2', '3', '4', '5'],
  'MB': ['1', 'S2'],
  'HALL': ['1', '2', '8', '9'],
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

const List<String> washroomsParking = [
  Facilities.washrooms,
  Facilities.parking,
];

final Map<String, List<String>> facilitiesByCode = buildFacilitiesByCode();

Map<String, List<String>> buildFacilitiesByCode() {
  return {
    'LB': [Facilities.washrooms, Facilities.coffeeShop, Facilities.metro],
    'MB': [Facilities.washrooms, Facilities.metro, Facilities.zenDen],
    'HALL': [
      Facilities.washrooms,
      Facilities.metro,
      Facilities.restaurants,
      Facilities.coffeeShop,
      Facilities.zenDen,
    ],
    'EV': [
      Facilities.washrooms,
      Facilities.zenDen,
      Facilities.coffeeShop,
      Facilities.metro,
    ],
    'GM': [
      Facilities.washrooms,
      Facilities.zenDen,
      Facilities.metro,
      Facilities.coffeeShop,
    ],
    'FG': [Facilities.washrooms, Facilities.restaurants],
    'FB': washroomsParking,
    'LD': washroomsParking,
    'CC': [Facilities.washrooms, Facilities.zenDen],
    for (final code in ['HA', 'HB', 'HC', 'JR', 'PC', 'RA', 'TA'])
      code: washroomsParking,
    'SC': [Facilities.washrooms, Facilities.coffeeShop, Facilities.restaurants],
    'SP': [Facilities.washrooms, Facilities.coffeeShop],
  };
}

const Set<String> notAccessibleCodes = {
  // SGW
  'B',
  'CI',
  'D',
  'EN',
  'FA',
  'K',
  'M',
  'MI',
  'MU',
  'P',
  'PR',
  'Q',
  'R',
  'RR',
  'S',
  'T',
  'TD',
  'V',
  'X',
  'Z',

  // Loyola
  'BB',
  'BH',
  'DO',
  'HB',
  'PS',
  'SI',
  'TA',
};

final Map<String, String> departmentByCode = buildDepartmentByCode();

Map<String, String> buildDepartmentByCode() {
  return {
    // SGW
    'HALL': Departments.engineeringComputerScience,
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
    'PY': Departments.psychology,
    'VE': Departments.appliedHumanSciences,
    for (final code in ['GE', 'SH']) code: Departments.research,
    for (final code in ['HA', 'HB', 'HC', 'JR']) code: Departments.residences,
  };
}

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
