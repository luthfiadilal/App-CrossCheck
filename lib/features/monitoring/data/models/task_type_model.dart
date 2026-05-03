class TaskTypeModel {
  final String id;
  final String name;
  final String unitMeasure;

  TaskTypeModel({
    required this.id,
    required this.name,
    required this.unitMeasure,
  });

  factory TaskTypeModel.fromJson(Map<String, dynamic> json) {
    return TaskTypeModel(
      id: json['task_type_id'] ?? json['id'] ?? '',
      name: json['task_name'] ?? json['name'] ?? '',
      unitMeasure: json['unit_measure'] ?? json['unit_measure'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit_measure': unitMeasure,
    };
  }
}
