enum ProtocolType { injection, oral, topical, nasal, sublingual, other }

extension ProtocolTypeDetails on ProtocolType {
  String get label {
    switch (this) {
      case ProtocolType.injection:
        return 'Injection';
      case ProtocolType.oral:
        return 'Oral';
      case ProtocolType.topical:
        return 'Topical';
      case ProtocolType.nasal:
        return 'Nasal';
      case ProtocolType.sublingual:
        return 'Sublingual';
      case ProtocolType.other:
        return 'Other';
    }
  }

  String get storageValue {
    switch (this) {
      case ProtocolType.injection:
        return 'injection';
      case ProtocolType.oral:
        return 'oral';
      case ProtocolType.topical:
        return 'topical';
      case ProtocolType.nasal:
        return 'nasal';
      case ProtocolType.sublingual:
        return 'sublingual';
      case ProtocolType.other:
        return 'other';
    }
  }

  static ProtocolType fromStorageValue(String? value) {
    switch (value) {
      case 'oral':
        return ProtocolType.oral;
      case 'topical':
        return ProtocolType.topical;
      case 'nasal':
        return ProtocolType.nasal;
      case 'sublingual':
        return ProtocolType.sublingual;
      case 'other':
        return ProtocolType.other;
      case 'injection':
      default:
        return ProtocolType.injection;
    }
  }
}
