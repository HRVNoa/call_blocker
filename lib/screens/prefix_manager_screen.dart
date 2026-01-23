import 'package:flutter/material.dart';
import '../models/blocked_prefix.dart';
import '../services/storage_service.dart';

class PrefixManagerScreen extends StatefulWidget {
  const PrefixManagerScreen({super.key});

  @override
  State<PrefixManagerScreen> createState() => _PrefixManagerScreenState();
}

class _PrefixManagerScreenState extends State<PrefixManagerScreen> {
  final StorageService _storageService = StorageService();
  List<BlockedPrefix> _prefixes = [];

  @override
  void initState() {
    super.initState();
    _loadPrefixes();
  }

  Future<void> _loadPrefixes() async {
    final prefixes = await _storageService.getBlockedPrefixes();
    setState(() {
      _prefixes = prefixes;
    });
  }

  Future<void> _togglePrefix(BlockedPrefix prefix) async {
    final updated = prefix.copyWith(isEnabled: !prefix.isEnabled);
    await _storageService.updatePrefix(prefix.prefix, updated);
    _loadPrefixes();
  }

  Future<void> _deletePrefix(String prefix) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le préfixe $prefix ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.removePrefix(prefix);
      _loadPrefixes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préfixe supprimé')),
        );
      }
    }
  }

  Future<void> _addPrefix() async {
    final TextEditingController prefixController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un préfixe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: prefixController,
              decoration: const InputDecoration(
                labelText: 'Préfixe (ex: 0270)',
                hintText: '0270',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Démarchage téléphonique',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (result == true && prefixController.text.isNotEmpty) {
      final newPrefix = BlockedPrefix(
        prefix: prefixController.text.trim(),
        description: descController.text.trim().isEmpty 
            ? 'Préfixe personnalisé' 
            : descController.text.trim(),
      );
      
      await _storageService.addPrefix(newPrefix);
      _loadPrefixes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préfixe ajouté')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les préfixes'),
        elevation: 2,
      ),
      body: _prefixes.isEmpty
          ? const Center(
              child: Text('Aucun préfixe configuré'),
            )
          : ListView.builder(
              itemCount: _prefixes.length,
              itemBuilder: (context, index) {
                final prefix = _prefixes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Checkbox(
                      value: prefix.isEnabled,
                      onChanged: (_) => _togglePrefix(prefix),
                    ),
                    title: Text(
                      prefix.prefix,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: prefix.isEnabled 
                            ? null 
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text(prefix.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePrefix(prefix.prefix),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPrefix,
        child: const Icon(Icons.add),
      ),
    );
  }
}
