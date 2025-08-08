class ContractDTO {
  final int? id;
  final String? name;
  final String? content;
  final bool? active;
  final String? title;
  final String? version;
  final String? type;
  final bool? mandatory;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdByUsername;

  ContractDTO({
    this.id,
    this.name,
    this.content,
    this.active,
    this.title,
    this.version,
    this.type,
    this.mandatory,
    this.createdAt,
    this.updatedAt,
    this.createdByUsername,
  });

  factory ContractDTO.fromJson(Map<String, dynamic> json) {
    return ContractDTO(
      id: json['id'],
      name: json['name'],
      title: json['title'],
      content: json['content'],
      active: json['active'],
      version: json['version'],
      type: json['type'],
      mandatory: json['mandatory'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : null,
      createdByUsername: json['createdByUsername'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'title': title,
      'content': content,
      'active': active,
      'version': version,
      'type': type,
      'mandatory': mandatory,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdByUsername': createdByUsername,
    };
  }
}
