import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superteach_app/config/theme/app_theme.dart';
import 'package:superteach_app/presentation/providers/books_provider.dart';

// ============================================================================
// PANTALLA: RECURSOS (BÚSQUEDA DE LIBROS Y MANUALES)
// ============================================================================
// PROPÓSITO:
// Esta pantalla permite a los usuarios buscar libros y manuales educativos.
// Utiliza Riverpod para manejar el estado de la búsqueda y mostrar resultados.
// ============================================================================
class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el estado de los libros (Riverpod)
    final booksState = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Fondo oscuro
      appBar: AppBar(
        title: const Text('Recursos Educativos', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar libros o manuales...',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                prefixIcon: const Icon(Icons.search, color: neonCyan),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: neonCyan),
                ),
              ),
              onSubmitted: (value) {
                // Al dar 'Enter' en el teclado, hace la búsqueda
                if (value.isNotEmpty) {
                  ref.read(booksProvider.notifier).search(value);
                }
              },
            ),
          ),
        ),
      ),
      
      // Aquí Riverpod decide qué pintar: Loader, Error o la Lista
      body: booksState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: neonCyan)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(error.toString(), style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
          ),
        ),
        data: (books) {
          if (books.isEmpty) {
            return const Center(child: Text("No se encontraron recursos", style: TextStyle(color: Colors.white54)));
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return Card(
                color: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Colors.white10)),
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book['thumbnail'],
                      width: 60,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(width: 60, height: 90, color: Colors.grey[800], child: const Icon(Icons.book, color: Colors.white54)),
                    ),
                  ),
                  title: Text(book['title'], style: const TextStyle(color: neonCyan, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text('Autor: ${book['authors']}', style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Text('Año: ${book['publishedDate']}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}