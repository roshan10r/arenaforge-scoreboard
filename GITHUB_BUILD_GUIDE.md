# GitHub APK Build Guide

## 1) GitHub par repo banao
- GitHub open karo
- New repository banao
- Name: `arenaforge-scoreboard`
- Public ya Private rakh sakte ho

## 2) Is ZIP ke andar wali files upload karo
Dhyan rahe: ZIP ke andar jo `arenaforge_scoreboard` folder hai, uske andar ki files repo root me upload honi chahiye.

Repo me yeh file visible honi chahiye:

```text
.github/workflows/build-apk.yml
pubspec.yaml
lib/main.dart
android/app/build.gradle
```

## 3) APK build run karo
- GitHub repo me `Actions` tab open karo
- `Build ArenaForge APK` workflow select karo
- `Run workflow` dabao

## 4) APK download karo
Workflow complete hone ke baad bottom me `Artifacts` section dikhega:

- `ArenaForge-release-apk` = phone me install/test karne ke liye APK
- `ArenaForge-playstore-aab` = Play Store upload ke liye AAB

## Important
Play Store final upload ke liye release signing zaroori hoti hai. GitHub workflow abhi unsigned/basic release artifact banata hai. Play Console me upload karne ke liye app signing setup ke baad signed AAB generate karna best rahega.
