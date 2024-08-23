class SearchResult {
  final String name;
  final String url;
  final String imgUrl;

  // Constructor with required named parameters to initialize the class.
  SearchResult({
    required this.name,
    required this.url,
    required this.imgUrl,
  });

  // Named constructor for creating a SearchResult from a map (like from JSON).
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      name: json['name'],
      url: json['url'],
      imgUrl: json['imgUrl'],
    );
  }

  // Method to convert the SearchResult instance into a map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
      'imgUrl': imgUrl,
    };
  }

  @override
  String toString() {
    return 'SearchResult(name: $name, url: $url, imgUrl: $imgUrl)';
  }

  // Implementing hashCode and operator == for better equality checks
  @override
  int get hashCode => Object.hash(name, url, imgUrl);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchResult &&
        other.name == name &&
        other.url == url &&
        other.imgUrl == imgUrl;
  }
}
