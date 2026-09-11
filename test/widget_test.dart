import 'package:flutter_test/flutter_test.dart';

import 'package:ev_charging_p2p/main.dart';

void main() {
  testWidgets('EV charging app loads the map screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const EVChargingApp());

    expect(find.text('⚡ Nearby EV Stations'), findsOneWidget);
    expect(find.text('Solar Home Charger - 22kW Fast AC'), findsNothing);
  });
}
