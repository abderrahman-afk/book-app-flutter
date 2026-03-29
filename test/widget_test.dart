import 'package:flutter_test/flutter_test.dart';

import 'package:book_crud_app/main.dart';

void main() {
  testWidgets('home screen shows CRUD entry points', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BookCrudApp());

    expect(find.text('Gestion des livres'), findsOneWidget);
    expect(find.text('Ajouter un livre'), findsOneWidget);
    expect(find.text('Actualiser la liste'), findsOneWidget);
    expect(
      find.text('Actualisez la liste ou ajoutez votre premier titre.'),
      findsOneWidget,
    );
  });
}
