# Smartphone Handy App

## Folder Responsibilities

- `lib/main.dart` starts the Flutter app.
- `lib/app.dart` contains the root app widget.
- `lib/core/constants` contains routes, theme, feature flags, and shared keys.
- `lib/core/services` contains API services, storage service, routing, dependency setup, export, mail, device, feedback, and OCR service wiring.
- `lib/core/utils` contains shared helpers, settings, localization, base classes, and value utilities.
- `lib/core/widgets` contains common reusable widgets used by multiple features.
- `lib/data/models` contains API models and app data models.
- `lib/data/local` contains local data implementations, SQLite, local OCR source, and local repository implementations.
- `lib/features` contains feature-first UI, BLoC, and widgets.

## Feature Responsibilities

- `lib/features/auth` contains device/code verification UI, auth BLoC, auth widgets, and auth use cases.
- `lib/features/main_menu` contains the home page, main menu page, menu item model, and menu card widget.
- `lib/features/receiving` contains slip/order scan, product scan, BR/QR scan, OCR scan, scanner widgets, receiving BLoC, and receiving use cases.
- `lib/features/saved_files` contains saved files page and saved file view/delete/send use cases.
- `lib/features/settings` contains initial settings page, export/email settings UI, settings BLoC, and settings widgets.

## APIs And Services

- API client: `lib/core/api_services/api_client.dart`
- Auth service: `lib/core/api_services/auth_service.dart`
- Send Mail API service: `lib/core/api_services/send_mail_service.dart`
- Export service: `lib/core/services/export_service.dart`
- Device info service: `lib/core/services/device_info_service.dart`
- Storage service: `lib/core/services/storage_service.dart`

## BLoCs

- Auth BLoC: `lib/features/auth/bloc`
- Receiving and scanner BLoCs: `lib/features/receiving/bloc`
- Settings BLoC: `lib/features/settings/bloc`
- Empty feature BLoC folders are kept for future feature state management.

## Widgets

- Common reusable widgets: `lib/core/widgets`
- Auth widgets: `lib/features/auth/widgets`
- Main menu widgets: `lib/features/main_menu/widgets`
- Receiving and scanner widgets: `lib/features/receiving/widgets`
- Settings widgets: `lib/features/settings/widgets`

## Local Storage

- Shared preferences wrapper: `lib/core/services/storage_service.dart`
- SQLite receiving storage: `lib/data/local/receiving_sqlite_data_source.dart`
- Local repository services: `lib/data/local`
