import 'injection_site.dart';

class InjectionLog {
  InjectionLog({
    String? id,
    required this.protocolId,
    required this.doseRecordId,
    required this.site,
    required this.loggedAt,
    this.notes,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  static const Object _unset = Object();

  final String id;
  final String protocolId;
  final String doseRecordId;
  final InjectionSite site;
  final DateTime loggedAt;
  final String? notes;

  InjectionLog copyWith({
    String? id,
    String? protocolId,
    String? doseRecordId,
    InjectionSite? site,
    DateTime? loggedAt,
    Object? notes = _unset,
  }) {
    return InjectionLog(
      id: id ?? this.id,
      protocolId: protocolId ?? this.protocolId,
      doseRecordId: doseRecordId ?? this.doseRecordId,
      site: site ?? this.site,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: identical(notes, _unset) ? this.notes : notes as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'protocol_id': protocolId,
      'dose_record_id': doseRecordId,
      'site': site.storageValue,
      'logged_at': loggedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory InjectionLog.fromMap(Map<String, Object?> map) {
    final storedSite = InjectionSiteDetails.fromStorageValue(
      map['site'] as String?,
    );

    if (storedSite == null) {
      throw FormatException('Unknown injection site: ${map['site']}');
    }

    return InjectionLog(
      id: map['id'] as String,
      protocolId: map['protocol_id'] as String,
      doseRecordId: map['dose_record_id'] as String,
      site: storedSite,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      notes: map['notes'] as String?,
    );
  }
}
