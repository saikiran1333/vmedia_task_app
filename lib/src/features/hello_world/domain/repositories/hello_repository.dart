import '../entities/hello_entity.dart';

abstract class HelloRepository {
  Future<HelloEntity> fetchHelloData();
}
