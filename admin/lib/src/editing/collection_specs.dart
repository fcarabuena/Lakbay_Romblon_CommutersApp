import 'package:lakbay_core/lakbay_core.dart';

import '../backend/dataset.dart';
import 'field_specs.dart';

/// How one collection is listed and edited.
class CollectionSpec {
  const CollectionSpec({
    required this.collection,
    required this.title,
    required this.singular,
    required this.fields,
    required this.titleOf,
    required this.howTo,
    this.verificationKey = 'verification',
    this.idFromItem,
    this.newItem = const {},
    this.group = 'Other data',
    this.hasPhotos = false,
  });

  final String collection;
  final String title;
  final String singular;
  final List<FieldSpec> fields;

  /// The list title for an item.
  final String Function(Json item, Dataset data) titleOf;

  /// The "How to use this page" tip: a few plain sentences.
  final String howTo;

  /// Where the item's [Verification] lives; null when it has none.
  final String? verificationKey;

  /// For collections without an `id` field (ship fares).
  final String? Function(Json item)? idFromItem;
  final Json newItem;
  final String group;
  final bool hasPhotos;

  IdSpec? get idSpec => fields.whereType<IdSpec>().firstOrNull;

  bool get hasIdField => idSpec != null;

  String docIdOf(Json item) =>
      idFromItem?.call(item) ?? (item['id'] as String? ?? '');
}

// ---------- names for ids ----------

Json? _row(Dataset d, String collection, Object? id) =>
    id is String ? (d.rows[collection]?[id]) : null;

String _name(Dataset d, String collection, Object? id) =>
    _row(d, collection, id)?['name'] as String? ?? '$id';

String placeName(Dataset d, Object? id) {
  for (final c in ['municipalities', 'ports', 'bus_terminals', 'hubs']) {
    final item = _row(d, c, id);
    if (item != null) return item['name'] as String? ?? '$id';
  }
  return '$id';
}

/// "Odiongan Port" → "Odiongan", for short labels and ids.
String shortPlace(Dataset d, Object? id) =>
    placeName(d, id).replaceAll(RegExp(r'\s+(Port|Pier|Terminal)$'), '');

String _en(Object? text) => text == null ? '' : LocalizedText.fromJson(text).en;

/// "19:30" → "7:30 PM".
String clock12(String? hhmm) {
  if (hhmm == null) return '';
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm);
  if (m == null) return hhmm;
  final h = int.parse(m.group(1)!);
  final suffix = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.group(2)} $suffix';
}

List<Json> _stops(Json voyage) =>
    (voyage['stops'] as List<Object?>? ?? const []).whereType<Json>().toList();

/// "MV One · Odiongan → Batangas · leaves 8:00 PM".
String voyageLabel(Json v, Dataset d) {
  final stops = _stops(v);
  if (stops.isEmpty) return '${v['vesselName'] ?? v['id']}';
  return '${v['vesselName']} · ${shortPlace(d, stops.first['portId'])} → '
      '${shortPlace(d, stops.last['portId'])} · leaves ${clock12(stops.first['depart'] as String?)}';
}

// ---------- id builders (top level so specs can be const) ----------

String? _idFromName(Json draft, Dataset _) => draft['name'] as String?;

String? _idVoyage(Json v, Dataset d) {
  final stops = _stops(v);
  if (v['vesselName'] == null || stops.isEmpty) return null;
  final time = (stops.first['depart'] as String? ?? '').replaceAll(':', '');
  return '${v['vesselName']} ${shortPlace(d, stops.first['portId'])} ${shortPlace(d, stops.last['portId'])} $time';
}

String? _idBusRoute(Json r, Dataset d) =>
    r['operatorId'] == null || r['originId'] == null
    ? null
    : '${_name(d, 'bus_operators', r['operatorId'])} ${shortPlace(d, r['originId'])}';

