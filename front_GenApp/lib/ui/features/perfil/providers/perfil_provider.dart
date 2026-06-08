import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';

final perfilProvider = FutureProvider((ref) {
  return ref.read(authRepositoryProvider).getPerfil();
});
