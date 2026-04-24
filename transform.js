const fs = require('fs');
let code = fs.readFileSync('lib/screens/offline_payment_screen.dart', 'utf8');

// Replacements
code = code.replace(/OfflinePaymentScreen/g, 'CompletedBookingScreen');
code = code.replace(/offline_payments_/g, 'completed_bookings_');
code = code.replace(/Offline Payment Report/g, 'Completed Bookings Report');

// Default status
code = code.replace(/String\?\s+_selectedStatus;\s*\/\/\s*null\s*=\s*"All statuses"/g, 'String? _selectedStatus = "Completed";');

// Remove offline filtering in fetch
// We need to carefully match this:
// final offlineList = response.content
//             .where((b) =>
//                 b.paymentMode.toUpperCase() == 'CASH' ||
//                 b.paymentMode.toUpperCase() == 'OFFLINE')
//             .toList();
const filterRegex = /final offlineList = response\.content\s*\.where\(\(b\)\s*=>\s*b\.paymentMode\.toUpperCase\(\) == 'CASH' \|\|\s*b\.paymentMode\.toUpperCase\(\) == 'OFFLINE'\)\s*\.toList\(\);/;
code = code.replace(filterRegex, 'final offlineList = response.content;');

// The title in build
code = code.replace(/"Offline Payment Report"/g, '"Completed Bookings"');

// Remove banners call in build
code = code.replace(/Padding\(\s*padding:\s*const EdgeInsets\.symmetric\(horizontal:\s*24\),\s*child:\s*_buildWarningBanner\(\),\s*\),\s*const SizedBox\(height:\s*16\),/g, '');

// Remove banner widget methods entirely
code = code.replace(/Widget _buildInfoBanner\(\) \{[\s\S]*?Widget _buildWarningBanner\(\) \{/g, 'Widget _buildWarningBanner() {');
code = code.replace(/Widget _buildWarningBanner\(\) \{[\s\S]*?Widget _buildEmptyState\(\) \{/g, 'Widget _buildEmptyState() {');

// Empty state
code = code.replace(/"No Transactions Found"/g, '"No Completed Bookings"');

fs.writeFileSync('lib/screens/completed_booking_screen.dart', code);
