# ArenaForge Scoreboard

Original Flutter esports points-table app for BGMI/Free Fire style tournaments.

## Features
- Separate BGMI and Free Fire spaces
- Create unlimited tournaments and matches
- Add teams with optional logo upload
- Easy calculation: rank points + kill points = total
- Editable presets/templates: 30 BGMI + 30 Free Fire names included in code
- Leaderboard, MVP/top fragger, match list
- Poster/certificate style preview and share screenshot
- Dark professional gaming UI

## Build
```bash
flutter pub get
flutter build appbundle --release
```
Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console after signing.

## Play Store Notes
- Android target SDK configured for API 35 in `android/app/build.gradle`.
- App uses image picker only for team logos.
- No real game characters or copyrighted game assets are included.

## GitHub Auto Build
This project includes GitHub Actions workflow:

```text
.github/workflows/build-apk.yml
```

Push/upload the project to GitHub, then open **Actions → Build ArenaForge APK → Run workflow**.

Artifacts generated:
- `ArenaForge-release-apk`
- `ArenaForge-playstore-aab`

See `GITHUB_BUILD_GUIDE.md` for step-by-step instructions.
