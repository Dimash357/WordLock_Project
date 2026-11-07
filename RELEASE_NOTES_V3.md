# WordLock v3 — developer handoff

## Implemented in this ZIP
- Stable UUID word IDs, legacy string-ID decoding, and one-time migration of learned words.
- Tombstones for deleted defaults; restore defaults and reset progress require confirmation.
- Five-box spaced repetition (1/3/7/14/30 days) and due-first candidate priority.
- Deterministic shuffled order and selectable decks; new words can have example and phonetic fields.
- Card training, multiple-choice quiz, offline English TTS (US on cards, UK in dictionary).
- Today screen with totals and seven-day activity; full-bleed background.
- Interactive lock-screen widget: reveal, knew, didn't know; circular progress symbol; home screen small/medium families.
- One dictionary load per timeline, refresh when app becomes active, onboarding, basic CSV import/export.
- Generated Launch Screen setting in Xcode project.

## NOT implemented / important limitations
- **No iOS build or real-device test was possible** in this Linux environment. Xcode compilation, signing, App Store review and widget interaction MUST be verified on a Mac/iPhone.
- No iCloud/CloudKit, Share Extension, Control Center/Action Button, Siri shortcuts, Apple Translation integration, notifications, Anki import, advanced swipe gestures, or fully localized UI yet.
- Existing 500-word source lacks genuine CEFR tags, IPA and example sentences; no invented data was added.
- CSV import/export is basic; CSV with multiline quoted fields is not supported; Anki package import is not supported.
- WidgetKit scheduling is best-effort; widget refresh frequency is controlled by iOS.
- The widget reveal/response flow may be affected by iPhone authentication policy and system refresh budget; test on locked hardware.
- App Group entitlement and signing must be configured on the developer's team for both targets.
- Check migration and data backups before shipping an update to existing users.

## Installation
1. Unzip; open `WordLock.xcodeproj` in Xcode 15+ on macOS.
2. Choose signing team for WordLock and WordLockWidgetExtension, and configure App Group `group.com.dimash.wordlock` on both.
3. Clean Build Folder, compile, run on a physical iPhone (iOS 17+).
4. Test lock-screen widget with phone locked, check progress persistence and delete/restore behavior.
5. Do not delete the installed app before updating if you want to preserve local data.

## Pre-App Store QA
- Test clean install and upgrade from v2 with existing learned words.
- Test iPhone full-screen layout, Dynamic Type, VoiceOver and all widget sizes.
- Test CSV round-trip including commas and quotation marks; avoid multiline examples.
- Verify code signing, app icon, launch screen, privacy policy, screenshots and App Store Connect metadata.
