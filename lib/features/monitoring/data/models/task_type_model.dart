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
      id: json['task_type_id'] ?? '',
      name: json['task_name'] ?? '',
      unitMeasure: json['unit_measure'] ?? '',
    );
  }
}
