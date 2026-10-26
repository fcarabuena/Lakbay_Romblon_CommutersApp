import 'package:lakbay_core/lakbay_core.dart';

/// A tiny two-town network used by planner tests.
///
/// Route 1: Town A → Port A (tricycle) → Batangas (ship, overnight) → walk →
///          bus to Cubao. Cheapest, fewest transfers.
/// Route 2: Town A → Port B (van) → Lucena (ship) → jeepney → bus to Cubao.
///          Dearer, but faster.
Map<String, Object?> fixtureCollections() {
  const placeholder = {'source': 'PLACEHOLDER', 'isPlaceholder': true};
  Map<String, Object?> items(List<Map<String, Object?>> list) => {
    'items': list,
  };

  return {
    'meta': {
      'dataVersion': 1,
      'discounts': {
        'percent': {'student': 20, 'senior': 20, 'pwd': 20},
        'verification': placeholder,
      },
    },
    'municipalities': items([
      {'id': 'town_a', 'name': 'Town A', 'island': 'Tablas'},
      {'id': 'town_b', 'name': 'Town B', 'island': 'Tablas'},
    ]),
    'ports': items([
      {
        'id': 'port_a',
        'name': 'Port A',
        'side': 'romblon',
        'municipalityId': 'town_a',
        'terminalFeePhp': 30,
      },
      {
        'id': 'port_b',
        'name': 'Port B',
        'side': 'romblon',
        'municipalityId': 'town_b',
        'terminalFeePhp': 30,
      },
      {
        'id': 'batangas',
        'name': 'Batangas Port',
        'side': 'mainland',
        'terminalFeePhp': 50,
      },
      {
        'id': 'lucena',
        'name': 'Lucena Port',
        'side': 'mainland',
        'terminalFeePhp': 40,
      },
    ]),
    'bus_terminals': items([
      {
        'id': 'bt_batangas',
        'name': 'Batangas Port Terminal',
        'portId': 'batangas',
      },
      {'id': 'bt_lucena', 'name': 'Lucena Terminal', 'portId': 'lucena'},
    ]),
    'hubs': items([
      {'id': 'cubao', 'name': 'Cubao', 'area': 'Quezon City'},
      {'id': 'pitx', 'name': 'PITX', 'area': 'Parañaque'},
    ]),
    'shipping_lines': items([
      {'id': 'line1', 'name': 'Sample Line 1'},
      {'id': 'line2', 'name': 'Sample Line 2'},
    ]),
    'voyages': items([
      {
        'id': 'v1',
        'lineId': 'line1',
        'vesselName': 'MV One',
        'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
        'checkInMinutes': 60,
        'stops': [
          {'portId': 'port_a', 'depart': '20:00'},
          {'portId': 'batangas', 'arrive': '04:00', 'dayOffset': 1},
        ],
      },
      {
        'id': 'v2',
        'lineId': 'line2',
        'vesselName': 'MV Two',
        'daysOfWeek': [1, 3, 5],
        'checkInMinutes': 60,
        'delayAllowanceMinutes': 0,
        'stops': [
          {'portId': 'port_b', 'depart': '18:00'},
          {'portId': 'lucena', 'arrive': '23:00'},
        ],
      },
      {
        'id': 'v3',
        'lineId': 'line1',
        'vesselName': 'MV One',
        'daysOfWeek': [1, 2, 3, 4, 5, 6, 7],
        'checkInMinutes': 60,
        'stops': [
          {'portId': 'batangas', 'depart': '08:00'},
          {'portId': 'port_a', 'arrive': '16:00'},
        ],
      },
    ]),
    'ship_fares': items([
      {
        'voyageId': 'v1',
        'fromPortId': 'port_a',
        'toPortId': 'batangas',
        'fareClass': 'economy',
        'farePhp': 800,
      },
      {
        'voyageId': 'v1',
        'fromPortId': 'port_a',
        'toPortId': 'batangas',
        'fareClass': 'cabin',
        'farePhp': 1500,
      },
      {
        'voyageId': 'v2',
        'fromPortId': 'port_b',
        'toPortId': 'lucena',
        'fareClass': 'economy',
        'farePhp': 700,
      },
      {
        'voyageId': 'v3',
        'fromPortId': 'batangas',
        'toPortId': 'port_a',
        'fareClass': 'economy',
        'farePhp': 800,
      },
    ]),
    'bus_operators': items([
      {'id': 'op1', 'name': 'Sample Bus 1'},
      {'id': 'op2', 'name': 'Sample Bus 2'},
    ]),
    'bus_routes': items([
      {
        'id': 'r1',
        'operatorId': 'op1',
        'originId': 'bt_batangas',
        'firstTrip': '03:00',
        'lastTrip': '22:00',
        'headwayMinutes': 30,
        'dropOffs': [
          {
            'placeId': 'cubao',
            'farePhp': 250,
            'minutes': {'min': 180, 'max': 240},
          },
          {
            'placeId': 'pitx',
            'farePhp': 230,
            'minutes': {'min': 150, 'max': 210},
          },
        ],
      },
      {
        'id': 'r2',
        'operatorId': 'op2',
        'originId': 'bt_lucena',
        'firstTrip': '00:00',
        'lastTrip': '23:30',
        'headwayMinutes': 60,
        'dropOffs': [
          {
            'placeId': 'cubao',
            'farePhp': 350,
            'minutes': {'min': 240, 'max': 300},
          },
        ],
      },
      {
        'id': 'r3',
        'operatorId': 'op1',
        'originId': 'cubao',
        'firstTrip': '00:00',
        'lastTrip': '23:00',
        'headwayMinutes': 30,
        'dropOffs': [
          {
            'placeId': 'bt_batangas',
            'farePhp': 250,
            'minutes': {'min': 180, 'max': 240},
          },
        ],
      },
    ]),
    'local_rides': items([
      {
        'id': 'a_pa',
        'fromId': 'town_a',
        'toId': 'port_a',
        'mode': 'tricycle',
        'farePhp': 50,
        'minutes': {'min': 15, 'max': 20},
      },
      {
        'id': 'a_pb',
        'fromId': 'town_a',
        'toId': 'port_b',
        'mode': 'van',
        'farePhp': 150,
        'minutes': {'min': 45, 'max': 60},
      },
      {
        'id': 'b_pb',
        'fromId': 'town_b',
        'toId': 'port_b',
        'mode': 'tricycle',
        'farePhp': 40,
        'minutes': 10,
      },
      {
        'id': 'bat_walk',
        'fromId': 'batangas',
        'toId': 'bt_batangas',
        'mode': 'walk',
        'minutes': {'min': 5, 'max': 10},
      },
      {
        'id': 'luc_jeep',
        'fromId': 'lucena',
        'toId': 'bt_lucena',
        'mode': 'jeepney',
        'farePhp': 20,
        'minutes': {'min': 20, 'max': 30},
      },
    ]),
    'checklists': items([
      {
        'id': 'to_manila',
        'direction': 'toManila',
        'phases': [
          {
            'id': 'prepare',
            'title': 'Prepare',
            'whatHappensNext': 'Next: go to the pier.',
            'items': [
              {'id': 'id', 'text': 'Bring a valid ID'},
              {'id': 'cash', 'text': 'Bring small bills'},
            ],
          },
          {
            'id': 'to_pier',
            'title': 'Home to pier',
            'legSlot': 'beforeShip',
            'whatHappensNext': 'Next: check in.',
            'items': [],
          },
          {
            'id': 'ship',
            'title': 'On the ship',
            'legSlot': 'ship',
            'whatHappensNext': 'Next: arrive.',
            'items': [
              {'id': 'seat', 'text': 'Find your seat'},
            ],
          },
          {
            'id': 'land',
            'title': 'Bus to Manila',
            'legSlot': 'afterShip',
            'whatHappensNext': 'You have arrived.',
            'items': [],
          },
        ],
      },
      {
        'id': 'to_romblon',
        'direction': 'toRomblon',
        'phases': [
          {
            'id': 'prepare',
            'title': 'Prepare',
            'whatHappensNext': 'Next: bus.',
            'items': [
              {'id': 'id', 'text': 'Bring a valid ID'},
            ],
          },
        ],
      },
    ]),
  };
}

TravelData fixtureData() => TravelData.fromCollections(fixtureCollections());

/// Monday 25 Oct 2027 is used as a fixed reference date in tests.
DateTime monday(int hour, [int minute = 0]) =>
    DateTime.utc(2027, 10, 25, hour, minute);
