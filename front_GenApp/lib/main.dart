import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/app.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: _AppWithAuth(),
    ),
  );
}

class _AppWithAuth extends ConsumerStatefulWidget {
  const _AppWithAuth();

  @override
  ConsumerState<_AppWithAuth> createState() => _AppWithAuthState();
}

class _AppWithAuthState extends ConsumerState<_AppWithAuth> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const GeneApp();
  }
}
