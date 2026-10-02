# Filter API audit — 2026-10-01

Verified against the supplied endpoint contracts and the local backend in `D:/DCx_Project_MIS/GPSF-MIS/backend/src/modules`. No live authenticated staging requests or backend edits were made.

## UI and shared implementation

`AppFilterSheet` retains the original centered Filters heading, right close button, divider, compact checkboxes, per-section columns, View All, scroll area, and pinned blue Apply footer. The extra Clear all header button was removed. Each screen imports the shared renderer and supplies its own catalog/configuration. Close discards draft edits; unchecking and Apply removes a filter.

Original configurations restored include RGC's six sections (Plenary, Status, Working Group, Primary Agency, Measure Category, Date of Decision), CDC Issues' five sections (Category, Status, All PSWGs, Year, Plenary Escalation), PSWG Issues' Year/Status/Primary Agency/Progress Report, dashboard working-group/agency/status/period sections, and the different request/calendar/summary sections. Options come from scoped facets, lookups, complete list pages, or published dashboard rows. Fixed labels such as Yes/No, Both and valid status buckets are domain choices, not sample records.

Each `ModuleRepositories` owns its API client and `FilterCatalogRepository`; PSWG, Ministry, CDC Section, CEFP and CDC GPSF reuse the UI without sharing another module's transport. `ApiFilterScope` carries both server queries and local selections to composed loaders. Query changes reload and reset pagination. RGC ignores stale responses. Catalog failures show retry without substituting sample values.

## Filtering behavior

| Feature | Server request | Additional filtering on API data |
| --- | --- | --- |
| WG Issues / Issue Matrix | `/working-group-issues/my` or `/issue-matrix`: `categoryIds`, `issueStatusIds`, `primaryAgencyIds`, `years` | CDC PSWG names; PSWG semester uses scoped issue detail progressReports (bounded concurrent requests) |
| CDC Issues | `/issues`: `page`, `limit` only | Category, status, PSWG, year across every API page |
| RGC | `/rgc-decisions`, or `/rgc-decisions/cdc-gpsf` for CDC GPSF: scalar `plenaryId`, `status`, `stakeholderId`, `categoryId` | Working-group relation names and decision date across all matching pages |
| Progress Reports | `/progress-reports`: scalar `year`, `semester`, `status` | None |
| Plenary reports | `/plenaries`: `statuses`, `ministryIds` | None |
| Meeting Requests | `/meeting-requests`: `page`, `limit`, optional `search` | Working-group/agency/status/date, Ministry year and issue count |
| Calendar | `/meetings`: scalar `status` | Working-group/agency/year/date/issue count |
| Meeting Summaries | `/meeting-summaries`: `page`, `limit`, optional `search` | Status/year/issue count |
| Dashboards | `/dashboards/{scope}/saved` and selected `/progress-reports/{id}/dashboards/{scope}/final`, otherwise `/live` | Status columns and corresponding working-group/agency chart rows |

Scalar query parameters use a single checked choice; array parameters use comma-separated IDs. `local.` keys never go into API queries. Multiple local sections combine with AND; choices within a section combine with OR. Working-group names are never sent as `stakeholderId` (that backend field refers to agency assignment). Relation names containing commas remain intact. Dates use Cambodia's UTC+7 calendar date; absent dates use one explicit unspecified value.

RGC filters use all historical `/plenaries` pages, not the creation-only plenary lookup which excludes expired plenaries. CDC GPSF uses its dedicated list route. Request/CDC/WG paging respects the backend limit of 50; other lists use 100.

## Remaining API limitations

- Plenary Escalation has no query parameter and current records do not expose an explicit escalation flag. Yes/No remain visible but disabled; unknown is not treated as No. CDC records exposing a boolean flag can enable local matching.
- Published dashboard responses contain separate aggregated breakdowns, not joint records. Working-group and agency choices affect their corresponding charts; status selects chart count columns. Published overall cards remain unchanged. These cannot be combined into a correct joint filtered total from marginal counts. A filtered aggregation endpoint is needed for that behavior. Year selects the newest available published semester in that year; selecting an explicit report replaces the year choice.
- Ministry `/my` and `/my/filter-options` remain dependent on backend ownership rules requiring a Private Sector stakeholder. No Ministry-owned issue list/facet contract was supplied. This requires backend support; the app does not broaden the user's ownership scope to bypass it.
- Local filtering can require downloading all matching pages. A future server filter contract would reduce that transfer. No unsupported query is sent as if it worked.
- Global Issue summary controllers have no list filter parameters; summary metrics continue to show server totals.

## Validation

Mock API and widget tests cover module transport isolation, supported query IDs/codes, same filters on later pages, Apply/uncheck/Close, retry, historical RGC dates, CDC GPSF route, original section order/columns, separate relation names, UTC+7 dates, semester detail hydration, and saved dashboard year/report selection.

The full suite previously reproduced six existing failures in an isolated HEAD archive: CDC Section/CEFP/CDC GPSF expectations in `issues_list_test.dart` and `issues_summary_test.dart`. Final full run: 119 passed, the same six pre-existing failures. Analyzer: no compilation errors and seven pre-existing warnings/lints; passing mock tests do not establish staging availability.