String? _idLocalRide(Json r, Dataset d) =>
    r['fromId'] == null || r['toId'] == null
    ? null
    : '${shortPlace(d, r['fromId'])} ${shortPlace(d, r['toId'])} ${r['mode'] ?? ''}';

String? _idGuide(Json g, Dataset _) =>
    g['placeId'] == null ? null : 'guide ${g['placeId']}';

String? _idHotline(Json h, Dataset _) =>
    h['agency'] == null ? null : '${h['agency']} ${_en(h['label'])}';

String? _idTitle(Json t, Dataset _) =>
    _en(t['title']).isEmpty ? null : _en(t['title']);

String? _idChecklist(Json c, Dataset _) => c['direction'] as String?;

String _poiId(Json item, int index) => slugId(
  _en(item['label']).isEmpty ? 'point_${index + 1}' : _en(item['label']),
);

// ---------- show/hide rules ----------

bool _notFirst(FieldContext c) => !c.isFirst;
bool _notLast(FieldContext c) => !c.isLast;
bool _portScope(FieldContext c) => c.item['scope'] == 'port';
bool _townScope(FieldContext c) => c.item['scope'] == 'municipality';

// ---------- choice limits ----------

List<String>? _voyagePorts(Json fare, Dataset d) {
  final voyage = _row(d, 'voyages', fare['voyageId']);
  return voyage == null
      ? null
      : [for (final s in _stops(voyage)) s['portId'] as String];
}

List<String>? _voyagePortsAfterFrom(Json fare, Dataset d) {
  final ports = _voyagePorts(fare, d);
  if (ports == null) return null;
  final from = ports.indexOf(fare['fromPortId'] as String? ?? '');
  return from < 0 ? ports : ports.sublist(from + 1);
}

// ---------- shared choices ----------

const _yourName = 'Write what travellers will read.';

const facilityChoices = [
  Choice('ticket_office', 'Ticket office'),
  Choice('waiting_area', 'Waiting area'),
  Choice('restroom', 'Restroom'),
  Choice('food', 'Food stalls'),
  Choice('parking', 'Parking'),
  Choice('baggage', 'Baggage / porter area'),
  Choice('drinking_water', 'Drinking water'),
  Choice('charging', 'Phone charging'),
  Choice('pwd_access', 'Ramp / PWD access'),
  Choice('first_aid', 'First aid'),
  Choice('security', 'Security or Coast Guard desk'),
];

const islandChoices = [
  Choice('Tablas', 'Tablas'),
  Choice('Sibuyan', 'Sibuyan'),
  Choice('Romblon', 'Romblon'),
  Choice('Banton', 'Banton'),
  Choice('Maestro de Campo', 'Maestro de Campo'),
  Choice('Simara', 'Simara'),
  Choice('Carabao', 'Carabao'),
  Choice('Other', 'Other'),
];

const rideModeChoices = [
  Choice('tricycle', 'Tricycle'),
  Choice('jeepney', 'Jeepney'),
  Choice('van', 'Van'),
  Choice('multicab', 'Multicab'),
  Choice('habalHabal', 'Habal-habal'),
  Choice('pumpboat', 'Pumpboat'),
  Choice('taxi', 'Taxi / Grab'),
  Choice('walk', 'Walk'),
];

const areaKindChoices = [
  Choice('entrance', 'Entrance'),
  Choice('ticketing', 'Ticket office'),
  Choice('waiting', 'Waiting area'),
  Choice('restroom', 'Restroom'),
  Choice('food', 'Food'),
  Choice('baggage', 'Baggage'),
  Choice('gate', 'Gate'),
  Choice('boarding', 'Boarding area'),
  Choice('transport', 'Rides / bus area'),
  Choice('security', 'Security'),
  Choice('office', 'Office'),
  Choice('other', 'Other'),
];

const _verify = 'the "I verified" box at the bottom';

