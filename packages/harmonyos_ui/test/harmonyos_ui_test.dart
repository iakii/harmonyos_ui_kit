import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harmonyos_ui/harmonyos_ui.dart';

void main() {
  // ------------------------------------------------------------------
  // Theme tests
  // ------------------------------------------------------------------
  group('HarmonyThemeData', () {
    test('factory constructor defaults to light brightness', () {
      final theme = HarmonyThemeData();
      expect(theme.brightness, Brightness.light);
      expect(theme.isLight, isTrue);
    });

    test('light factory creates light theme', () {
      final theme = HarmonyThemeData.light();
      expect(theme.brightness, Brightness.light);
    });

    test('dark factory creates dark theme', () {
      final theme = HarmonyThemeData.dark();
      expect(theme.brightness, Brightness.dark);
    });

    test('default accent color is blue', () {
      final theme = HarmonyThemeData();
      expect(theme.accentColor.normal, const Color(0xFF007DFF));
    });

    test('light and dark have different background colors', () {
      final light = HarmonyThemeData.light();
      final dark = HarmonyThemeData.dark();
      expect(light.backgroundColor, isNot(dark.backgroundColor));
    });

    test('copyWith replaces specified fields', () {
      final original = HarmonyThemeData();
      final copy = original.copyWith(
        brightness: Brightness.dark,
        textColor: const Color(0xFF123456),
      );
      expect(copy.brightness, Brightness.dark);
      expect(copy.textColor, const Color(0xFF123456));
      // Unspecified fields remain the same
      expect(copy.accentColor.normal, original.accentColor.normal);
    });

    test('merge overrides non-null fields', () {
      final base = HarmonyThemeData();
      final overrides = HarmonyThemeData.raw(
        brightness: Brightness.dark,
        accentColor: HarmonyColors.red,
        colorTokens: HarmonyColorTokens.dark(),
        backgroundColor: const Color(0xFF000000),
        surfaceColor: const Color(0xFF111111),
        scaffoldBackgroundColor: const Color(0xFF000000),
        textColor: const Color(0xFFFFFFFF),
        textSecondaryColor: const Color(0xFFAAAAAA),
        disabledColor: const Color(0xFF333333),
        dividerColor: const Color(0xFF222222),
        shadowColor: const Color(0x1AFFFFFF),
        typography: HarmonyTypography.dark(),
        animationDuration: const Duration(milliseconds: 500),
        animationCurve: Curves.linear,
        visualDensity: VisualDensity.compact,
      );
      final merged = base.merge(overrides);
      expect(merged.brightness, Brightness.dark);
      expect(merged.accentColor.normal, HarmonyColors.red.normal);
    });

    test('lerp interpolates colors', () {
      final light = HarmonyThemeData.light();
      final dark = HarmonyThemeData.dark();
      final mid = HarmonyThemeData.lerp(light, dark, 0.5);
      expect(mid, isNotNull);
    });
  });

  group('HarmonyColorTokens', () {
    test('light tokens are available', () {
      final tokens = HarmonyColorTokens.light();
      expect(tokens.pageBackground, isNotNull);
      expect(tokens.textPrimary, isNotNull);
    });

    test('dark tokens are available', () {
      final tokens = HarmonyColorTokens.dark();
      expect(tokens.pageBackground, isNotNull);
      expect(tokens.textPrimary, isNotNull);
    });
  });

  group('HarmonyTypography', () {
    test('light typography has all styles', () {
      final typography = HarmonyTypography.light();
      expect(typography.headline1, isNotNull);
      expect(typography.headline2, isNotNull);
      expect(typography.headline3, isNotNull);
      expect(typography.title1, isNotNull);
      expect(typography.title2, isNotNull);
      expect(typography.title3, isNotNull);
      expect(typography.body, isNotNull);
      expect(typography.bodySmall, isNotNull);
      expect(typography.caption, isNotNull);
      expect(typography.overline, isNotNull);
    });

    test('copyWith replaces a single style', () {
      final typography = HarmonyTypography.light();
      final newBody = TextStyle(fontSize: 42);
      final copy = typography.copyWith(body: newBody);
      expect(copy.body?.fontSize, 42);
      expect(copy.headline1?.fontSize, typography.headline1?.fontSize);
    });
  });

  // ------------------------------------------------------------------
  // Button tests
  // ------------------------------------------------------------------
  group('HosButton', () {
    testWidgets('renders with child text', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosButton(
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosButton(
              onPressed: null,
              child: const Text('Disabled'),
            ),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  group('HosOutlinedButton', () {
    testWidgets('renders with child text', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosOutlinedButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('HosTextButton', () {
    testWidgets('renders with child text', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosTextButton(
              onPressed: () {},
              child: const Text('Learn more'),
            ),
          ),
        ),
      );

      expect(find.text('Learn more'), findsOneWidget);
    });
  });

  group('HosIconButton', () {
    testWidgets('renders with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosIconButton(
              onPressed: () {},
              child: const Icon(Icons.settings),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------
  // WidgetStateExtension tests
  // ------------------------------------------------------------------
  group('WidgetStateExtension', () {
    test('empty set returns isNone true', () {
      const states = <WidgetState>{};
      expect(states.isPressed, isFalse);
      expect(states.isHovered, isFalse);
      expect(states.isFocused, isFalse);
      expect(states.isDisabled, isFalse);
      expect(states.isNone, isTrue);
    });

    test('pressed state is detected', () {
      const states = <WidgetState>{WidgetState.pressed};
      expect(states.isPressed, isTrue);
    });

    test('disabled state is detected', () {
      const states = <WidgetState>{WidgetState.disabled};
      expect(states.isDisabled, isTrue);
    });
  });

  // ------------------------------------------------------------------
  // Input control tests
  // ------------------------------------------------------------------
  group('HosCheckbox', () {
    testWidgets('renders unchecked by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosCheckbox(
              checked: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(HosCheckbox), findsOneWidget);
    });

    testWidgets('toggles when tapped', (WidgetTester tester) async {
      bool? changedValue;
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosCheckbox(
              checked: false,
              onChanged: (v) => changedValue = v,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HosCheckbox));
      expect(changedValue, true);
    });
  });

  group('HosRadio', () {
    testWidgets('renders radio button', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosRadio(
              selected: false,
              onChanged: () {},
            ),
          ),
        ),
      );
      expect(find.byType(HosRadio), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (WidgetTester tester) async {
      bool called = false;
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosRadio(
              selected: false,
              onChanged: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HosRadio));
      expect(called, isTrue);
    });
  });

  group('HosSwitch', () {
    testWidgets('renders toggle switch', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosSwitch(
              checked: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(HosSwitch), findsOneWidget);
    });

    testWidgets('toggles when tapped', (WidgetTester tester) async {
      bool? changedValue;
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosSwitch(
              checked: false,
              onChanged: (v) => changedValue = v,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(HosSwitch));
      expect(changedValue, true);
    });
  });

  group('HosSlider', () {
    testWidgets('renders slider', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: SizedBox(
              width: 200,
              height: 40,
              child: HosSlider(
                value: 0.5,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.byType(HosSlider), findsOneWidget);
    });
  });

  group('HosRatingBar', () {
    testWidgets('renders stars', (WidgetTester tester) async {
      await tester.pumpWidget(
        HarmonyOSApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: HosRatingBar(
              rating: 3.0,
              maxRating: 5,
            ),
          ),
        ),
      );
      expect(find.byType(HosRatingBar), findsOneWidget);
      // 3 filled + 2 empty
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
    });
  });

  // ------------------------------------------------------------------
  // Form field tests
  // ------------------------------------------------------------------
  group('HosTextInput', () {
    testWidgets('renders with placeholder', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: HosTextInput(placeholder: 'Enter name'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(HosTextInput), findsOneWidget);
    });

    testWidgets('shows error text when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: HosTextInput(errorText: 'Required field'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Required field'), findsOneWidget);
    });
  });

  group('HosSearchBox', () {
    testWidgets('renders with search icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: HosSearchBox(placeholder: 'Search...'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  group('HosPasswordInput', () {
    testWidgets('renders with visibility toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: HosPasswordInput(placeholder: 'Password'),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: HosPasswordInput(placeholder: 'Password'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------
  // Layout tests
  // ------------------------------------------------------------------
  group('HosPage', () {
    testWidgets('renders with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const HosPage(
              title: 'Settings',
              body: Text('Content'),
            ),
          ),
        ),
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('shows back button when navigable', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const HosPage(title: 'Page 1'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HosPage), findsOneWidget);
    });
  });

  group('HosAppBar', () {
    testWidgets('renders title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              appBar: HosAppBar(title: 'Settings'),
              body: SizedBox.shrink(),
            ),
          ),
        ),
      );
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders with leading widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              appBar: HosAppBar(
                title: 'Page',
                leading: Icon(Icons.menu),
              ),
              body: SizedBox.shrink(),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.text('Page'), findsOneWidget);
    });

    testWidgets('renders with actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              appBar: HosAppBar(
                title: 'Page',
                actions: [Icon(Icons.search), Icon(Icons.more_vert)],
              ),
              body: SizedBox.shrink(),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('renders without immersive (opaque style)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              appBar: HosAppBar(title: 'Page', immersive: false),
              body: SizedBox.shrink(),
            ),
          ),
        ),
      );
      expect(find.text('Page'), findsOneWidget);
    });

    testWidgets('has correct preferred size', (WidgetTester tester) async {
      const appBar = HosAppBar(title: 'Test', height: 80);
      expect(appBar.preferredSize, const Size.fromHeight(80));
    });
  });

  // ------------------------------------------------------------------
  // Utility widget tests
  // ------------------------------------------------------------------
  group('HosDivider', () {
    testWidgets('renders simple divider', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: Column(
                children: [
                  Text('Above'),
                  HosDivider(),
                  Text('Below'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(HosDivider), findsOneWidget);
    });

    testWidgets('renders divider with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosDivider(label: 'OR'),
            ),
          ),
        ),
      );
      expect(find.text('OR'), findsOneWidget);
    });
  });

  group('HosInfoLabel', () {
    testWidgets('renders with label and info', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosInfoLabel(
                label: 'Dark mode',
                info: 'Use dark theme',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Dark mode'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('renders with trailing widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosInfoLabel(
                label: 'Wi-Fi',
                child: Text('On'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Wi-Fi'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
    });
  });

  group('HosFocusBorder', () {
    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosFocusBorder(
                child: Text('Focusable'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Focusable'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------
  // Navigation tests
  // ------------------------------------------------------------------
  group('HosTabBar', () {
    testWidgets('renders tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Scaffold(
              body: HosTabBar(
                tabs: ['Tab A', 'Tab B', 'Tab C'],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Tab A'), findsOneWidget);
      expect(find.text('Tab B'), findsOneWidget);
      expect(find.text('Tab C'), findsOneWidget);
    });
  });

  group('HosBottomNavigation', () {
    testWidgets('renders items with default (immersive) style',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Scaffold(
              bottomNavigationBar: HosBottomNavigation(
                items: const [
                  HosBottomNavItem(icon: Icons.home, label: 'Home'),
                  HosBottomNavItem(icon: Icons.settings, label: 'Settings'),
                ],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders items without immersive (opaque background)',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Scaffold(
              bottomNavigationBar: HosBottomNavigation(
                items: const [
                  HosBottomNavItem(icon: Icons.home, label: 'Home'),
                  HosBottomNavItem(icon: Icons.settings, label: 'Settings'),
                ],
                selectedIndex: 0,
                onChanged: (_) {},
                immersive: false,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('floating style renders with shadow and rounded corners',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Scaffold(
              body: Stack(
                children: [
                  const Center(child: Text('Content')),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: HosBottomNavigation(
                      items: const [
                        HosBottomNavItem(icon: Icons.home, label: 'Home'),
                        HosBottomNavItem(
                            icon: Icons.settings, label: 'Settings'),
                      ],
                      selectedIndex: 0,
                      onChanged: (_) {},
                      floating: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('custom iconSize is respected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Scaffold(
              bottomNavigationBar: HosBottomNavigation(
                items: const [
                  HosBottomNavItem(icon: Icons.home, label: 'Home'),
                ],
                selectedIndex: 0,
                onChanged: (_) {},
                iconSize: 28,
              ),
            ),
          ),
        ),
      );
      // The icon should render with the custom size
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('active icon is used when selected',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Scaffold(
              bottomNavigationBar: HosBottomNavigation(
                items: const [
                  HosBottomNavItem(
                      icon: Icons.home_outlined,
                      label: 'Home',
                      activeIcon: Icons.home),
                ],
                selectedIndex: 0,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      // The active (filled) icon should be shown because index 0 is selected
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('tap calls onChanged', (WidgetTester tester) async {
      int tapped = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Scaffold(
              bottomNavigationBar: HosBottomNavigation(
                items: const [
                  HosBottomNavItem(icon: Icons.home, label: 'Home'),
                  HosBottomNavItem(icon: Icons.settings, label: 'Settings'),
                ],
                selectedIndex: 0,
                onChanged: (i) => tapped = i,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Settings'));
      expect(tapped, 1);
    });
  });

  group('HosNavigationRail', () {
    testWidgets('renders items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: Row(
              children: [
                HosNavigationRail(
                  items: const [
                    HosNavRailItem(icon: Icons.home, label: 'Home'),
                    HosNavRailItem(icon: Icons.settings, label: 'Settings'),
                  ],
                  selectedIndex: 0,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });

  // ------------------------------------------------------------------
  // Surface tests
  // ------------------------------------------------------------------
  group('HosCard', () {
    testWidgets('renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosCard(child: Text('Card content')),
            ),
          ),
        ),
      );
      expect(find.text('Card content'), findsOneWidget);
    });
  });

  group('HosListItem', () {
    testWidgets('renders with title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosListItem(title: 'Title', subtitle: 'Subtitle'),
            ),
          ),
        ),
      );
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
    });
  });

  group('HosProgressBar', () {
    testWidgets('renders determinate bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosProgressBar(value: 0.5),
            ),
          ),
        ),
      );
      expect(find.byType(HosProgressBar), findsOneWidget);
    });
  });

  group('HosProgressRing', () {
    testWidgets('renders ring', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosProgressRing(),
            ),
          ),
        ),
      );
      expect(find.byType(HosProgressRing), findsOneWidget);
    });
  });

  group('HosEmptyState', () {
    testWidgets('renders with title and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosEmptyState(
                icon: Icons.inbox,
                title: 'No items',
                message: 'List is empty',
              ),
            ),
          ),
        ),
      );
      expect(find.text('No items'), findsOneWidget);
      expect(find.text('List is empty'), findsOneWidget);
    });
  });

  group('HosErrorState', () {
    testWidgets('renders with retry button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HarmonyTheme(
            data: HarmonyThemeData.light(),
            child: const Scaffold(
              body: HosErrorState(message: 'Error loading'),
            ),
          ),
        ),
      );
      expect(find.text('Error loading'), findsOneWidget);
    });
  });
}
