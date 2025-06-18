import 'package:hive/hive.dart';
import '../models/material_request.dart';

class MaterialRequestItemAdapter extends TypeAdapter<MaterialRequestItem> {
  @override
  final int typeId = 31;

  @override
  MaterialRequestItem read(BinaryReader reader) {
    return MaterialRequestItem(
      materialCode: reader.read(),
      materialDescription: reader.read(),
      unit: reader.read(),
      quantity: reader.read(),
      issueNo: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialRequestItem obj) {
    writer.write(obj.materialCode);
    writer.write(obj.materialDescription);
    writer.write(obj.unit);
    writer.write(obj.quantity);
    writer.write(obj.issueNo);
  }
} 