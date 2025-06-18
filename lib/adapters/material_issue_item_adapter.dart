import 'package:hive/hive.dart';
import '../models/material_issue.dart';

class MaterialIssueItemAdapter extends TypeAdapter<MaterialIssueItem> {
  @override
  final int typeId = 31;

  @override
  MaterialIssueItem read(BinaryReader reader) {
    return MaterialIssueItem(
      materialCode: reader.read(),
      materialDescription: reader.read(),
      unit: reader.read(),
      quantity: reader.read(),
      issueNo: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialIssueItem obj) {
    writer.write(obj.materialCode);
    writer.write(obj.materialDescription);
    writer.write(obj.unit);
    writer.write(obj.quantity);
    writer.write(obj.issueNo);
  }
} 