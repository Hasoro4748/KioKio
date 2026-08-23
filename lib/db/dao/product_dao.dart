import 'package:drift/drift.dart';
import 'package:kiosk/db/app_database.dart';

class ProductDao {
  final AppDatabase db;

  ProductDao(this.db);

  Future<List<Product>> getAll() {
    return db.select(db.products).get();
  }

  Future<Product?> getById(int id) {
    return (db.select(db.products)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insert(ProductsCompanion companion) {
    return db.into(db.products).insert(companion);
  }

  Future<int> insertOrUpdate(ProductsCompanion companion) {
    // 동일한 ID가 있으면 덮어씌웁니다.
    return db.into(db.products).insertOnConflictUpdate(companion);
  }

  Future updateProduct(ProductsCompanion companion) {
    return db.update(db.products).replace(companion);
  }

  Future updateProductStock(int id, int stock) {
    return (db.update(db.products)..where((p) => p.id.equals(id)))
        .write(ProductsCompanion(stock: Value(stock)));
  }

  Future delete(int id) {
    return (db.delete(db.products)..where((t) => t.id.equals(id))).go();
  }
}
