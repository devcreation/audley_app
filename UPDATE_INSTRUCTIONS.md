# Update Instructions — Remove All Hardcoded Content

## Summary
All hardcoded text, form fields, labels, options, images, and content in the Flutter app
now come from the website's API. Nothing is hardcoded in the app.

---

## Backend Changes (2 files)

### 1. `api/content.php` — Enhanced `get_app_config`
- **`get_app_config`** (no auth required) now returns:
  - `event` — event name, badge, subtitle, dates, hero_image
  - `logo_url` — absolute URL to the logo image
  - `sponsors` — sponsor logos
  - `ui` — UI strings for all screens:
    - `login_subtitle`, `register_subtitle`
    - `section_updates`, `section_partners`
    - `section_emergency`, `section_contacts`, `section_hotels`
    - `tab_hotels`, `tab_fleet`, `tab_faq`

### 2. `api/forms.php` — Enhanced `get_form_config`
- Now includes `participant_form` with full field definitions:
  - Each field has: `key`, `label`, `type`, `placeholder`, `required`, `options`
  - Supports: `text`, `date`, `email`, `phone`, `textarea`, `dropdown`, `chips`, `header`
  - Conditional visibility via `show_when` (e.g. kurta/pajama only for Male)
  - Dynamic Q-numbering via `label_prefix_male` / `label_prefix_female`
  - "Other" text field support via `has_other`, `other_key`
  - Dropdown options include size measurements from website (e.g. `S (37.8" - 40.2")`)
- `tours_form` with title, description, button labels
- `confirmation` with all confirmation/locked panel strings
- `tabs` with tab labels
- Seat limits from `$TOUR_LIMITS` (already on server, NOT hardcoded in app)

---

## App Changes (8 files)

### 1. `lib/data/api_client.dart`
- Added `getAppConfig()` — fetches branding without auth

### 2. `lib/data/models/models.dart`
- Added `AppConfig` model with `event`, `logoUrl`, `ui` strings
- `uiString(key, fallback)` helper for safe access

### 3. `lib/providers/providers.dart`
- Added `appConfigProvider` — `FutureProvider<AppConfig?>` (no auth)
- Used by login, register, home, more screens

### 4. `lib/main.dart`
- No structural change; `appConfigProvider` auto-fetches when login screen watches it

### 5. `lib/screens/auth/login_screen.dart`
- Event name, subtitle, badge → from `appConfigProvider`
- Logo → `CachedNetworkImage` from `config.logoUrl` with bundled fallback
- Login subtitle → from `config.uiString('login_subtitle')`

### 6. `lib/screens/auth/register_screen.dart`
- Subtitle → from `config.uiString('register_subtitle')`

### 7. `lib/screens/forms/forms_screen.dart` (major rewrite)
- **Participant form is now 100% dynamic:**
  - Reads field definitions from `config['participant_form']['fields']`
  - Dynamic form builder renders text/dropdown/chips/date/header fields
  - Conditional visibility (`show_when`) for gender-specific clothing fields
  - Dynamic Q-numbering based on gender
  - Labels, placeholders, options, certification text — all from API
- **Tours form** — title, description, button labels from API
- **Tab labels** — from `config['tabs']`
- **Confirmation/locked panels** — all strings from `config['confirmation']`

### 8. `lib/screens/home/home_screen.dart`
- "Trip Updates" → from `config.uiString('section_updates')`
- "Our Partners" → from `config.uiString('section_partners')`

### 9. `lib/screens/more/more_screen.dart`
- "Emergency Helpline" → from `config.uiString('section_emergency')`
- "Contact Directory" → from `config.uiString('section_contacts')`
- "Hotel Contacts" → from `config.uiString('section_hotels')`

---

## Deployment Steps

1. **Backend**: Replace `api/content.php` and `api/forms.php` on the server
2. **App**: Replace the listed files in the Flutter project
3. **Test**: Verify login shows branding from API, forms render dynamically

## What Changed vs What Stayed

| Item | Before | After |
|------|--------|-------|
| Event name on login | Hardcoded | From API |
| Form field labels | Hardcoded Q1-Q20 | From `get_form_config` |
| Meal options | Hardcoded array | From API |
| Clothing sizes | Hardcoded S/M/L/XL | From API with measurements |
| Tour seat limits | From API (already) | From API (unchanged) |
| Section titles | Hardcoded strings | From `get_app_config` UI strings |
| Logo | Bundled asset only | Network + bundled fallback |
| Confirmation text | Hardcoded | From API |
