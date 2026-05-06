import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/supabase_client.dart';

class MemberSearchResult {
  final String userId;
  final String displayName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final bool isFromContacts; // vrai si trouvé dans le répertoire

  MemberSearchResult({
    required this.userId,
    required this.displayName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.isFromContacts = false,
  });
}

class MemberService {
  // ── Recherche manuelle par email ou téléphone ────────
  Future<MemberSearchResult?> searchByEmailOrPhone(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    final isEmail = q.contains('@');

    final data = await supabase
        .from('profiles')
        .select('id, display_name, email, phone, avatar_url')
        .neq('id', supabase.auth.currentUser!.id) // exclure soi-même
        .or(isEmail ? 'email.eq.$q' : 'phone.eq.$q,phone.eq.+$q')
        .maybeSingle();

    if (data == null) return null;

    return MemberSearchResult(
      userId: data['id'],
      displayName: data['display_name'] ?? data['email'] ?? 'Utilisateur',
      email: data['email'],
      phone: data['phone'],
      avatarUrl: data['avatar_url'],
    );
  }

  // ── Recherche depuis les contacts du téléphone ───────
  // Disponible uniquement sur Android/iOS
  Future<List<MemberSearchResult>> searchFromContacts() async {
    // Sur Web, retourner une liste vide
    if (kIsWeb) return [];

    // Demander la permission
    final status = await Permission.contacts.request();
    if (!status.isGranted) return [];

    // Lire les contacts
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
    );

    // Extraire tous les numéros de téléphone
    final phones = <String>[];
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        final cleaned = phone.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        if (cleaned.isNotEmpty) phones.add(cleaned);
      }
    }

    if (phones.isEmpty) return [];

    // Chercher lesquels ont un compte CoopEnergie
    final data = await supabase
        .from('profiles')
        .select('id, display_name, email, phone, avatar_url')
        .neq('id', supabase.auth.currentUser!.id)
        .inFilter('phone', phones);

    return (data as List)
        .map((d) => MemberSearchResult(
              userId: d['id'],
              displayName: d['display_name'] ?? d['email'] ?? 'Utilisateur',
              email: d['email'],
              phone: d['phone'],
              avatarUrl: d['avatar_url'],
              isFromContacts: true,
            ))
        .toList();
  }

  // ── Vérifier si un utilisateur est déjà membre ───────
  Future<bool> isAlreadyMember(String coopId, String userId) async {
    final data = await supabase
        .from('cooperative_members')
        .select('id')
        .eq('cooperative_id', coopId)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null;
  }
}

final memberServiceProvider = Provider<MemberService>((ref) => MemberService());
