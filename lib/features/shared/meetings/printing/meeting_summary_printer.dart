import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import '../../../../core/text/html_text.dart';
import '../../../../translations/app_language.dart';
import '../../../../translations/app_localizations.dart';
import '../data/meeting_summary.dart';

/// The native WebView print engines shape Khmer and paginate rich text just as
/// the web report does. All assets are bundled; no credentials or remote URLs
/// are passed to the print renderer.
class MeetingSummaryPrinter {
  static const channel = MethodChannel('gpsf/meeting-summary-print');

  static Future<void> printSummary(MeetingSummary summary) async {
    final document = await buildDocument(summary);
    await printDocument(document, name: 'Meeting-Summary-${summary.id}');
  }

  static Future<void> printDocument(
    String document, {
    required String name,
  }) async {
    await channel.invokeMethod<void>('printHtml', {
      'html': document,
      'name': name,
    });
  }

  static Future<String> buildDocument(MeetingSummary summary) async {
    Future<String> asset(String path) async {
      final bytes = await rootBundle.load(path);
      return base64Encode(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }

    final assets = await Future.wait([
      asset('assets/fonts/KhBattambang.ttf'),
      asset('assets/print/Moul-Regular.ttf'),
      asset('assets/print/primary-agency.png'),
      asset('assets/print/cdc-logo.png'),
      rootBundle.loadString('assets/print/khmer-calendar.js'),
    ]);
    return meetingSummaryPrintHtml(
      summary,
      bodyFont: assets[0],
      titleFont: assets[1],
      agencyLogo: assets[2],
      cdcLogo: assets[3],
      calendarScript: assets[4],
    );
  }
}

String _text(String value) => const HtmlEscape().convert(value);
String _value(String value) => _text(
  value.trim().isEmpty || value.trim() == 'Not Uploaded' ? '-' : value.trim(),
);

/// Keep editor paragraphs, lists and tables, but never scripts, URLs, or
/// arbitrary CSS in a document running inside the native print WebView.
String meetingSummaryPrintRichText(String value) {
  if (value.trim().isEmpty || value.trim() == 'Not Uploaded') return '-';
  if (!containsEditorHtml(value)) return _text(value).replaceAll('\n', '<br>');
  const tags = {
    'p',
    'div',
    'span',
    'strong',
    'b',
    'em',
    'i',
    'u',
    's',
    'strike',
    'mark',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'ul',
    'ol',
    'li',
    'blockquote',
    'pre',
    'code',
    'table',
    'thead',
    'tbody',
    'tr',
    'td',
    'th',
    'br',
    'hr',
    'a',
  };
  const blocked = {
    'script',
    'style',
    'iframe',
    'object',
    'embed',
    'svg',
    'math',
    'form',
    'input',
    'button',
    'meta',
    'link',
    'img',
    'video',
    'audio',
    'template',
  };
  String serialize(dom.Node node) {
    if (node is dom.Text) return _text(node.data);
    if (node is! dom.Element) return '';
    final tag = node.localName!;
    if (blocked.contains(tag)) return '';
    final children = node.nodes.map(serialize).join();
    if (!tags.contains(tag)) return children;
    final styles = <String>[];
    for (final rule in (node.attributes['style'] ?? '').split(';')) {
      final parts = rule.split(':');
      if (parts.length != 2) continue;
      final key = parts[0].trim().toLowerCase();
      final val = parts[1].trim().toLowerCase();
      if ((key == 'text-align' &&
              {'left', 'right', 'center', 'justify'}.contains(val)) ||
          ({'color', 'background-color'}.contains(key) &&
              RegExp(
                r'^(#[0-9a-f]{3,8}|[a-z]+|rgba?\([\d\s.,%]+\))$',
              ).hasMatch(val))) {
        styles.add('$key:$val');
      }
    }
    final style = styles.isEmpty ? '' : ' style="${_text(styles.join(';'))}"';
    final spans = ['colspan', 'rowspan']
        .where(
          (key) =>
              {'td', 'th'}.contains(tag) &&
              RegExp(r'^[1-9][0-9]?$').hasMatch(node.attributes[key] ?? ''),
        )
        .map((key) => ' $key="${node.attributes[key]}"')
        .join();
    if (tag == 'br' || tag == 'hr') return '<$tag>';
    return '<$tag$style$spans>$children</$tag>';
  }

  return html
      .parseFragment(sanitizedEditorHtml(value))
      .nodes
      .map(serialize)
      .join();
}

String meetingSummaryPrintHtml(
  MeetingSummary summary, {
  required String bodyFont,
  required String titleFont,
  required String agencyLogo,
  required String cdcLogo,
  required String calendarScript,
}) {
  const kh = AppLocalizations(AppLanguage.khmer);
  final sector = summary.pswgKhName.trim().isNotEmpty
      ? summary.pswgKhName
      : summary.pswg;
  final date = summary.detailDate ?? summary.date;
  final dateKey = date == null
      ? ''
      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String row(String label, String value, {bool rich = false}) =>
      '<tr><td>${_text(label)}</td><td>${rich ? meetingSummaryPrintRichText(value) : _value(value).replaceAll('\n', '<br>')}</td></tr>';
  String status(String value) =>
      switch (value.toUpperCase().replaceAll(' ', '_')) {
        'SOLVED' => 'បានដោះស្រាយ',
        'IN_PROGRESS' => 'កំពុងដោះស្រាយ',
        'NOT_ADDRESSED' => 'មិនទាន់ដោះស្រាយ',
        'NEW_SUBMITTED' => 'បានដាក់ស្នើថ្មី',
        _ => value,
      };
  final issues = summary.issues.indexed.map((entry) {
    final (index, issue) = entry;
    final agencyOrders = issue.governmentAgencies.keys.toList()..sort();
    return '''<section class="issue"><h3>${kh.number(index + 1)}. ${_value(issue.title)}</h3>
<table class="issue-table"><thead><tr><th>ព័ត៌មានកិច្ចប្រជុំ</th><th>ពិពណ៌នា</th></tr></thead><tbody>
${row('ប្រភេទបញ្ហា', issue.category)}
${row('សេចក្តីសង្ខេបបញ្ហារបស់ផ្នែកឯកជន', issue.descriptionHtml, rich: true)}
${row('សំណើរណ៍របស់ផ្នែកឯកជន', issue.recommendationHtml, rich: true)}
${row('ដំណោះស្រាយក្នុងកិច្ចប្រជុំ', issue.rgcDecisionHtml, rich: true)}
${row('សកម្មភាពបន្ទាប់', issue.nextStepHtml, rich: true)}
${row('កំណត់ចំណាំផ្សេងៗ', issue.remarkHtml, rich: true)}
${row('ស្ថានភាព', status(issue.status))}
${row('ស្ថាប័នពាក់ព័ន្ធ', agencyOrders.map((order) => issue.governmentAgencies[order]!).join('\n'))}
</tbody></table></section>''';
  }).join();
  String signature(String role, String position, String name) =>
      '''<div class="signature">
<div class="lunar-date">-</div><div>ត្រូវនឹង <span class="gregorian-date">${_text(kh.date(date))}</span></div>
<div class="signature-role">${_text(role)}<br>${_text(position)}</div>
<div class="signature-name">${_text(name)}</div></div>''';
  final signatures = summary.participants
      .map(
        (person) => person.group == 'pswg'
            ? '${signature('អ្នកធ្វើរបាយការណ៍កិច្ចប្រជុំក្រុមការងារ\nកំណត់ហេតុកិច្ចប្រជុំ', person.reporterPosition, person.reporter)}${signature('អ្នកត្រួតពិនិត្យរបាយការណ៍កិច្ចប្រជុំ\nកំណត់ហេតុកិច្ចប្រជុំ', person.representativePosition, person.representative)}'
            : '${signature('អនុប្រធាន និងសហប្រធានក្រុមការងារតាមវិស័យផ្នែក $sector', person.reporterPosition, person.reporter)}${signature('សហប្រធានក្រុមការងារតាមវិស័យផ្នែក $sector', person.representativePosition, person.representative)}',
      )
      .join();
  return '''<!DOCTYPE html><html lang="km"><head><meta charset="utf-8">
<meta name="viewport" content="width=794, initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; font-src data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'">
<title>Meeting-Summary-${summary.id}</title><style>
@font-face{font-family:ReportBody;src:url(data:font/ttf;base64,$bodyFont)}
@font-face{font-family:ReportTitle;src:url(data:font/ttf;base64,$titleFont)}
@page{size:A4 portrait;margin:15mm 16mm}
*{box-sizing:border-box}body{margin:0;background:white;color:#0d0d0d;font:18px/1.65 ReportBody,serif}
header{text-align:center;margin-bottom:26px}.motto{font:30px/1.6 ReportTitle,serif;margin:0}
.ornament{margin:10px 0 22px;color:#717680}.logo-band{display:table;width:100%;table-layout:fixed}
.logo-cell{display:table-cell;width:95px;vertical-align:middle}.logo-cell img{width:88px;height:88px;object-fit:contain}
.heading{display:table-cell;vertical-align:middle;padding:0 8px}.title{font:22px/1.6 ReportTitle,serif;margin:0 0 6px}
.intro{text-align:center;margin:30px 0 22px}.issue{margin-bottom:24px}h3{font-size:18px;line-height:1.5;margin:8px 0 24px;break-after:avoid}
table{border-collapse:collapse;width:100%;table-layout:fixed}th,td{border:1px solid #acacac;padding:12px 14px;vertical-align:top;overflow-wrap:anywhere}
/* Keep both outer edges inside the printable box. Two-pixel rules survive
   Android's reduced-page preview, where a one-pixel edge can disappear. */
.issue-table{border-collapse:separate;border-spacing:0;width:calc(100% - 4px);margin-left:2px}
.issue-table>thead>tr>th,.issue-table>tbody>tr>td{border:0;border-right:2px solid #666;border-bottom:2px solid #666}
.issue-table>thead>tr>th:first-child,.issue-table>tbody>tr>td:first-child{border-left:2px solid #666}
.issue-table>thead>tr>th{border-top:2px solid #666}
.issue-table>thead>tr>th:first-child,.issue-table>tbody>tr>td:first-child{width:22%}
th{background:#ddedfb;text-align:left;font-weight:bold;print-color-adjust:exact;-webkit-print-color-adjust:exact}
thead{display:table-header-group}td p:first-child{margin-top:0}td p:last-child{margin-bottom:0}td p{margin:0 0 8px}
td h1,td h2,td h3,td h4,td h5,td h6{font: bold 18px/1.6 ReportBody;margin:8px 0}
td ul,td ol{padding-left:24px;margin:8px 0}pre{white-space:pre-wrap}blockquote{margin:8px 0;padding-left:16px;border-left:3px solid #ccc}
.signatures{margin-top:22mm;display:flex;flex-wrap:wrap;justify-content:space-between;gap:18mm 0;break-inside:avoid;page-break-inside:avoid}
.signature{width:44%;min-height:66mm;text-align:center;break-inside:avoid;page-break-inside:avoid}
.signature-role{margin-top:12mm;min-height:14mm;font-weight:bold;white-space:pre-line}.signature-name{margin-top:22mm;font-weight:bold}
@media screen{body{max-width:210mm;margin:auto;padding:15mm 16mm}}
</style></head><body>
<header><div class="motto">ព្រះរាជាណាចក្រកម្ពុជា</div><div class="motto">ជាតិសាសនា ព្រះមហាក្សត្រ</div>
<div class="ornament">────୨ৎ────</div><div class="logo-band">
<div class="logo-cell"><img src="data:image/png;base64,$agencyLogo" alt="ស្ថាប័នដឹកនាំ"></div>
<div class="heading"><h1 class="title">របាយការណ៍លទ្ធផលកិច្ចប្រជុំ</h1>
<div>ក្រុមការងារតាមវិស័យផ្នែក <b>${_value(sector)}</b></div><div>ទីកន្លែងប្រជុំ <b>${_value(summary.location)}</b></div>
<div class="gregorian-date">${_text(kh.date(date))}</div></div>
<div class="logo-cell"><img src="data:image/png;base64,$cdcLogo" alt="CDC"></div></div></header>
<p class="intro">របាយការណ៍លទ្ធផលកិច្ចប្រជុំ ${_value(sector)} ដែលបញ្ហាសរុបចំនួន ${kh.number(summary.issues.length)} ត្រូវបានពិភាក្សា និង សម្រេច មានខ្លឹមសារដូចខាងក្រោម៖</p>
$issues<div class="signatures">$signatures</div>
<script>$calendarScript
try { if ('$dateKey') {
 const d = MeetingCalendar.toKhmerLunarDate('$dateKey');
 document.querySelectorAll('.lunar-date').forEach(e => e.textContent = d.lunarDateText);
 document.querySelectorAll('.gregorian-date').forEach(e => e.textContent = d.gregorianDateText);
} } catch(e) { /* Keep the Gregorian date when conversion is unavailable. */ }
Promise.all([document.fonts.ready, ...Array.from(document.images).map(i => i.decode())])
 .then(() => { window.__meetingPrintReady = true; })
 .catch(() => { window.__meetingPrintFailed = true; });
</script></body></html>''';
}
