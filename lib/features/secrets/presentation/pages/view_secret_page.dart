import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/secret_state.dart';

class ViewSecretPage extends ConsumerStatefulWidget {
  const ViewSecretPage({super.key});

  @override
  ConsumerState<ViewSecretPage> createState() => _ViewSecretPageState();
}

class _ViewSecretPageState extends ConsumerState<ViewSecretPage> {
  final _formKey = GlobalKey<FormState>();
  final _secretKeyController = TextEditingController();
  final _passphraseController = TextEditingController();
  bool _needsPassphrase = false;

  @override
  void dispose() {
    _secretKeyController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _handleGetSecret() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(getSecretProvider.notifier).getSecret(
          secretKey: _secretKeyController.text.trim(),
          passphrase: _passphraseController.text.isEmpty
              ? null
              : _passphraseController.text,
        );
  }

  void _showSecretDialog(String secretValue) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock_open, color: Colors.green),
            const SizedBox(width: 8),
            const Text('Secret Retrieved'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This secret has been burned and can never be viewed again.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                secretValue,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: secretValue));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Secret copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final secretState = ref.watch(getSecretProvider);

    // Listen for success
    ref.listen(getSecretProvider, (previous, next) {
      next.whenData((secret) {
        if (secret != null) {
          if (secret.passphraseRequired == true && !_needsPassphrase) {
            setState(() {
              _needsPassphrase = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This secret requires a passphrase'),
              ),
            );
          } else if (secret.value != null) {
            _showSecretDialog(secret.value!);
            ref.read(getSecretProvider.notifier).reset();
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Secret'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  'Retrieve Secret',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the secret key to view the one-time secret',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Secret Key
                TextFormField(
                  controller: _secretKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Secret Key',
                    hintText: 'Enter the secret key',
                    prefixIcon: Icon(Icons.key),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a secret key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Passphrase (shown only if needed)
                if (_needsPassphrase) ...[
                  TextFormField(
                    controller: _passphraseController,
                    decoration: const InputDecoration(
                      labelText: 'Passphrase',
                      hintText: 'Enter the passphrase',
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (_needsPassphrase &&
                          (value == null || value.isEmpty)) {
                        return 'Please enter the passphrase';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                // Warning
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This secret will be permanently deleted after viewing',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // View button
                secretState.when(
                  data: (_) => ElevatedButton(
                    onPressed: _handleGetSecret,
                    child: const Text('View Secret'),
                  ),
                  loading: () => const ElevatedButton(
                    onPressed: null,
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Column(
                    children: [
                      ElevatedButton(
                        onPressed: _handleGetSecret,
                        child: const Text('View Secret'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error: ${error.toString()}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
