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

List<String> _parseSearchTerms(String value) {
  if (value.trim().isEmpty) {
    return const [];
  }

  return value
      .split(';')
      .map((term) => term.trim())
      .where((term) => term.isNotEmpty)
      .toList(growable: false);
}

List<_BuildingSeed> _parseBuildingSeeds(String rows) {
  final seeds = <_BuildingSeed>[];

  for (final rawRow in rows.trim().split('\n')) {
    final row = rawRow.trim();
    if (row.isEmpty) continue;

    final parts = row.split('|');
    if (parts.length != 3) {
      throw FormatException('Invalid building seed row: $row');
    }

    final code = parts[0].trim();
    final rawName = parts[1].trim();
    seeds.add(
      _BuildingSeed(
        code: code,
        name: rawName.isEmpty ? null : rawName,
        searchTerms: _parseSearchTerms(parts[2]),
      ),
    );
  }

  return seeds;
}

List<MapEntry<String, List<String>>> _parseAnnexSeeds(String rows) {
  final seeds = <MapEntry<String, List<String>>>[];

  for (final rawRow in rows.trim().split('\n')) {
    final row = rawRow.trim();
    if (row.isEmpty) continue;

    final parts = row.split('|');
    if (parts.length != 2) {
      throw FormatException('Invalid annex seed row: $row');
    }

    seeds.add(MapEntry(parts[0].trim(), _parseSearchTerms(parts[1])));
  }

  return seeds;
}

const String _sgwSeedRows = '''
LB|LB Building|lb
MB|JMSB Building|mb, jmsb, jsmb
HALL|Hall Building|hall;h;HALL
EV|EV Building|ev;engineering;visual arts
GM|GM Building|gm;guy metro
FG|Faubourg Building|faubourg;fg
ER|ER building|er
FB|FB - Faubourg Tower|fb;faubourg;tower
GN|Grey Nuns Building|grey nuns;gn
GS||gs
K||k
LD||ld
LS|Learning Square|learning square;ls
M||m
MI||mi
MU||mu
P||p
PR||pr
Q||q
R||r
RR||rr
S||s
SB||sb
T||t
TD||td
V||v
VA||va;visual arts
''';

const String _loyolaSeedRows = '''
AD|Administration Building|administration;ad;admin
CC|Central Building|central;cc
CJ|Communication Studies and Journalism building|communication;journalism;cj;comm
DO|Stinger Dome|stinger;dome;do
FC|F.C. Smith building|fc;smith
GE|Center for structural and functional genomics|genomics;ge;center
HA|Hingston Hall, wing HA|hingston;ha;hall
HB|Hingston Hall, wing HB|hingston;hb;hall
HC|Hingston Hall, wing HC|hingston;hc;hall
HU|Applied Science Hub|applied science;hub;hu
JR|Jesuit Residence|jesuit;residence;jr
PC|PERFORM center|perform;pc;center
PS|Physical Services building|physical services;ps
PT|Oscar Peterson Concert Hall|oscar peterson;concert;hall;pt
PY|Psychology building|psychology;py;psych
QA|Quadrangle|quadrangle;qa;quad
RA|Recreation and Athletic Complex|recreation;athletic;ra;rec
RF|Loyola Jesuit Hall and Conference Centre|loyola;jesuit;conference;rf
SC|Student Centre|student;centre;center;sc
SH|Future Buildings Laboratory|future buildings;laboratory;sh;lab
SI|St. Ignatus of Loyola Church|st ignatus;loyola;church;si;saint
SP|Richard J. Renaud Science Complex|richard renaud;science;sp;complex
TA|Terrebonne Building|terrebonne;ta
VE|Vanier Extension|vanier;extension;ve
VL|Vanier Library|vanier;library;vl
''';

const String _annexSeedRows = '''
B|b;annex
CI|ci;annex
CL|cl;annex
D|d;annex
EN|en;annex
FA|fa;annex
BB|bb;annex
BH|bh;annex
''';

final List<_BuildingSeed> _sgwSeeds = _parseBuildingSeeds(_sgwSeedRows);

final List<_BuildingSeed> _loyolaSeeds = _parseBuildingSeeds(_loyolaSeedRows);

final List<MapEntry<String, List<String>>> _annexSeeds = _parseAnnexSeeds(
  _annexSeedRows,
);

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
