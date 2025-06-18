import 'package:hive/hive.dart';
import '../models/material_request.dart';

class MaterialRequestAdapter extends TypeAdapter<MaterialRequest> {
  @override
  final int typeId = 30;

  @override
  MaterialRequest read(BinaryReader reader) {
    return MaterialRequest(
      issueNo: reader.read(),
      date: reader.read(),
      issuedBy: reader.read(),
      status: reader.read(),
      items: reader.read(),
      jobNo: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, MaterialRequest obj) {
    writer.write(obj.issueNo);
    writer.write(obj.date);
    writer.write(obj.issuedBy);
    writer.write(obj.status);
    writer.write(obj.items);
    writer.write(obj.jobNo);
  }
} 