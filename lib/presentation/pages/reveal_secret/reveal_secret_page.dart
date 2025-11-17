import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../blocs/secret/secret_bloc.dart';
import '../../blocs/secret/secret_event.dart';
import '../../blocs/secret/secret_state.dart';

/// Page for revealing/viewing secrets
class RevealSecretPage extends StatefulWidget {
  final String? secretKey;

  const RevealSecretPage({super.key, this.secretKey});

  @override
  State<RevealSecretPage> createState() => _RevealSecretPageState();
}

class _RevealSecretPageState extends State<RevealSecretPage> {
  final _formKey = GlobalKey<FormState>();
  final _secretKeyController = TextEditingController();
  final _passphraseController = TextEditingController();

  bool _showScanner = false;
  bool _requiresPassphrase = false;

  @override
  void initState() {
    super.initState();
    if (widget.secretKey != null) {
      _secretKeyController.text = widget.secretKey!;
    }
  }

  @override
  void dispose() {
    _secretKeyController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  void _handleRevealSecret() {
    if (_formKey.currentState!.validate()) {
      context.read<SecretBloc>().add(RevealSecretEvent(
            secretKey: _secretKeyController.text.trim(),
            passphrase: _requiresPassphrase
                ? _passphraseController.text
                : null,
          ));
    }
  }

  void _handleQRCodeDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      final url = barcode!.rawValue!;
      // Extract secret key from URL
      final uri = Uri.parse(url);
      final secretKey = uri.pathSegments.last;

      setState(() {
        _secretKeyController.text = secretKey;
        _showScanner = false;
      });
    }
  }

  void _handleCopyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Secret'),
        actions: [
          IconButton(
            icon: Icon(_showScanner ? Icons.keyboard : Icons.qr_code_scanner),
            onPressed: () {
              setState(() {
                _showScanner = !_showScanner;
              });
            },
            tooltip: _showScanner ? 'Enter manually' : 'Scan QR code',
          ),
        ],
      ),
      body: BlocConsumer<SecretBloc, SecretState>(
        listener: (context, state) {
          if (state is SecretError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SecretRevealed) {
            return _buildRevealedView(state);
          }

          if (_showScanner) {
            return _buildQRScanner();
          }

          return _buildRevealForm(state is SecretLoading);
        },
      ),
    );
  }

  Widget _buildQRScanner() {
    return MobileScanner(
      onDetect: _handleQRCodeDetected,
      overlay: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Scan QR code to reveal secret',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevealForm(bool isLoading) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter the secret key to reveal',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _secretKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Secret Key',
                      hintText: 'Enter or paste secret key',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a secret key';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Protected by passphrase'),
                    subtitle: const Text('This secret requires a passphrase'),
                    value: _requiresPassphrase,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _requiresPassphrase = value;
                            });
                          },
                  ),
                  if (_requiresPassphrase) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passphraseController,
                      decoration: const InputDecoration(
                        labelText: 'Passphrase',
                        hintText: 'Enter passphrase',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                      validator: (value) {
                        if (_requiresPassphrase &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter the passphrase';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleRevealSecret,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Reveal Secret'),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Warning: Revealing this secret will destroy it permanently.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevealedView(SecretRevealed state) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Secret Revealed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'This secret has been destroyed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Secret Content',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () => _handleCopyToClipboard(
                                  state.secret.value ?? ''),
                              tooltip: 'Copy to clipboard',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          state.secret.value ?? 'No content',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'This secret has been permanently destroyed and cannot be viewed again.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () {
                    context.read<SecretBloc>().add(ResetSecretEvent());
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
