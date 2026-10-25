import 'cdc_translation_keys.dart';

// CEFP shares the CDC screen structure. Its matrix uses a separate namespace;
// values must always come from the CEFP dictionary, even for shared web keys.
String cefpApiKey(String key) {
  final sharedKey = cdcApiKey(key);
  const prefix = 'cdc_issue_matrix.';
  return sharedKey.startsWith(prefix)
      ? 'cefp_issue_matrix.${sharedKey.substring(prefix.length)}'
      : sharedKey;
}

Map<String, String> _cefpKeys(Map<String, String> keys) =>
    keys.map((alias, key) => MapEntry(alias, cefpApiKey(key)));

final cefpCommonKeys = <String, String>{
  ..._cefpKeys(cdcCommonKeys),
  'cefpIssuesMatrix': 'cefp_issue_matrix.title',
};

final cefpPageKeys = cdcPageKeys.map(
  (page, keys) => MapEntry(page, _cefpKeys(keys)),
);

const cefpPageParents = cdcPageParents;

final cefpFilterKeys = cdcFilterKeys.map(
  (page, keys) => MapEntry(page, _cefpKeys(keys)),
);