const fareClassChoices = [
  Choice('economy', 'Economy'),
  Choice('tourist', 'Tourist (air-conditioned)'),
  Choice('cabin', 'Cabin'),
  Choice('comfort', 'Comfort (reclining seat)'),
  Choice('premium', 'Premium (air-conditioned)'),
  Choice('reclining', 'Reclining seat'),
  Choice('economy_bed', 'Economy bed'),
  Choice('tourist_bed', 'Tourist bed'),
  Choice('vip_room', 'VIP room'),
];

const farePriceChoices = [
  Choice('student', 'Student'),
  Choice('senior', 'Senior citizen'),
  Choice('pwd', 'PWD'),
  Choice('halfFare', 'Half fare'),
  Choice('minor', 'Minor (2–11 years)'),
  Choice('infant', 'Infant (under 2)'),
];

String fareClassName(Object? code) =>
    fareClassChoices.where((c) => c.value == code).firstOrNull?.label ??
    '$code';

final collectionSpecs = <CollectionSpec>[
  CollectionSpec(
    collection: 'advisories',
    title: 'Advisories',
    singular: 'advisory',
    group: 'Travel',
    verificationKey: null,
    howTo:
        'Publish a notice when trips are affected by weather, a Coast Guard order or a port change. '
        'Only use official sources and name them. When it is over, open it and press "End now".',
    titleOf: (i, _) =>
        '${switch (i['severity']) {
          'suspended' => 'Suspended',
          'caution' => 'Caution',
          _ => 'Notice',
        }}: ${_en(i['title'])}',
    newItem: {
      'type': 'coastGuard',
      'severity': 'caution',
      'affectedPortIds': <String>[],
      'affectedVoyageIds': <String>[],
    },
    fields: const [
      IdSpec(),
      ChoiceSpec(
        'severity',
        'How serious is it?',
        [
          Choice(
            'info',
            'Notice',
            description: 'For information only. Travellers see a blue banner.',
            tone: 'notice',
          ),
          Choice(
            'caution',
            'Caution',
            description: 'Trips may be delayed or rough. Amber banner.',
            tone: 'caution',
          ),
          Choice(
            'suspended',
            'Suspended',
            description: 'Trips are not sailing. Red banner.',
            tone: 'suspended',
          ),
        ],
        required: true,
        style: ChoiceStyle.cards,
        help: 'Push alerts for Caution and Suspended are not active yet (free plan). Phones show the banner after they update.',
      ),
      ChoiceSpec('type', 'Who issued it?', [
        Choice('weather', 'Weather (PAGASA)'),
        Choice('coastGuard', 'Coast Guard'),
        Choice('portNotice', 'Port notice'),
        Choice('operatorNotice', 'Shipping line notice'),
      ], required: true),
      LocalizedSpec(
        'title',
        'Headline',
        required: true,
        help: 'Short, shown on the banner.',
        example: 'Trips to Batangas suspended',
      ),
      LocalizedSpec(
        'message',
        'Details',
        required: true,
        multiline: true,
        help: 'What travellers should know and do.',
        example: 'Gale warning. No trips from Odiongan until further notice. Wait for the Coast Guard to lift it.',
      ),
      DateTimeSpec(
        'validFrom',
        'Starts',
        required: true,
        help: 'Philippine time. Usually now.',
      ),
      DateTimeSpec(
        'validUntil',
        'Ends',
        openEndedLabel: 'Until further notice',
        help: 'Philippine time.',
      ),
      TextSpec(
        'source',
        'Source',
        required: true,
        help: 'Where it came from, and when.',
        example: 'PCG Romblon bulletin, 12:00 noon',
      ),
      MultiRefSpec(
        'affectedPortIds',
        'Which ports?',
        RefTarget.ports,
        help: 'Choose none (and no voyages) if it affects all sea trips in Romblon.',
      ),
      MultiRefSpec(
        'affectedVoyageIds',
        'Which voyages?',
        RefTarget.voyages,
        help: 'Optional. Choose specific sailings if only some are affected.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'ship_fares',
    title: 'Ship fares',
    singular: 'ship fare',
    group: 'Travel',
    howTo:
        'One fare is the price for one class between two stops of a voyage. '
        'Choose the voyage first, then where the passenger gets on and off. '
        'If you checked the price with the shipping line today, tick $_verify.',
    titleOf: (i, d) =>
        '${shortPlace(d, i['fromPortId'])} → ${shortPlace(d, i['toPortId'])} · '
        '${fareClassName(i['fareClass'])} · ${_row(d, 'voyages', i['voyageId'])?['vesselName'] ?? i['voyageId']}',
    idFromItem: (i) =>
        i['voyageId'] == null ? null : TravelData.documentId('ship_fares', i),
    newItem: {'fareClass': 'economy'},
    fields: const [
      RefSpec(
        'voyageId',
        'Voyage',
        RefTarget.voyages,
        required: true,
        help: 'The sailing this fare is for.',
      ),
      RefSpec(
        'fromPortId',
        'Gets on at',
        RefTarget.ports,
        required: true,
        only: _voyagePorts,
      ),
      RefSpec(
        'toPortId',
        'Gets off at',
        RefTarget.ports,
        required: true,
        only: _voyagePortsAfterFrom,
      ),
      ChoiceSpec('fareClass', 'Class', fareClassChoices, required: true),
      PesoSpec(
        'farePhp',
        'Regular fare',
        required: true,
        help: 'Full adult price, before discounts. For a room, the price of the whole room.',
        example: '650',
      ),
      IntSpec(
        'roomFor',
        'Room for how many people?',
        min: 1,
        help: 'Only for room prices (e.g. a VIP room for 2). Leave empty for per-person fares.',
      ),
      PesoTableSpec(
        'pricesPhp',
        'Prices the company publishes',
        farePriceChoices,
        help: "Fill in only the prices on the company's own price list. Empty ones use the standard discounts.",
      ),
      JsonSpec(
        'pricesVerification',
        'Separate check for the published prices',
        help: 'Only if those prices were checked differently from the regular fare.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'voyages',
    title: 'Voyages',
    singular: 'voyage',
    group: 'Travel',
    howTo:
        'A voyage is one scheduled sailing: the ship, the days it leaves, and each port it stops at in order. '
        'Add the stops from first to last. Fares are added separately under Ship fares.',
    titleOf: (i, d) => voyageLabel(i, d),
    newItem: {
      'daysOfWeek': <int>[],
      'checkInMinutes': 60,
      'stops': <Object?>[],
    },
    fields: const [
      IdSpec(from: _idVoyage),
      RefSpec(
        'lineId',
        'Shipping line',
        RefTarget.shippingLines,
        required: true,
      ),
      TextSpec(
        'vesselName',
        'Ship name',
        required: true,
        example: 'MV Maria Isabel',
      ),
      DaysSpec(
        'daysOfWeek',
        'Leaves on',
        help: 'The days the ship leaves its first port.',
      ),
      BoolSpec(
        'timesToConfirm',
        'Some days or times are not known yet',
        help:
            'Turn on to save a voyage with missing days or times. Travellers see "To be confirmed", '
            'and the trip planner skips legs without both times.',
      ),
      LocalizedSpec(
        'note',
        'Note for travellers',
        example: 'Schedule subject to change without prior notice.',
      ),
      IntSpec(
        'checkInMinutes',
        'Be at the port this many minutes before leaving',
        minutes: true,
        example: '60',
      ),
      IntSpec(
        'delayAllowanceMinutes',
        'Usual delay to allow for (minutes)',
        minutes: true,
        help: 'Added to the longest travel time. 0 if it is usually on time.',
      ),
      ObjectListSpec(
        'stops',
        'Stops, from first to last',
        [
          RefSpec('portId', 'Port', RefTarget.ports, required: true),
          ClockSpec('arrive', 'Arrives', visibleWhen: _notFirst),
          ClockSpec('depart', 'Leaves', visibleWhen: _notLast),
          BoolSpec(
            'estimated',
            'These times are estimates',
            help: 'e.g. worked out from "about 10 hours". Travellers see "(estimate)".',
          ),
          ChoiceSpec(
            'dayOffset',
            'Which day of the trip?',
            [
              Choice(0, 'Same day'),
              Choice(1, 'Next day'),
              Choice(2, '2 days later'),
            ],
            help: 'For overnight trips, later stops are often the next day.',
            style: ChoiceStyle.radio,
            defaultValue: 0,
          ),
        ],
        itemLabel: 'Stop',
        minItems: 2,
      ),
    ],
  ),
  CollectionSpec(
    collection: 'bus_routes',
    title: 'Bus routes',
    singular: 'bus route',
    group: 'Travel',
    howTo:
        'A bus route is a bus company\'s service from one terminal, with the places it drops passengers off. '
        'Fares and travel times are counted from where the bus leaves.',
    titleOf: (i, d) =>
        '${_name(d, 'bus_operators', i['operatorId'])} · from ${placeName(d, i['originId'])}',
    newItem: {'aircon': true, 'dropOffs': <Object?>[]},
    fields: const [
      IdSpec(from: _idBusRoute),
      RefSpec(
        'operatorId',
        'Bus company',
        RefTarget.busOperators,
        required: true,
      ),
      RefSpec(
        'originId',
        'Leaves from',
        RefTarget.places,
        required: true,
        help: 'Usually the port\'s bus terminal.',
      ),
      ClockSpec('firstTrip', 'First bus', required: true),
      ClockSpec('lastTrip', 'Last bus', required: true),
      IntSpec(
        'headwayMinutes',
        'A bus leaves every … minutes',
        required: true,
        min: 1,
        minutes: true,
        example: '30',
      ),
      BoolSpec('aircon', 'Air-conditioned', defaultValue: true),
      ObjectListSpec(
        'dropOffs',
        'Drop-off places',
        [
          RefSpec('placeId', 'Place', RefTarget.places, required: true),
          RangeSpec(
            'farePhp',
            'Fare from where the bus leaves',
            required: true,
            pesos: true,
            example: '420',
          ),
          RangeSpec(
            'minutes',
            'Travel time',
            required: true,
            help: 'In minutes.',
            example: '180',
          ),
        ],
        itemLabel: 'Drop-off',
        minItems: 1,
      ),
    ],
  ),
  CollectionSpec(
    collection: 'local_rides',
    title: 'Local rides',
    singular: 'local ride',
    group: 'Travel',
    howTo:
        'Short rides between a town, a port and a terminal: tricycle, jeepney, van and so on. '
        'If the price varies, switch on "It varies" and give the lowest and highest.',
    titleOf: (i, d) =>
        '${rideModeChoices.where((c) => c.value == i['mode']).firstOrNull?.label ?? i['mode']}: '
        '${placeName(d, i['fromId'])} → ${placeName(d, i['toId'])}',
    newItem: {'mode': 'tricycle', 'perPerson': true, 'bidirectional': true},
    fields: const [
      IdSpec(from: _idLocalRide),
      RefSpec('fromId', 'From', RefTarget.places, required: true),
      RefSpec('toId', 'To', RefTarget.places, required: true),
      ChoiceSpec('mode', 'Type of ride', rideModeChoices, required: true),
      RangeSpec('farePhp', 'Fare', pesos: true, example: '50'),
      ChoiceSpec(
        'perPerson',
        'The fare is for',
        [
          Choice(true, 'Each person'),
          Choice(false, 'The whole ride (shared by the group)'),
        ],
        style: ChoiceStyle.radio,
        defaultValue: true,
      ),
      RangeSpec(
        'minutes',
        'Travel time',
        required: true,
        help: 'In minutes.',
        example: '20',
      ),
      BoolSpec(
        'bidirectional',
        'Same fare and time in both directions',
        defaultValue: true,
      ),
      LocalizedSpec(
        'note',
        'Note for travellers',
        example: 'Agree on the fare before riding.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'ports',
    title: 'Ports',
    singular: 'port',
    group: 'Places',
    verificationKey: 'terminalFeeVerification',
    howTo:
        'Fill in the port\'s name and town, then press "Pick on map" and drag the pin to the port entrance. '
        'Tick the facilities that are really there. If you checked the terminal fee today, tick $_verify.',
    titleOf: (i, _) => '${i['name']}',
    newItem: {'side': 'romblon', 'terminalFeePhp': 0},
    fields: const [
      IdSpec(from: _idFromName),
      TextSpec(
        'name',
        'Port name',
        required: true,
        help: _yourName,
        example: 'Odiongan Port',
      ),
      RefSpec(
        'municipalityId',
        'Town',
        RefTarget.municipalities,
        help: 'The town the port is in. Leave empty for mainland ports.',
      ),
      ChoiceSpec(
        'side',
        'Where is it?',
        [
          Choice('romblon', 'In Romblon'),
          Choice('mainland', 'Mainland (Batangas, Lucena, Manila)'),
        ],
        required: true,
        style: ChoiceStyle.radio,
      ),
      GeoSpec(
        'location',
        'Location',
        townKey: 'municipalityId',
        help: 'Put the pin on the port entrance.',
      ),
      PesoSpec(
        'terminalFeePhp',
        'Terminal fee per passenger',
        help: 'What each passenger pays at the port. 0 if none.',
        example: '30',
      ),
      CheckboxListSpec(
        'facilities',
        'Facilities',
        facilityChoices,
        help: 'Tick only what is really there.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'guides',
    title: 'Guides & photos',
    singular: 'guide',
    group: 'Places',
    hasPhotos: true,
    howTo:
        'A guide helps first-time travellers find their way around one pier or terminal. '
        'Write short tips in the order a traveller needs them, and add map points you measured on site.',
    titleOf: (i, d) => placeName(d, i['placeId']),
    newItem: {
      'tips': <Object?>[],
      'photos': <Object?>[],
      'pointsOfInterest': <Object?>[],
    },
    fields: const [
      IdSpec(from: _idGuide),
      RefSpec('placeId', 'Pier or terminal', RefTarget.places, required: true),
      LocalizedSpec(
        'summary',
        'Short summary',
        multiline: true,
        example: 'Small port; the ticket office is to the left of the gate.',
      ),
      LocalizedListSpec(
        'tips',
        'Tips',
        itemLabel: 'Tip',
        example: 'Buy your ticket at the window, not from people outside.',
      ),
      ObjectListSpec(
        'pointsOfInterest',
        'Map points',
        [
          LocalizedSpec(
            'label',
            'Name',
            required: true,
            example: 'Ticket office',
          ),
          ChoiceSpec('kind', 'Type', areaKindChoices, defaultValue: 'other'),
          GeoSpec(
            'location',
            'Location',
            help: 'Only add points you checked on site.',
          ),
        ],
        itemLabel: 'Map point',
        itemId: _poiId,
      ),
      JsonSpec(
        'layout',
        'Drawn layout',
        help: 'See docs/guide-layout-format.md. The easy way is "Upload layout image" below.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'hotlines',
    title: 'Hotlines',
    singular: 'hotline',
    group: 'Safety',
    howTo:
        'A wrong emergency number is dangerous. Only enter numbers you confirmed by calling them or from an official notice, '
        'then tick $_verify. Leave the numbers empty if you are not sure; the app then shows "Number needed".',
    titleOf: (i, _) => '${i['agency']}: ${_en(i['label'])}',
    newItem: {'scope': 'municipality', 'numbers': <String>[]},
    fields: const [
      IdSpec(from: _idHotline),
      TextSpec('agency', 'Agency', required: true, example: 'MDRRMO Odiongan'),
      LocalizedSpec(
        'label',
        'What this number is for',
        required: true,
        example: 'Disaster and rescue',
      ),
      ChoiceSpec(
        'scope',
        'Covers',
        [
          Choice('national', 'Whole country'),
          Choice('province', 'Whole province (Romblon)'),
          Choice('port', 'One port'),
          Choice('municipality', 'One town'),
        ],
        required: true,
        style: ChoiceStyle.radio,
      ),
      RefSpec(
        'portId',
        'Which port?',
        RefTarget.ports,
        visibleWhen: _portScope,
      ),
      RefSpec(
        'municipalityId',
        'Which town?',
        RefTarget.municipalities,
        visibleWhen: _townScope,
      ),
      PhoneListSpec(
        'numbers',
        'Phone numbers',
        help: 'One number per box.',
        example: '0917 123 4567',
      ),
      LocalizedSpec('note', 'Note', example: 'Open 24 hours'),
    ],
  ),
  CollectionSpec(
    collection: 'safety_tips',
    title: 'Safety tips',
    singular: 'safety tip',
    group: 'Safety',
    verificationKey: null,
    howTo: 'Short, practical advice for first-time travellers. Keep each tip to a few sentences.',
    titleOf: (i, _) => _en(i['title']),
    newItem: {'category': 'safety'},
    fields: const [
      IdSpec(from: _idTitle),
      ChoiceSpec(
        'category',
        'Kind',
        [
          Choice('scam', 'Scam warning'),
          Choice('safety', 'Safety tip'),
          Choice('cancellation', 'If a trip is cancelled'),
        ],
        required: true,
        style: ChoiceStyle.radio,
      ),
      LocalizedSpec(
        'title',
        'Title',
        required: true,
        example: 'Buy tickets only at the ticket office',
      ),
      LocalizedSpec(
        'body',
        'Text',
        required: true,
        multiline: true,
        example: 'People outside may offer "cheaper" tickets that are fake.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'shipping_lines',
    title: 'Shipping lines',
    singular: 'shipping line',
    verificationKey: null,
    howTo: 'The companies that run the ships. Keep "sample company" on until the company and its fares are confirmed.',
    titleOf: (i, _) => '${i['name']}',
    newItem: {'isPlaceholder': true},
    fields: const [
      IdSpec(from: _idFromName),
      TextSpec(
        'name',
        'Company name',
        required: true,
        example: 'Starhorse Shipping Lines, Inc.',
      ),
      PhoneListSpec(
        'phones',
        'Phone numbers',
        help: 'Travellers can tap to call these.',
        example: '0995 515 9149',
      ),
      TextSpec(
        'contactLabel',
        'Whose numbers are these?',
        example: 'Starlite Cajidiocan office',
      ),
      TextSpec(
        'office',
        'Office address',
        example: 'No. 20 San Antonio St., Brgy. Isabang, Lucena City',
      ),
      TextSpec(
        'website',
        'Official page (link)',
        example: 'https://www.facebook.com/starhorseshippinglines',
      ),
      TextSpec(
        'bookingUrl',
        'Online booking (link)',
        example: 'https://www.chelseatravel.ph/',
      ),
      TextSpec('contact', 'Other contact details', advanced: true),
      BoolSpec(
        'isPlaceholder',
        'This is a sample company, not a real operator',
        defaultValue: true,
        help: 'Turn off only after you have the company\'s permission to list it.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'bus_operators',
    title: 'Bus companies',
    singular: 'bus company',
    verificationKey: null,
    howTo: 'The companies that run buses from the ports to Manila. Keep "sample company" on until confirmed.',
    titleOf: (i, _) => '${i['name']}',
    newItem: {'isPlaceholder': true},
    fields: const [
      IdSpec(from: _idFromName),
      TextSpec(
        'name',
        'Company name',
        required: true,
        example: 'Sample Bus Co. 1',
      ),
      TextSpec(
        'contact',
        'Contact',
        help: 'Phone number or website.',
        example: '0917 123 4567',
      ),
      BoolSpec(
        'isPlaceholder',
        'This is a sample company, not a real operator',
        defaultValue: true,
        help: 'Turn off only after you have the company\'s permission to list it.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'municipalities',
    title: 'Towns',
    singular: 'town',
    group: 'Places',
    verificationKey: null,
    howTo: 'Romblon\'s towns, used as the traveller\'s hometown. Put the map pin on the town centre.',
    titleOf: (i, _) => '${i['name']} (${i['island']})',
    fields: const [
      IdSpec(from: _idFromName),
      TextSpec('name', 'Town name', required: true, example: 'Odiongan'),
      ChoiceSpec('island', 'Island', islandChoices, required: true),
      GeoSpec(
        'location',
        'Location',
        help: 'Put the pin on the town centre (plaza or municipal hall).',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'bus_terminals',
    title: 'Bus terminals',
    singular: 'bus terminal',
    group: 'Places',
    verificationKey: null,
    howTo: 'Terminals where buses leave from, usually next to a mainland port.',
    titleOf: (i, _) => '${i['name']}',
    fields: const [
      IdSpec(from: _idFromName),
      TextSpec(
        'name',
        'Terminal name',
        required: true,
        example: 'Batangas Port Bus Terminal',
      ),
      TextSpec('city', 'City', example: 'Batangas City'),
      RefSpec('portId', 'Serves which port?', RefTarget.ports),
      GeoSpec(
        'location',
        'Location',
        help: 'Put the pin where passengers board.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'hubs',
    title: 'Manila hubs',
    singular: 'hub',
    group: 'Places',
    verificationKey: null,
    howTo: 'The Metro Manila stops travellers can choose as their destination, such as Cubao or PITX.',
    titleOf: (i, _) => '${i['name']}',
    fields: const [
      IdSpec(from: _idFromName),
      TextSpec('name', 'Name', required: true, example: 'Cubao'),
      TextSpec('area', 'Area', required: true, example: 'Quezon City'),
      GeoSpec('location', 'Location'),
      LocalizedSpec(
        'description',
        'Description',
        multiline: true,
        example: 'Many bus terminals along EDSA.',
      ),
    ],
  ),
  CollectionSpec(
    collection: 'checklists',
    title: 'First-Timer checklists',
    singular: 'checklist',
    verificationKey: null,
    howTo: 'Rarely changed. The steps are edited as technical data under Advanced; ask technical staff for help.',
    titleOf: (i, _) => switch (i['direction']) {
      'toManila' => 'To Manila',
      'toRomblon' => 'Going home to Romblon',
      final d => '$d',
    },
    fields: const [
      IdSpec(from: _idChecklist),
      ChoiceSpec(
        'direction',
        'Direction',
        [
          Choice('toManila', 'To Manila'),
          Choice('toRomblon', 'Going home to Romblon'),
        ],
        required: true,
        style: ChoiceStyle.radio,
      ),
      JsonSpec('phases', 'Phases and items', emptyValue: <Object?>[]),
    ],
  ),
];

CollectionSpec? specFor(String collection) =>
    collectionSpecs.where((s) => s.collection == collection).firstOrNull;

/// A new item's id from its fields, unique within the collection.
String? suggestId(CollectionSpec spec, Json draft, Dataset data) {
  final idSpec = spec.idSpec;
  if (idSpec == null) return null;
  final text =
      idSpec.from?.call(draft, data) ??
      (draft['name'] as String?) ??
      _idTitle(draft, data);
  if (text == null || text.trim().isEmpty) return null;
  final base = slugId(text);
  if (base.isEmpty) return null;
  return uniqueId(base, data.rows[spec.collection]?.keys ?? const []);
}
