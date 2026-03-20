/// Contains mappings between building codes and their full names for search functionality
class BuildingName {
  final String code;
  final String name;
  final List<String> searchTerms;

  const BuildingName({
    required this.code,
    required this.name,
    this.searchTerms = const [],
  });
}

class _BuildingSeed {
  final String code;
  final String? name;
  final List<String> searchTerms;

  const _BuildingSeed({
    required this.code,
    this.name,
    this.searchTerms = const [],
  });
}

BuildingName _fromSeed(_BuildingSeed seed) {
  return BuildingName(
    code: seed.code,
    name: seed.name ?? seed.code,
    searchTerms: seed.searchTerms,
  );
}

BuildingName _annexBuilding(String code, List<String> searchTerms) {
  return BuildingName(
    code: code,
    name: '$code annex',
    searchTerms: searchTerms,
  );
}

const List<_BuildingSeed> _sgwSeeds = [
  _BuildingSeed(code: 'LB', name: 'LB Building', searchTerms: ['lb']),
  _BuildingSeed(
    code: 'MB',
    name: 'JMSB Building',
    searchTerms: ['mb, jmsb, jsmb'],
  ),
  _BuildingSeed(
    code: 'HALL',
    name: 'Hall Building',
    searchTerms: ['hall', 'h', 'HALL'],
  ),
  _BuildingSeed(
    code: 'EV',
    name: 'EV Building',
    searchTerms: ['ev', 'engineering', 'visual arts'],
  ),
  _BuildingSeed(
    code: 'GM',
    name: 'GM Building',
    searchTerms: ['gm', 'guy metro'],
  ),
  _BuildingSeed(
    code: 'FG',
    name: 'Faubourg Building',
    searchTerms: ['faubourg', 'fg'],
  ),
  _BuildingSeed(code: 'ER', name: 'ER building', searchTerms: ['er']),
  _BuildingSeed(
    code: 'FB',
    name: 'FB - Faubourg Tower',
    searchTerms: ['fb', 'faubourg', 'tower'],
  ),
  _BuildingSeed(
    code: 'GN',
    name: 'Grey Nuns Building',
    searchTerms: ['grey nuns', 'gn'],
  ),
  _BuildingSeed(code: 'GS', searchTerms: ['gs']),
  _BuildingSeed(code: 'K', searchTerms: ['k']),
  _BuildingSeed(code: 'LD', searchTerms: ['ld']),
  _BuildingSeed(
    code: 'LS',
    name: 'Learning Square',
    searchTerms: ['learning square', 'ls'],
  ),
  _BuildingSeed(code: 'M', searchTerms: ['m']),
  _BuildingSeed(code: 'MI', searchTerms: ['mi']),
  _BuildingSeed(code: 'MU', searchTerms: ['mu']),
  _BuildingSeed(code: 'P', searchTerms: ['p']),
  _BuildingSeed(code: 'PR', searchTerms: ['pr']),
  _BuildingSeed(code: 'Q', searchTerms: ['q']),
  _BuildingSeed(code: 'R', searchTerms: ['r']),
  _BuildingSeed(code: 'RR', searchTerms: ['rr']),
  _BuildingSeed(code: 'S', searchTerms: ['s']),
  _BuildingSeed(code: 'SB', searchTerms: ['sb']),
  _BuildingSeed(code: 'T', searchTerms: ['t']),
  _BuildingSeed(code: 'TD', searchTerms: ['td']),
  _BuildingSeed(code: 'V', searchTerms: ['v']),
  _BuildingSeed(code: 'VA', searchTerms: ['va', 'visual arts']),
];

