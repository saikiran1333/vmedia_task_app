import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/catalogue_theme.dart';
import '../viewmodels/enquiry_viewmodels.dart';

class EnquirySuccessScreen extends ConsumerWidget {
  const EnquirySuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(enquiryFormViewModelProvider);
    final receipt = form.receipt;
    return Theme(
      data: CatalogueTheme.light(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Enquiry sent')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: receipt == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('There is no new enquiry to show.', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: () => context.go('/'), child: const Text('Back home')),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        form.status == EnquirySubmitStatus.localSaveFailed ? 'Sent, with one note' : 'Enquiry received',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text('Reference ${receipt.enquiryNumber}', style: const TextStyle(fontSize: 18, color: CatalogueTheme.terracotta, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('${receipt.units} units · ${receipt.createdAt}', style: const TextStyle(color: CatalogueTheme.muted)),
                      const SizedBox(height: 16),
                      Text(
                        form.status == EnquirySubmitStatus.localSaveFailed
                            ? 'The server accepted this enquiry. It could not be saved in My Enquiries on this phone. Saving again will not send a second enquiry.'
                            : 'A specialist will reply within 24 working hours. This reference is also kept in My Enquiries on this phone.',
                        style: const TextStyle(height: 1.4),
                      ),
                      if (form.message != null) ...[const SizedBox(height: 8), Text(form.message!, style: const TextStyle(color: CatalogueTheme.terracotta))],
                      const Spacer(),
                      if (form.status == EnquirySubmitStatus.localSaveFailed)
                        ElevatedButton(
                          onPressed: () => ref.read(enquiryFormViewModelProvider.notifier).retryLocalSave(),
                          child: const Text('Save in My Enquiries'),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton(onPressed: () => context.go('/enquiries'), child: const Text('View my enquiries')),
                      const SizedBox(height: 8),
                      TextButton(onPressed: () => context.go('/'), child: const Text('Back home')),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
