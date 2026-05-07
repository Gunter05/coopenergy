import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
import '../models/contribution.dart';

class ContributionService {
  Future<List<Contribution>> fetchForCoop(String coopId) async {
    final data = await supabase
        .from('contributions')
        .select('*, profiles(display_name)')
        .eq('cooperative_id', coopId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => Contribution.fromJson(e)).toList();
  }

  Stream<List<Contribution>> watchForCoop(String coopId) {
    return supabase
        .from('contributions')
        .stream(primaryKey: ['id'])
        .eq('cooperative_id', coopId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => Contribution.fromJson(e)).toList());
  }
}

final contributionServiceProvider =
    Provider<ContributionService>((ref) => ContributionService());

final contributionsProvider =
    StreamProvider.family<List<Contribution>, String>((ref, coopId) {
  return ref.watch(contributionServiceProvider).watchForCoop(coopId);
});