const List<_BuildingSeed> _loyolaSeeds = [
  _BuildingSeed(
    code: 'AD',
    name: 'Administration Building',
    searchTerms: ['administration', 'ad', 'admin'],
  ),
  _BuildingSeed(
    code: 'CC',
    name: 'Central Building',
    searchTerms: ['central', 'cc'],
  ),
  _BuildingSeed(
    code: 'CJ',
    name: 'Communication Studies and Journalism building',
    searchTerms: ['communication', 'journalism', 'cj', 'comm'],
  ),
  _BuildingSeed(
    code: 'DO',
    name: 'Stinger Dome',
    searchTerms: ['stinger', 'dome', 'do'],
  ),
  _BuildingSeed(
    code: 'FC',
    name: 'F.C. Smith building',
    searchTerms: ['fc', 'smith'],
  ),
  _BuildingSeed(
    code: 'GE',
    name: 'Center for structural and functional genomics',
    searchTerms: ['genomics', 'ge', 'center'],
  ),
  _BuildingSeed(
    code: 'HA',
    name: 'Hingston Hall, wing HA',
    searchTerms: ['hingston', 'ha', 'hall'],
  ),
  _BuildingSeed(
    code: 'HB',
    name: 'Hingston Hall, wing HB',
    searchTerms: ['hingston', 'hb', 'hall'],
  ),
  _BuildingSeed(
    code: 'HC',
    name: 'Hingston Hall, wing HC',
    searchTerms: ['hingston', 'hc', 'hall'],
  ),
  _BuildingSeed(
    code: 'HU',
    name: 'Applied Science Hub',
    searchTerms: ['applied science', 'hub', 'hu'],
  ),
  _BuildingSeed(
    code: 'JR',
    name: 'Jesuit Residence',
    searchTerms: ['jesuit', 'residence', 'jr'],
  ),
  _BuildingSeed(
    code: 'PC',
    name: 'PERFORM center',
    searchTerms: ['perform', 'pc', 'center'],
  ),
  _BuildingSeed(
    code: 'PS',
    name: 'Physical Services building',
    searchTerms: ['physical services', 'ps'],
  ),
  _BuildingSeed(
    code: 'PT',
    name: 'Oscar Peterson Concert Hall',
    searchTerms: ['oscar peterson', 'concert', 'hall', 'pt'],
  ),
  _BuildingSeed(
    code: 'PY',
    name: 'Psychology building',
    searchTerms: ['psychology', 'py', 'psych'],
  ),
  _BuildingSeed(
    code: 'QA',
    name: 'Quadrangle',
    searchTerms: ['quadrangle', 'qa', 'quad'],
  ),
  _BuildingSeed(
    code: 'RA',
    name: 'Recreation and Athletic Complex',
    searchTerms: ['recreation', 'athletic', 'ra', 'rec'],
  ),
  _BuildingSeed(
    code: 'RF',
    name: 'Loyola Jesuit Hall and Conference Centre',
    searchTerms: ['loyola', 'jesuit', 'conference', 'rf'],
  ),
  _BuildingSeed(
    code: 'SC',
    name: 'Student Centre',
    searchTerms: ['student', 'centre', 'center', 'sc'],
  ),
  _BuildingSeed(
    code: 'SH',
    name: 'Future Buildings Laboratory',
    searchTerms: ['future buildings', 'laboratory', 'sh', 'lab'],
  ),
  _BuildingSeed(
    code: 'SI',
    name: 'St. Ignatus of Loyola Church',
    searchTerms: ['st ignatus', 'loyola', 'church', 'si', 'saint'],
  ),
  _BuildingSeed(
    code: 'SP',
    name: 'Richard J. Renaud Science Complex',
    searchTerms: ['richard renaud', 'science', 'sp', 'complex'],
  ),
  _BuildingSeed(
    code: 'TA',
    name: 'Terrebonne Building',
    searchTerms: ['terrebonne', 'ta'],
  ),
  _BuildingSeed(
    code: 'VE',
    name: 'Vanier Extension',
    searchTerms: ['vanier', 'extension', 've'],
  ),
  _BuildingSeed(
    code: 'VL',
    name: 'Vanier Library',
    searchTerms: ['vanier', 'library', 'vl'],
  ),
];

const List<MapEntry<String, List<String>>> _annexSeeds = [
  MapEntry('B', ['b', 'annex']),
  MapEntry('CI', ['ci', 'annex']),
  MapEntry('CL', ['cl', 'annex']),
  MapEntry('D', ['d', 'annex']),
  MapEntry('EN', ['en', 'annex']),
  MapEntry('FA', ['fa', 'annex']),
  MapEntry('BB', ['bb', 'annex']),
  MapEntry('BH', ['bh', 'annex']),
];

final List<BuildingName> _sgwBuildings = _sgwSeeds.map(_fromSeed).toList();

final List<BuildingName> _sgwAnnexBuildings = _annexSeeds
    .take(6)
    .map((entry) => _annexBuilding(entry.key, entry.value))
    .toList();

final List<BuildingName> _loyolaLeadBuildings = _loyolaSeeds
    .take(1)
    .map(_fromSeed)
    .toList();

final List<BuildingName> _loyolaAnnexBuildings = _annexSeeds
    .skip(6)
    .map((entry) => _annexBuilding(entry.key, entry.value))
    .toList();

final List<BuildingName> _loyolaRemainingBuildings = _loyolaSeeds
    .skip(1)
    .map(_fromSeed)
    .toList();

final List<BuildingName> concordiaBuildingNames = [
  ..._sgwBuildings,
  ..._sgwAnnexBuildings,
  ..._loyolaLeadBuildings,
  ..._loyolaAnnexBuildings,
  ..._loyolaRemainingBuildings,
];
