class Book {
  const Book({
    this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.publishedDate,
  });

  final int? id;
  final String title;
  final String author;
  final String isbn;
  final String publishedDate;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: _asInt(json['id']),
      title: (json['title'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      isbn: (json['isbn'] ?? '').toString(),
      publishedDate: (json['publishedDate'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return <String, dynamic>{
      if (includeId && id != null) 'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'publishedDate': publishedDate,
    };
  }

  static int? _asInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
