import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:onetimesecret_flutter/presentation/blocs/auth/auth_bloc.dart';
import 'package:onetimesecret_flutter/presentation/blocs/auth/auth_event.dart';
import 'package:onetimesecret_flutter/presentation/blocs/auth/auth_state.dart';
import 'package:onetimesecret_flutter/presentation/pages/splash/splash_page.dart';

@GenerateMocks([AuthBloc])
import 'splash_page_test.mocks.dart';

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: const SplashPage(),
      ),
    );
  }

  testWidgets('should display app name and loading indicator',
      (WidgetTester tester) async {
    // arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    when(mockAuthBloc.stream)
        .thenAnswer((_) => Stream.fromIterable([AuthInitial()]));

    // act
    await tester.pumpWidget(createWidgetUnderTest());

    // assert
    expect(find.text('OneTimeSecret'), findsOneWidget);
    expect(find.text('Share secrets securely'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.security), findsOneWidget);
  });

  testWidgets('should trigger CheckAuthenticationEvent after delay',
      (WidgetTester tester) async {
    // arrange
    when(mockAuthBloc.state).thenReturn(AuthInitial());
    when(mockAuthBloc.stream)
        .thenAnswer((_) => Stream.fromIterable([AuthInitial()]));

    // act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 2));

    // assert
    verify(mockAuthBloc.add(any)).called(greaterThanOrEqualTo(1));
  });
}
