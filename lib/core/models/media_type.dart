enum MediaType {
  photo('photo'),
  video('video');

  const MediaType(this.value);

  final String value;

  static MediaType fromValue(String value) {
    return MediaType.values.firstWhere(
      (MediaType type) => type.value == value,
      orElse: () => MediaType.photo,
    );
  }
}
