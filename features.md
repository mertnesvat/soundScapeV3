---
base_branch: master
max_retries: 2
continue_on_failure: false
visual_gate_enabled: false
bundle_id: com.StudioNext.SoundScape
action_logging: true

# Deep Quality Mode - Critical for accurate translations
deep_quality_mode: true
deep_quality_max_retries: 5
deep_quality_review_gate: true
---

# Feature Queue: SoundScape Localization

Localize SoundScape to 4 new languages. Each language is a separate feature with its own commit.

**Target Languages:**
- Latin American Spanish (es-419)
- Brazilian Portuguese (pt-BR)
- Vietnamese (vi)
- Thai (th)

---

### 1. Set Up Localization Infrastructure

Create the localization system for the app. Currently all strings are hardcoded in English.

**User Story:** As a developer, I want a localization system so translations can be added.

**Acceptance Criteria:**
- Create Xcode String Catalog (Localizable.xcstrings) with English as base
- Update all SwiftUI views to use localized strings instead of hardcoded text
- Target screens: Onboarding (10 screens), all 8 tabs, Settings, Now Playing bar
- App builds and displays English correctly after refactoring
- Commit: "🌐 Set up localization infrastructure with English base"

**Priority:** 1
**Dependencies:** None

---

### 2. Localize to Latin American Spanish (es-419)

Translate the entire app to Latin American Spanish.

**User Story:** As a Spanish-speaking user in Latin America, I want to use SoundScape in my language.

**Acceptance Criteria:**
- Add es-419 locale to String Catalog
- Translate all strings using Latin American vocabulary (not Castilian)
- All screens display correctly in Spanish
- App builds without crashes
- Commit: "🌍 Add Latin American Spanish (es-419) localization"

**Priority:** 2
**Dependencies:** 1

---

### 3. Localize to Brazilian Portuguese (pt-BR)

Translate the entire app to Brazilian Portuguese.

**User Story:** As a Portuguese-speaking user in Brazil, I want to use SoundScape in my language.

**Acceptance Criteria:**
- Add pt-BR locale to String Catalog
- Translate all strings using Brazilian vocabulary (not European Portuguese)
- All screens display correctly in Portuguese
- App builds without crashes
- Commit: "🌍 Add Brazilian Portuguese (pt-BR) localization"

**Priority:** 3
**Dependencies:** 2

---

### 4. Localize to Vietnamese (vi)

Translate the entire app to Vietnamese.

**User Story:** As a Vietnamese-speaking user, I want to use SoundScape in my language.

**Acceptance Criteria:**
- Add vi locale to String Catalog
- Translate all strings with proper Vietnamese diacritics
- All screens display correctly in Vietnamese
- App builds without crashes
- Commit: "🌍 Add Vietnamese (vi) localization"

**Priority:** 4
**Dependencies:** 3

---

### 5. Localize to Thai (th)

Translate the entire app to Thai.

**User Story:** As a Thai-speaking user, I want to use SoundScape in my language.

**Acceptance Criteria:**
- Add th locale to String Catalog
- Translate all strings in Thai script
- All screens display correctly in Thai
- App builds without crashes
- Commit: "🌍 Add Thai (th) localization"

**Priority:** 5
**Dependencies:** 4

---

## Notes

**Do NOT translate:**
- "SoundScape" (app name)
- "Studio Next" (company name)
- Hz values, version numbers, URLs

**Key screens to localize:**
- Onboarding flow (Welcome, Quiz, Results, Pain Points, Benefits, Reviews, Features, Plan)
- Sounds tab (library, categories, sound names)
- Mixer, Timer, Saved Mixes sheets
- Favorites, Alarms, Binaural Beats tabs
- Wind Down, Discover, Adaptive, Insights tabs
- Settings view
- Now Playing bar
