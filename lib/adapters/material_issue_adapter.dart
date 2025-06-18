import 'package:hive/hive.dart';
import '../models/material_issue.dart';

class MaterialIssueAdapter extends TypeAdapter<MaterialIssue> {
  @override
  final int typeId = 30;

  @override
  MaterialIssue read(BinaryReader reader) {
    return MaterialIssue(
      issueNo: reader.read(),
      date: reader.read(),
      issuedBy: reader.read(),
      status: reader.read(),
      items: reader.read(),
      jobNo: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialIssue obj) {
    writer.write(obj.issueNo);
    writer.write(obj.date);
    writer.write(obj.issuedBy);
    writer.write(obj.status);
    writer.write(obj.items);
    writer.write(obj.jobNo);
  }
} 