import 'package:drift/drift.dart';
import 'package:kiosk/db/tables/products.dart';
import 'package:kiosk/db/tables/themes.dart';

class ProductThemes extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get productId => integer().references(
        Products,
        #id,
        onDelete: KeyAction.cascade,
      )();

  IntColumn get themeId => integer().references(
        Themes,
        #id,
        onDelete: KeyAction.cascade,
      )();
}
