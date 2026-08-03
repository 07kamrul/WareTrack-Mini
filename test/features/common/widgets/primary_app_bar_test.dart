import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waretrack_mini/core/widgets/primary_app_bar.dart';

void main() {
  testWidgets('keeps long app bar titles centered without ellipsis', (
    tester,
  ) async {
    const title = 'Receiving Scanner';

    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: PrimaryAppBar(
            title: title,
            showBackButton: true,
            showSettingsButton: true,
            onBackPressed: () {},
            onSettingsPressed: () {},
          ),
        ),
      ),
    );

    final titleFinder = find.text(title);
    final titleText = tester.widget<Text>(titleFinder);
    final titleCenter = tester.getCenter(titleFinder);

    expect(titleFinder, findsOneWidget);
    expect(titleText.overflow, TextOverflow.visible);
    expect(titleCenter.dx, moreOrLessEquals(180, epsilon: 1));
    expect(find.textContaining('...'), findsNothing);
  });
}
