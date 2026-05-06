import 'package:flutter/material.dart';

class CooperativeDetailScreen extends StatelessWidget {
  final String coopId;
  const CooperativeDetailScreen({super.key, required this.coopId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détail coopérative')),
      body: Center(child: Text('Coopérative : $coopId')),
    );
  }
}
