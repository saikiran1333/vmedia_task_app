import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/catalogue_theme.dart';
import '../../../catalog/presentation/screens/catalogue_shell.dart';
import '../../../catalog/presentation/ui/catalog_widgets.dart';
import '../../../catalog/presentation/viewmodels/catalog_viewmodels.dart';
import '../../domain/enquiry_rules.dart';
import '../viewmodels/enquiry_viewmodels.dart';

class EnquiryFormScreen extends ConsumerStatefulWidget {
  const EnquiryFormScreen({super.key});

  @override
  ConsumerState<EnquiryFormScreen> createState() => _EnquiryFormScreenState();
}

class _EnquiryFormScreenState extends ConsumerState<EnquiryFormScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _company = TextEditingController();
  final _message = TextEditingController();
  final _units = TextEditingController(text: '1');
  final _requirements = TextEditingController();
  final _date = TextEditingController();
  String _occasion = '';
  String _budget = '';
  final _options = <String>{};

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _city, _company, _message, _units, _requirements, _date]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _clear() {
    for (final controller in [_name, _email, _phone, _city, _company, _message, _requirements, _date]) {
      controller.clear();
    }
    _units.text = '1';
    setState(() {
      _occasion = '';
      _budget = '';
      _options.clear();
    });
    ref.read(selectionProvider.notifier).clear();
  }

  Future<void> _submit(List<String> occasions, List<String> customisations) async {
    final gifts = ref.read(selectionProvider);
    final draft = EnquiryDraft(
      name: _name.text,
      email: _email.text,
      phone: _phone.text,
      city: _city.text,
      companyName: _company.text,
      occasion: _occasion,
      budget: _budget,
      message: _message.text,
      units: _units.text,
      customisationRequirements: _requirements.text,
      deliveryDate: _date.text.trim(),
      customisationOptions: _options.toList(),
      gifts: gifts,
    );
    final sent = await ref.read(enquiryFormViewModelProvider.notifier).submit(draft, occasions: occasions, customisations: customisations);
    if (!mounted || !sent) return;
    _clear();
    context.push('/enquiry-sent');
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(enquiryFormViewModelProvider);
    final gifts = ref.watch(selectionProvider);
    final occasions = ref.watch(occasionsProvider);
    final customisations = ref.watch(customisationsProvider);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return CatalogueScaffold(
      title: 'Enquiry',
      body: occasions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => StatusPanel(title: 'Form unavailable', body: 'Occasions could not be loaded.', actionLabel: 'Retry', onAction: () => ref.invalidate(occasionsProvider)),
        data: (occasionRows) {
          final labels = occasionRows.map((item) => item.enquiryLabel).where((label) => label.isNotEmpty).toList();
          final offered = customisations.value ?? const <String>[];
          final allowed = _allowedOptions(offered, gifts);
          return ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + inset),
            children: [
              const Text('Tell us about the gifts. We reply within 24 working hours.', style: TextStyle(color: CatalogueTheme.muted, height: 1.4)),
              const SizedBox(height: 16),
              if (form.message != null) ...[
                Text(form.message!, style: const TextStyle(color: CatalogueTheme.terracotta)),
                const SizedBox(height: 12),
              ],
              _field(_name, 'Name', error: form.errors['name']),
              _field(_email, 'Email', error: form.errors['email'], keyboard: TextInputType.emailAddress),
              _field(_phone, 'Phone', error: form.errors['phone'], keyboard: TextInputType.phone),
              _field(_city, 'City', error: form.errors['city']),
              _field(_company, 'Company name (optional)', error: form.errors['companyName']),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _occasion.isEmpty ? null : _occasion,
                decoration: InputDecoration(labelText: 'Occasion', errorText: form.errors['occasion']),
                items: [for (final label in labels) DropdownMenuItem(value: label, child: Text(label, overflow: TextOverflow.ellipsis))],
                onChanged: (value) => setState(() => _occasion = value ?? ''),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _budget.isEmpty ? null : _budget,
                decoration: InputDecoration(labelText: 'Budget', errorText: form.errors['budget']),
                items: [for (final label in enquiryBudgets) DropdownMenuItem(value: label, child: Text(label, overflow: TextOverflow.ellipsis))],
                onChanged: (value) => setState(() => _budget = value ?? ''),
              ),
              const SizedBox(height: 12),
              if (gifts.isEmpty)
                _field(_units, 'Number of gifts', error: form.errors['units'], keyboard: TextInputType.number)
              else ...[
                Text('Selected gifts · ${totalUnits(gifts)} units', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (form.errors['gifts'] != null || form.errors['quantity'] != null || form.errors['units'] != null)
                  Text(form.errors['gifts'] ?? form.errors['quantity'] ?? form.errors['units']!, style: const TextStyle(color: CatalogueTheme.terracotta)),
                const SizedBox(height: 8),
                for (final gift in gifts) _GiftRow(gift: gift),
                const SizedBox(height: 12),
              ],
              if (allowed.isNotEmpty) ...[
                const Text('Customisation', style: TextStyle(fontWeight: FontWeight.w600)),
                for (final option in allowed)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _options.contains(option),
                    title: Text(option),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _options.add(option);
                      } else {
                        _options.remove(option);
                      }
                    }),
                  ),
                if (form.errors['customisationOptions'] != null) Text(form.errors['customisationOptions']!, style: const TextStyle(color: CatalogueTheme.terracotta)),
              ],
              _field(_requirements, 'Customisation requirements (optional)', error: form.errors['customisationRequirements'], lines: 3),
              _field(_message, 'Message', error: form.errors['message'], lines: 4),
              TextField(
                controller: _date,
                readOnly: true,
                decoration: InputDecoration(labelText: 'Delivery date (optional)', errorText: form.errors['deliveryDate']),
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(context: context, firstDate: DateTime(now.year, now.month, now.day), lastDate: DateTime(now.year + 2));
                  if (picked == null) return;
                  _date.text = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: form.status == EnquirySubmitStatus.submitting ? null : () => _submit(labels, offered),
                child: Text(form.status == EnquirySubmitStatus.submitting ? 'Sending…' : 'Send enquiry'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {String? error, TextInputType? keyboard, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        minLines: lines,
        maxLines: lines,
        decoration: InputDecoration(labelText: label, errorText: error),
      ),
    );
  }
}

List<String> _allowedOptions(List<String> offered, List<SelectedGift> gifts) {
  if (gifts.isEmpty) return offered;
  var allowed = offered.toSet();
  for (final gift in gifts) {
    allowed = allowed.intersection(gift.customisationOptions.toSet());
  }
  return allowed.toList();
}

class _GiftRow extends ConsumerWidget {
  const _GiftRow({required this.gift});
  final SelectedGift gift;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 56, child: CatalogImage(imageKey: gift.imageKey))),
          const SizedBox(width: 12),
          Expanded(child: Text(gift.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
          IconButton(onPressed: () => ref.read(selectionProvider.notifier).setQuantity(gift.id, gift.quantity - 1), icon: const Icon(Icons.remove)),
          Text('${gift.quantity}'),
          IconButton(onPressed: () => ref.read(selectionProvider.notifier).setQuantity(gift.id, gift.quantity + 1), icon: const Icon(Icons.add)),
          IconButton(onPressed: () => ref.read(selectionProvider.notifier).remove(gift.id), icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
