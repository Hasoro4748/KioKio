import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';

class FilterDao {
  final AppDatabase db;

  FilterDao(this.db);

  Future<List<Product>> getByTheme(int themeId) {
    return (db.select(db.products).join([
      innerJoin(
        db.productThemes,
        db.productThemes.productId.equalsExp(db.products.id),
      ),
    ])
          ..where(db.productThemes.themeId.equals(themeId)))
        .map((row) => row.readTable(db.products))
        .get();
  }
}
