import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';
import 'package:frontend/app/app.dart';

void main() {
  testWidgets('App load test', (WidgetTester tester) async {
    final queryClient = QueryClient(
      cache: QueryCache.instance,
      networkPolicy: NetworkPolicy.instance,
    );

    await tester.pumpWidget(VitalinkApp(queryClient: queryClient));
    
    expect(find.byType(VitalinkApp), findsOneWidget);
  });
}