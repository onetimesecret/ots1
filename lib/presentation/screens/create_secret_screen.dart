import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/secret_provider.dart';
import '../widgets/loading_overlay.dart';

/// Screen for creating a new one-time secret
class CreateSecretScreen extends StatefulWidget {
  const CreateSecretScreen({super.key});

  @override
  State<CreateSecretScreen> createState() => _CreateSecretScreenState();
}

class _CreateSecretScreenState extends State<CreateSecretScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secretController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _recipientController = TextEditingController();

  int? _selectedTTL = 604800; // 7 days default
  bool _usePassphrase = false;
  bool _obscureSecret = true;

  @override
  void dispose() {
    _secretController.dispose();
    _passphraseController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _createSecret() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<SecretProvider>();
    await provider.createSecret(
      value: _secretController.text,
      ttl: _selectedTTL,
      passphrase: _usePassphrase ? _passphraseController.text : null,
      recipient: _recipientController.text.isNotEmpty
          ? _recipientController.text
          : null,
    );

    if (provider.state == SecretState.loaded && mounted) {
      _showSuccessDialog();
    } else if (provider.state == SecretState.error && mounted) {
      _showErrorDialog(provider.errorMessage ?? 'Unknown error');
    }
  }

  void _showSuccessDialog() {
    final secret = context.read<SecretProvider>().currentSecret;
    if (secret == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Secret Created'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your secret has been created successfully. Share this link:',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                'https://onetimesecret.dev/secret/${secret.secretKey}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        'https://onetimesecret.dev/secret/${secret.secretKey}',
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Link'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Secret'),
      ),
      body: Consumer<SecretProvider>(
        builder: (context, provider, child) {
          return LoadingOverlay(
            isLoading: provider.state == SecretState.loading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Secret input
                    TextFormField(
                      controller: _secretController,
                      decoration: InputDecoration(
                        labelText: 'Secret *',
                        hintText: 'Enter your secret message',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSecret
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureSecret = !_obscureSecret;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureSecret,
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a secret';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // TTL selector
                    DropdownButtonFormField<int>(
                      value: _selectedTTL,
                      decoration: const InputDecoration(
                        labelText: 'Time to Live',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 300, child: Text('5 minutes')),
                        DropdownMenuItem(
                          value: 3600,
                          child: Text('1 hour'),
                        ),
                        DropdownMenuItem(
                          value: 86400,
                          child: Text('1 day'),
                        ),
                        DropdownMenuItem(
                          value: 604800,
                          child: Text('7 days'),
                        ),
                        DropdownMenuItem(
                          value: 1209600,
                          child: Text('14 days'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTTL = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Passphrase toggle
                    SwitchListTile(
                      title: const Text('Require Passphrase'),
                      subtitle: const Text(
                        'Add an extra layer of protection',
                      ),
                      value: _usePassphrase,
                      onChanged: (value) {
                        setState(() {
                          _usePassphrase = value;
                        });
                      },
                    ),

                    // Passphrase input (conditional)
                    if (_usePassphrase) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passphraseController,
                        decoration: const InputDecoration(
                          labelText: 'Passphrase *',
                          hintText: 'Enter passphrase',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_usePassphrase &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter a passphrase';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Recipient (optional)
                    TextFormField(
                      controller: _recipientController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient (optional)',
                        hintText: 'Email or identifier',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),

                    // Create button
                    ElevatedButton(
                      onPressed: _createSecret,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Create Secret'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
