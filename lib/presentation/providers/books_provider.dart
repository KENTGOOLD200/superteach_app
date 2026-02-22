import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/infrastructure/datasources/books_datasource.dart';

// ============================================================================
// PROVEEDORES DE RIVERPOD PARA LIBROS
// ============================================================================


// Proveedor del DataSource
final booksDatasourceProvider = Provider((ref) => BooksDataSource());

// Proveedor del Estado (AsyncValue maneja automáticamente Loading, Error y Data)
final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<dynamic>>>((ref) {
  return BooksNotifier(ref.read(booksDatasourceProvider));
});

class BooksNotifier extends StateNotifier<AsyncValue<List<dynamic>>> {
  final BooksDataSource dataSource;

  BooksNotifier(this.dataSource) : super(const AsyncValue.loading()) {
    // Al iniciar la pantalla, buscará esto por defecto
    search('tecnologia educativa'); 
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final books = await dataSource.searchBooks(query);
      state = AsyncValue.data(books);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}