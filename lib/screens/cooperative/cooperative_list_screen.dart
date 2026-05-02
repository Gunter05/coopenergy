import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/cooperative_card.dart';

class CooperativeListScreen extends StatelessWidget {
  const CooperativeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coopératives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une coopérative...',
                prefixIcon: const Icon(Icons.search_rounded),
                fillColor: AppColors.surface,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: CooperativeCard(
                    name: 'Solaire Miabe J${index + 1}',
                    objective: 'Installation de panneaux solaires pour le quartier ${index + 1}.',
                    collectedAmount: 100000.0 * (index + 1),
                    targetAmount: 500000.0,
                    memberCount: 10 + (index * 5),
                    status: index == 0 ? 'Actif' : 'En attente',
                    onTap: () => context.push('/cooperative/$index'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
