
import 'package:web3dart/web3dart.dart';

void main() {
  const privateKey = '0x553aC57ACd543cfb291d14E113699594d1BAb8bE';
  final credentials = EthPrivateKey.fromHex(privateKey);
  print('Adresse publique : ${credentials.address.hex}');
}
