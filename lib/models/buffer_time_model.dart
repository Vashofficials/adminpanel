class BufferTimeModel {
  final String id;
  final int distanceFrom;
  final int distanceTo;
  final int bufferAfter;
  final int bufferBefore;
  final bool isActive;

  BufferTimeModel({
    required this.id,
    required this.distanceFrom,
    required this.distanceTo,
    required this.bufferAfter,
    required this.bufferBefore,
    required this.isActive,
  });

  factory BufferTimeModel.fromJson(Map<String, dynamic> json) {
    return BufferTimeModel(
      id: json['id'] ?? '',
      distanceFrom: json['distanceFrom'] ?? 0,
      distanceTo: json['distanceTo'] ?? 0,
      bufferAfter: json['bufferAfter'] ?? 0,
      bufferBefore: json['bufferBefore'] ?? 0,
      isActive: json['isActive'] ?? false,
    );
  }
}