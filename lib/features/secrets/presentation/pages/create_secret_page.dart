import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/secret_state.dart';

class CreateSecretPage extends ConsumerStatefulWidget {
  const CreateSecretPage({super.key});

  @override
  ConsumerState<CreateSecretPage> createState() => _CreateSecretPageState();
}

class _CreateSecretPageState extends ConsumerState<CreateSecretPage> {
  final _formKey = GlobalKey<FormState>();
  final _secretController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _recipientController = TextEditingController();
  int _selectedTtl = 604800; // 7 days in seconds

  final Map<String, int> _ttlOptions = {
    '5 minutes': 300,
    '1 hour': 3600,
    '1 day': 86400,
    '7 days': 604800,
    '14 days': 1209600,
  };

  @override
  void dispose() {
    _secretController.dispose();
    _passphraseController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateSecret() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(createSecretProvider.notifier).createSecret(
          secret: _secretController.text,
          passphrase: _passphraseController.text.isEmpty
              ? null
              : _passphraseController.text,
          ttl: _selectedTtl,
          recipient: _recipientController.text.isEmpty
              ? null
              : _recipientController.text,
        );
  }

  void _showSuccessDialog(String secretKey, String metadataKey) {
    final secretUrl = 'https://onetimesecret.com/secret/$secretKey';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Secret Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your secret has been created. Share this link:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                secretUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This link will only work once!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: secretUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copied to clipboard')),
              );
            },
            child: const Text('Copy Link'),
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
    final secretState = ref.watch(createSecretProvider);

    // Listen for success
    ref.listen(createSecretProvider, (previous, next) {
      next.whenData((secret) {
        if (secret != null) {
          _showSuccessDialog(
            secret.secretKey ?? '',
            secret.metadataKey ?? '',
          );
          ref.read(createSecretProvider.notifier).reset();
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Secret'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Secret content
                TextFormField(
                  controller: _secretController,
                  decoration: const InputDecoration(
                    labelText: 'Secret',
                    hintText: 'Enter the secret message',
                    helperText: 'This will only be viewable once',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a secret';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Passphrase (optional)
                TextFormField(
                  controller: _passphraseController,
                  decoration: const InputDecoration(
                    labelText: 'Passphrase (Optional)',
                    hintText: 'Add extra protection',
                    helperText: 'Recipient will need this to view the secret',
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // Recipient email (optional)
                TextFormField(
                  controller: _recipientController,
                  decoration: const InputDecoration(
                    labelText: 'Recipient Email (Optional)',
                    hintText: 'recipient@example.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // TTL Selection
                DropdownButtonFormField<int>(
                  value: _selectedTtl,
                  decoration: const InputDecoration(
                    labelText: 'Expires In',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  items: _ttlOptions.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.value,
                      child: Text(entry.key),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedTtl = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Create button
                secretState.when(
                  data: (_) => ElevatedButton(
                    onPressed: _handleCreateSecret,
                    child: const Text('Create Secret'),
                  ),
                  loading: () => const ElevatedButton(
                    onPressed: null,
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Column(
                    children: [
                      ElevatedButton(
                        onPressed: _handleCreateSecret,
                        child: const Text('Create Secret'),
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
