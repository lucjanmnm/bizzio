import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyWidget has a title and message', (WidgetTester tester) async {
    // Build the widget.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Title'),
              Text('Message'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
  });

  testWidgets('Button tap increments counter', (WidgetTester tester) async {
    int counter = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Text('Count: $counter', key: const Key('counter')),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        counter++;
                      });
                    },
                    child: const Text('Increment'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Count: 0'), findsOneWidget);

    await tester.tap(find.text('Increment'));
    await tester.pump();

    expect(find.text('Count: 1'), findsOneWidget);
  });

  testWidgets('Widget displays icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Icon(Icons.add, key: Key('add_icon')),
        ),
      ),
    );

    expect(find.byKey(const Key('add_icon')), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}