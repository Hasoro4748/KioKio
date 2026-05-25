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

  Future<int> insert(ProductsCompanion data) {
    return db.into(db.products).insert(data);
  }

  Future updateProduct(Product product) {
    return db.update(db.products).replace(product);
  }

  Future delete(int id) {
    return (db.delete(db.products)..where((t) => t.id.equals(id))).go();
  }
}
