class BookingReportModel {
  String? type;
  BookingResult? result;

  BookingReportModel({this.type, this.result});

  BookingReportModel.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    result = json['result'] != null ? BookingResult.fromJson(json['result']) : null;
  }
}

class BookingResult {
  int? cancelled, completed, ongoing, pending, year;
  List<MonthData>? completedMonth, cancelledMonth, ongoingMonth, pendingMonth;

  BookingResult({
    this.cancelled, this.completed, this.ongoing, this.pending, this.year,
    this.completedMonth, this.cancelledMonth, this.ongoingMonth, this.pendingMonth,
  });

  BookingResult.fromJson(Map<String, dynamic> json) {
    cancelled = json['cancelled'];
    completed = json['completed'];
    ongoing = json['ongoing'];
    pending = json['pending'];
    year = json['year'];
    if (json['completedMonth'] != null) {
      completedMonth = <MonthData>[];
      json['completedMonth'].forEach((v) => completedMonth!.add(MonthData.fromJson(v)));
    }
    if (json['cancelledMonth'] != null) {
      cancelledMonth = <MonthData>[];
      json['cancelledMonth'].forEach((v) => cancelledMonth!.add(MonthData.fromJson(v)));
    }
    if (json['ongoingMonth'] != null) {
      ongoingMonth = <MonthData>[];
      json['ongoingMonth'].forEach((v) => ongoingMonth!.add(MonthData.fromJson(v)));
    }
    if (json['pendingMonth'] != null) {
      pendingMonth = <MonthData>[];
      json['pendingMonth'].forEach((v) => pendingMonth!.add(MonthData.fromJson(v)));
    }
  }
}

class MonthData {
  String? mothName;
  int? cashBooking, onlineBooking;

  MonthData({this.mothName, this.cashBooking, this.onlineBooking});

  MonthData.fromJson(Map<String, dynamic> json) {
    mothName = json['mothName'];
    cashBooking = json['cashBooking'];
    onlineBooking = json['onlineBooking'];
  }
}