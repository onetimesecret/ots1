import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/secret_provider.dart';
import '../widgets/loading_overlay.dart';

/// Screen for retrieving a one-time secret
class RetrieveSecretScreen extends StatefulWidget {
  const RetrieveSecretScreen({super.key});

  @override
  State<RetrieveSecretScreen> createState() => _RetrieveSecretScreenState();
}

class _RetrieveSecretScreenState extends State<RetrieveSecretScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secretKeyController = TextEditingController();
  final _passphraseController = TextEditingController();

  bool _requiresPassphrase = false;
  bool _secretRetrieved = false;

  @override
  void dispose() {
    _secretKeyController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _retrieveSecret() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<SecretProvider>();
    await provider.retrieveSecret(
      secretKey: _secretKeyController.text.trim(),
      passphrase: _requiresPassphrase ? _passphraseController.text : null,
    );

    if (provider.state == SecretState.loaded && mounted) {
      setState(() {
        _secretRetrieved = true;
      });
    } else if (provider.state == SecretState.error && mounted) {
      _showErrorDialog(provider.errorMessage ?? 'Unknown error');
    }
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
        title: const Text('Retrieve Secret'),
        actions: [
          if (_secretRetrieved)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _secretRetrieved = false;
                  _secretKeyController.clear();
                  _passphraseController.clear();
                  _requiresPassphrase = false;
                });
                context.read<SecretProvider>().clearSecret();
              },
              tooltip: 'Retrieve another secret',
            ),
        ],
      ),
      body: Consumer<SecretProvider>(
        builder: (context, provider, child) {
          if (_secretRetrieved && provider.currentSecret != null) {
            return _buildSecretDisplay(provider.currentSecret!.value ?? '');
          }

          return LoadingOverlay(
            isLoading: provider.state == SecretState.loading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Warning banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Warning: The secret will be permanently deleted after viewing',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Secret key input
                    TextFormField(
                      controller: _secretKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Secret Key *',
                        hintText: 'Enter the secret key',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a secret key';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Passphrase toggle
                    SwitchListTile(
                      title: const Text('Requires Passphrase'),
                      subtitle: const Text(
                        'Enable if the secret is passphrase-protected',
                      ),
                      value: _requiresPassphrase,
                      onChanged: (value) {
                        setState(() {
                          _requiresPassphrase = value;
                        });
                      },
                    ),

                    // Passphrase input (conditional)
                    if (_requiresPassphrase) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passphraseController,
                        decoration: const InputDecoration(
                          labelText: 'Passphrase *',
                          hintText: 'Enter passphrase',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (_requiresPassphrase &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter the passphrase';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Retrieve button
                    ElevatedButton(
                      onPressed: _retrieveSecret,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text('Retrieve Secret'),
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

  Widget _buildSecretDisplay(String secretValue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secret retrieved successfully! This secret has been deleted.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Secret content
          const Text(
            'Secret Content:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: SelectableText(
              secretValue,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Copy button
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: secretValue));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Secret copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy to Clipboard'),
          ),
          const SizedBox(height: 24),

          // Reminder note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF0066CC)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Remember to securely store or use this secret immediately. '
                    'It cannot be retrieved again.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
