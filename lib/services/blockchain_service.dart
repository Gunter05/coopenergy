import 'dart:convert';
import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

class BlockchainService {
  Web3Client? _client;
  DeployedContract? _contract;
  EthPrivateKey? _credentials;
  bool _initialized = false;

  // ── Initialisation ────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    final rpcUrl = dotenv.env['POLYGON_RPC_URL']!;
    final contractAddress = dotenv.env['CONTRACT_ADDRESS']!;
    final privateKey = dotenv.env['WALLET_PRIVATE_KEY']!;

    _client = Web3Client(rpcUrl, http.Client());
    _credentials = EthPrivateKey.fromHex(privateKey);

    // Charger l'ABI depuis les assets
    final abiJson = await rootBundle.loadString('assets/abi/coopenergy.json');
    final abi = ContractAbi.fromJson(abiJson, 'CoopEnergie');

    _contract = DeployedContract(
      abi,
      EthereumAddress.fromHex(contractAddress),
    );

    _initialized = true;
  }

  // ── Helpers ───────────────────────────────────────────

  // Convertit un UUID Supabase en bytes32 pour Solidity
  Uint8List _uuidToBytes32(String uuid) {
    final cleaned = uuid.replaceAll('-', '');
    final bytes = hex.decode(cleaned);
    final result = Uint8List(32);
    result.setRange(0, bytes.length, bytes);
    return result;
  }

  // ── Transactions ──────────────────────────────────────

  Future<String> createCooperative({
    required String coopId,
    required double goalAmount,
  }) async {
    await init();

    final fn = _contract!.function('createCooperative');
    final tx = await _client!.sendTransaction(
      _credentials!,
      Transaction.callContract(
        contract: _contract!,
        function: fn,
        parameters: [
          _uuidToBytes32(coopId),
          BigInt.from(goalAmount.toInt()),
        ],
      ),
      chainId: 80002, // Polygon Amoy
      fetchChainIdFromNetworkId: false,
    );

    await _waitForConfirmation(tx);
    return tx;
  }

  Future<String> recordContribution({
    required String coopId,
    required double amount,
  }) async {
    await init();

    final fn = _contract!.function('recordContribution');
    final tx = await _client!.sendTransaction(
      _credentials!,
      Transaction.callContract(
        contract: _contract!,
        function: fn,
        parameters: [
          _uuidToBytes32(coopId),
          BigInt.from(amount.toInt()),
        ],
      ),
      chainId: 80002,
      fetchChainIdFromNetworkId: false,
    );

    await _waitForConfirmation(tx);
    return tx;
  }

  Future<String> castVote({
    required String proposalId,
    required int choice, // 0=yes 1=no 2=abstain
  }) async {
    await init();

    final fn = _contract!.function('castVote');
    final tx = await _client!.sendTransaction(
      _credentials!,
      Transaction.callContract(
        contract: _contract!,
        function: fn,
        parameters: [
          _uuidToBytes32(proposalId),
          BigInt.from(choice),
        ],
      ),
      chainId: 80002,
      fetchChainIdFromNetworkId: false,
    );

    await _waitForConfirmation(tx);
    return tx;
  }

  // ── Diagnostics ──────────────────────────────────────

  Future<String> getPublicAddress() async {
    await init();
    return _credentials!.address.hex;
  }

  Future<double> getBalance() async {
    await init();
    final balance = await _client!.getBalance(_credentials!.address);
    return balance.getValueInUnit(EtherUnit.ether);
  }

  // ── Attendre confirmation ─────────────────────────────
  Future<void> _waitForConfirmation(String txHash) async {
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final receipt = await _client!.getTransactionReceipt(txHash);
      if (receipt != null) return;
    }
    // Timeout après 60s — on continue quand même
  }

  // ── URL explorateur ───────────────────────────────────
  String explorerUrl(String txHash) =>
      'https://amoy.polygonscan.com/tx/$txHash';

  // ── Nettoyage ─────────────────────────────────────────
  void dispose() {
    _client?.dispose();
  }
}

final blockchainServiceProvider = Provider<BlockchainService>((ref) {
  final service = BlockchainService();
  ref.onDispose(service.dispose);
  return service;
});
