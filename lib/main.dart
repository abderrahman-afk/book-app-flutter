import 'package:flutter/material.dart';

import 'models/book.dart';
import 'services/book_api_service.dart';

void main() {
  runApp(const BookCrudApp());
}

class BookCrudApp extends StatelessWidget {
  const BookCrudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion des livres',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        scaffoldBackgroundColor: const Color(0xFFF7F4EE),
      ),
      home: const BookHomePage(),
    );
  }
}

class BookHomePage extends StatefulWidget {
  const BookHomePage({super.key});

  @override
  State<BookHomePage> createState() => _BookHomePageState();
}

class _BookHomePageState extends State<BookHomePage> {
  final BookApiService _apiService = BookApiService();
  List<Book> _books = const [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks({String? successMessage}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = await _apiService.fetchBooks();
      if (!mounted) {
        return;
      }

      setState(() {
        _books = books;
      });

      if (successMessage != null) {
        _showSnackBar(successMessage);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreateBookPage() async {
    final result = await Navigator.of(context).push<BookFormResult>(
      MaterialPageRoute(builder: (_) => BookFormPage(apiService: _apiService)),
    );

    if (result == BookFormResult.created && mounted) {
      await _fetchBooks(successMessage: 'Livre ajoute avec succes.');
    }
  }

  Future<void> _openBookForEdition(Book book) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final freshBook = await _apiService.fetchBook(book.id!);
      if (!mounted) {
        return;
      }

      final action = await Navigator.of(context).push<BookFormResult>(
        MaterialPageRoute(
          builder: (_) =>
              BookFormPage(apiService: _apiService, initialBook: freshBook),
        ),
      );

      if (!mounted || action == null) {
        return;
      }

      final message = switch (action) {
        BookFormResult.created => 'Livre ajoute avec succes.',
        BookFormResult.updated => 'Livre modifie avec succes.',
        BookFormResult.deleted => 'Livre supprime avec succes.',
      };

      await _fetchBooks(successMessage: message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des livres'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _openCreateBookPage,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Ajouter un livre'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _fetchBooks,
                    icon: const Icon(Icons.download_outlined),
                    label: const Text('Actualiser la liste'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              _ErrorCard(message: _errorMessage!),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: Stack(
                children: [
                  if (_books.isEmpty)
                    const _EmptyState()
                  else
                    ListView.separated(
                      itemCount: _books.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final book = _books[index];
                        return Card(
                          child: InkWell(
                            onDoubleTap: book.id == null
                                ? null
                                : () => _openBookForEdition(book),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(book.id?.toString() ?? '?'),
                              ),
                              title: Text(book.title),
                              subtitle: Text(
                                'Auteur : ${book.author}\n'
                                'ISBN : ${book.isbn}\n'
                                'Publication : ${book.publishedDate}',
                              ),
                              trailing: const Icon(Icons.edit_note_outlined),
                              isThreeLine: true,
                            ),
                          ),
                        );
                      },
                    ),
                  if (_isLoading)
                    const ColoredBox(
                      color: Color(0x99FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFEBEE),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 60),
          SizedBox(height: 12),
          Text(
            'Aucun livre pour le moment.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text('Actualisez la liste ou ajoutez votre premier titre.'),
        ],
      ),
    );
  }
}

enum BookFormResult { created, updated, deleted }

class BookFormPage extends StatefulWidget {
  const BookFormPage({super.key, required this.apiService, this.initialBook});

  final BookApiService apiService;
  final Book? initialBook;

  bool get isEditMode => initialBook != null;

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _isbnController;
  late final TextEditingController _publishedDateController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialBook?.title ?? '',
    );
    _authorController = TextEditingController(
      text: widget.initialBook?.author ?? '',
    );
    _isbnController = TextEditingController(
      text: widget.initialBook?.isbn ?? '',
    );
    _publishedDateController = TextEditingController(
      text: widget.initialBook?.publishedDate ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _publishedDateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initialDate =
        DateTime.tryParse(_publishedDateController.text) ?? DateTime(2024);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    _publishedDateController.text = selectedDate
        .toIso8601String()
        .split('T')
        .first;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final book = Book(
        id: widget.initialBook?.id,
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        isbn: _isbnController.text.trim(),
        publishedDate: _publishedDateController.text.trim(),
      );

      if (widget.isEditMode) {
        await widget.apiService.updateBook(book);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(BookFormResult.updated);
      } else {
        await widget.apiService.createBook(book);
        if (!mounted) {
          return;
        }
        Navigator.of(context).pop(BookFormResult.created);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final bookId = widget.initialBook?.id;
    if (bookId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Voulez-vous vraiment supprimer ce livre ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.apiService.deleteBook(bookId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(BookFormResult.deleted);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.isEditMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Modifier un livre' : 'Ajouter un livre'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: AbsorbPointer(
        absorbing: _isSubmitting,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isEditMode) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Identifiant : ${widget.initialBook!.id}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le titre est obligatoire.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Auteur',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L auteur est obligatoire.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _isbnController,
                      decoration: const InputDecoration(
                        labelText: 'ISBN',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L ISBN est obligatoire.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _publishedDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date de publication',
                        hintText: 'YYYY-MM-DD',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La date de publication est obligatoire.';
                        }
                        final parsed = DateTime.tryParse(value.trim());
                        if (parsed == null || value.trim().length != 10) {
                          return 'Utilisez le format YYYY-MM-DD.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        isEditMode ? 'Enregistrer les changements' : 'Enregistrer le livre',
                      ),
                    ),
                    if (isEditMode) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Supprimer ce livre'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_isSubmitting)
              const ColoredBox(
                color: Color(0xAAFFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
