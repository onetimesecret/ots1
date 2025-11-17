import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../blocs/secret/secret_bloc.dart';
import '../../blocs/secret/secret_event.dart';
import '../../blocs/secret/secret_state.dart';

/// Page for creating new secrets
class CreateSecretPage extends StatefulWidget {
  const CreateSecretPage({super.key});

  @override
  State<CreateSecretPage> createState() => _CreateSecretPageState();
}

class _CreateSecretPageState extends State<CreateSecretPage> {
  final _formKey = GlobalKey<FormState>();
  final _secretController = TextEditingController();
  final _passphraseController = TextEditingController();
  final _recipientController = TextEditingController();

  int _selectedTtl = AppConstants.defaultTtl;
  bool _usePassphrase = false;

  final List<Map<String, dynamic>> _ttlOptions = [
    {'label': '5 minutes', 'value': 300},
    {'label': '1 hour', 'value': 3600},
    {'label': '1 day', 'value': 86400},
    {'label': '7 days', 'value': 604800},
    {'label': '30 days', 'value': 2592000},
  ];

  @override
  void dispose() {
    _secretController.dispose();
    _passphraseController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  void _handleCreateSecret() {
    if (_formKey.currentState!.validate()) {
      context.read<SecretBloc>().add(CreateSecretEvent(
            secret: _secretController.text,
            passphrase:
                _usePassphrase ? _passphraseController.text : null,
            ttl: _selectedTtl,
            recipient: _recipientController.text.isEmpty
                ? null
                : _recipientController.text,
          ));
    }
  }

  void _handleShare(String url) {
    Share.share(
      'I\'ve shared a secret with you. View it here (one time only): $url',
      subject: 'OneTimeSecret - View Secret',
    );
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
        title: const Text('Create Secret'),
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
          if (state is SecretCreated) {
            return _buildSuccessView(state);
          }

          return _buildCreateForm(state is SecretLoading);
        },
      ),
    );
  }

  Widget _buildCreateForm(bool isLoading) {
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
                  TextFormField(
                    controller: _secretController,
                    decoration: const InputDecoration(
                      labelText: 'Secret',
                      hintText: 'Enter your secret here...',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    maxLines: 5,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a secret';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Add passphrase protection'),
                    subtitle: const Text('Require a passphrase to view'),
                    value: _usePassphrase,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _usePassphrase = value;
                            });
                          },
                  ),
                  if (_usePassphrase) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passphraseController,
                      decoration: const InputDecoration(
                        labelText: 'Passphrase',
                        hintText: 'Enter passphrase',
                        prefixIcon: Icon(Icons.key_outlined),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                      validator: (value) {
                        if (_usePassphrase &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Please enter a passphrase';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Expires after',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _ttlOptions.map((option) {
                      return ChoiceChip(
                        label: Text(option['label']),
                        selected: _selectedTtl == option['value'],
                        onSelected: isLoading
                            ? null
                            : (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedTtl = option['value'];
                                  });
                                }
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _recipientController,
                    decoration: const InputDecoration(
                      labelText: 'Recipient (optional)',
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleCreateSecret,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Secret'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(SecretCreated state) {
    final shareUrl = state.secret.getShareUrl(AppConstants.baseUrl);

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
                  'Secret Created!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Share this link with your recipient',
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
                      children: [
                        QrImageView(
                          data: shareUrl,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                        const SizedBox(height: 24),
                        SelectableText(
                          shareUrl,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _handleCopyToClipboard(shareUrl),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _handleShare(shareUrl),
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                          ],
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
                          Icons.warning_amber,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'This link can only be viewed once. After that, it will be destroyed.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
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
