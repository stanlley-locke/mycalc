// lib/calculation.dart
import 'package:hive_flutter/hive_flutter.dart';

part 'calculation.g.dart';

@HiveType(typeId: 0)
class Calculation extends HiveObject {
  @HiveField(0)
  final String expression;

  @HiveField(1)
  final double result;

  Calculation(this.expression, this.result);
}