# API coding standard

## Where code belongs

- `lib/core/network/`: shared HTTP transport, base URL, cookies, timeout, JSON envelope validation, and `ApiException`.
- `lib/features/<feature>/data/`: endpoint repositories and typed models.
- Screens: invoke repositories, show loading/error states, and render models. Never embed URLs, credentials, HTTP calls, or JSON parsing in widgets.
- `dashboard/data/filter_options.dart`: current local filter options. `filter_sheet.dart` accepts groups supplied by its caller and edits a separate draft.

## Configuration

The default backend is the staging URL supplied in the screenshots. Override it with:

```sh
flutter run --dart-define=API_BASE_URL=https://your-host/api/v1
```

Always use HTTPS outside local testing. Keep endpoints relative (`auth/me`, without a leading slash). GET query values belong in the `query` argument, not string concatenation.

```dart
final data = await api.get('auth/me');
final user = AuthUser.fromJson(data['user'] as Map<String, dynamic>);
```

The client expects `{ "success": true, "data": { ... } }`. Add explicit response handling for list/paginated endpoints when their contract is available. Repositories convert `data` into models and expose domain methods such as `getCurrentUser()`.

## Authentication and sessions

`AuthRepository.login()` posts the entered credentials and then fetches `/auth/me`. The native client captures the server's `accessToken` Set-Cookie and reuses it for the same API origin. It does not follow redirects. Cookies remain in memory and are cleared on local logout or failed login. No screenshot credentials or tokens are embedded in code. Restarting the app requires signing in again.

Web uses browser-managed cookies with credentials enabled. The backend must allow the web origin with credentialed CORS and suitable cookie attributes. JavaScript cannot clear HttpOnly cookies: a backend logout endpoint is required to invalidate the web session and revoke native sessions on the server. `POST auth/logout` is now called before app state is cleared. A 401 means the session already expired; other failures keep the dialog open for retry.

The verified user is stored in `AppSettingsController.currentUser`. Module selection now uses `user.roles[].name`, not email or position. The centralized mapping in `core/config/role_modules.dart` recognizes `line_ministry`, `private_sector`, `cdc_section`, `cdc_secretariat`, and `cefp`; spaces/hyphens and case are normalized. `pswg` is also accepted as a Private Sector display alias. `admin` defaults to CDC Secretariat only when no recognized module-specific role exists. Multiple roles use the documented mapping order; unsupported roles cannot open a dashboard. Server permissions must still enforce access.

`POST auth/forgot-password` sends `{email}`. The next screen collects OTP, new password, and password confirmation. `POST auth/reset-password` sends `{email, otp, newPassword}`; confirmation stays on the device. Success returns to login. Action endpoints accept a success envelope without `data`, or an empty successful HTTP response. Password policy and OTP expiry remain enforced by the backend.

Fresh app sessions default to Khmer and light mode. Users can still change language and theme in settings.

## UI and validation

Disable duplicate submissions, show a loading indicator, handle `ApiException`, check `mounted` after awaits, and dispose controllers. Never log passwords, cookies, or full authentication responses. Test repository requests with `MockClient`; test cookie transport against a local server without real credentials.

The screenshots do not specify filter endpoints, identifiers, or response formats. Local filter choices remain operational. Once that contract is supplied, add a filter repository/model, load it in the owning screen with retry/loading states, and pass its groups to the sheet. Use backend IDs for selections when supported by the dashboard API.

## Working Group dashboard data

All modules use the same authenticated `GET dashboards/pswg/live` endpoint when opening their Working Group dashboard or breakdown tab. `PswgDataLoader` supplies a typed response to the existing UI through `PswgDataScope`. Existing metric cards, tabs, agency charts, category tracks, and Working Group rows retain their original layout and styling. The Private Sector/CEFP and CDC Section top-level Working Group scopes use the full response; Line Ministry and CDC Secretariat fetch it when opening their Working Group breakdown.

The loader fetches once per mount, shares the result between existing widgets, and supports retry after a failed request. Zero counts remain zero and nullable optional progress values do not become demo numbers. The API has not supplied filter query parameters, so this change does not invent a filter request contract.

## Plenary dashboard data

The existing top-level Plenary selectors (Private Sector, CEFP and CDC Section) request `GET dashboards/plenary/live`. `DashboardScope` selects the endpoint; both endpoints reuse the same typed cards/breakdown model. Changing the top-level scope reloads the data, while switching Overall, Agencies, Working Group, or Categories within that scope reuses the same response. A Working Group breakdown within Plenary stays on the Plenary dataset. Existing layout and styling are unchanged. The Plenary fixture uses the screenshot's card values with representative breakdown rows for regression coverage.

## WG Issues summary cards

`IssuesRepository.getMyWorkingGroupSummary()` calls `GET working-group-issues/summary/my` through the authenticated client. Its typed model preserves the five counters exactly as supplied, even when status counts do not add up to `totalIssues`. The existing WG Issues metric cards across all roles display these values; the existing Line Ministry primary-agency card also uses the response. The loader stays inside the summary area so navigation remains usable during loading or errors, and reloads when returning to WG Issues. Issues Matrix and issue list/detail records are not populated by this summary endpoint. No filters are sent without a documented query contract.

## WG Issues list

`IssuesRepository.getMyWorkingGroupIssues()` calls `GET working-group-issues/my` and parses `data.items`. The existing cards below the WG Issues summary iterate the returned records in API order with stable issue IDs. The list handles loading, empty results, and retry without demo fallbacks. The Private Sector search field filters the loaded records locally without repeating the request. This implements the returned `items` list; no pagination parameters or metadata contract was supplied.

HTML descriptions and recommendations are parsed to plain text with paragraph boundaries and decoded entities. Script/style content is excluded. JSON is decoded as UTF-8, including when a server omits its charset. Nullable relations show missing-value placeholders, unknown status names are retained, and links shared between direct and linked meetings are counted once. The original card layouts remain in use across roles.

Opening a live card passes the selected issue to the existing detail screen, including its description and recommendation. The supplied list response has no progress-report records, so live details show an unavailable-data message instead of demo reports. Attachment counts are derived from returned metadata; downloading documents is not added by this list integration.

## Meeting Requests

`MeetingRequestsRepository.getRequests()` uses the shared authenticated client's `GET meeting-requests`. This endpoint returns an array directly in `data`; `ApiClient.getList` validates that envelope separately from object responses. Each role's Meeting Requests tab iterates this array using stable request IDs and its existing card layout. CEFP and CDC Section route to the concrete meeting screen rather than recursively calling the role dispatcher.

Cards display the returned title, submitter's working groups, meeting date, `issuesCount`, status (including Scheduled), and a deduplicated count of request-letter and meeting-reference paths. Null dates stay blank placeholders, empty responses show an empty state, and failures offer retry. Opening a request passes its record to the request detail view; description, submitter, agencies, document metadata, and the All Issues tab use that record. Nested issue attachments accept string paths as well as the object form used by the WG Issues endpoint. HTML is converted to readable text. No mutation, document-download, pagination, or server-filter endpoints are inferred from this response.
