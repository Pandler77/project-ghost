import '../models/protocol.dart';
import 'protocol_service.dart';

class AppDataService {
  final ProtocolService _protocolService = ProtocolService();

  String get displayName => 'Frank';

  double get startingWeight => 405.2;

  double get currentWeight => 361.4;

  List<Protocol> getInitialProtocols() {
    return _protocolService.getAllProtocols();
  }
}