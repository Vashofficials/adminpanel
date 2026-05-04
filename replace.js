const fs = require('fs');
const content = fs.readFileSync('lib/screens/booking_details_screen.dart', 'utf-8');

const startMarker = '// ─── Reschedule Reasons';
const endMarker = 'void _showCancelDialog';

const startIndex = content.indexOf(startMarker);
const endIndex = content.indexOf(endMarker);

if (startIndex !== -1 && endIndex !== -1) {
    const before = content.substring(0, startIndex);
    const after = content.substring(endIndex);
    const replacement = `void _showRescheduleDialog(BookingModel booking) {
  showDialog(
    context: context,
    builder: (context) => RescheduleBookingDialog(
      booking: booking,
      onBack: widget.onBack,
    ),
  );
}\n\n`;

    fs.writeFileSync('lib/screens/booking_details_screen.dart', before + replacement + after, 'utf-8');
    console.log('Successfully replaced the reschedule logic.');
} else {
    console.log('Failed to find markers.', startIndex, endIndex);
}
