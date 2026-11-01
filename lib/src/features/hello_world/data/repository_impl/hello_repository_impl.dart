import '../../domain/entities/hello_entity.dart';
import '../../domain/repositories/hello_repository.dart';
import '../datasources/hello_remote_datasource.dart';

class HelloRepositoryImpl implements HelloRepository {
  final HelloRemoteDatasource _remoteDatasource;

  HelloRepositoryImpl(this._remoteDatasource);

  @override
  Future<HelloEntity> fetchHelloData() async {
    final model = await _remoteDatasource.fetchHelloData();
    return model.toEntity();
  }
}
