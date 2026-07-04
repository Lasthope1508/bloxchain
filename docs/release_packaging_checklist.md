# BloxChain Release Packaging Checklist

- Project root: `C:\w\bloxchain-core`
- Godot console: `C:\Users\Admin\.gemini\antigravity\bin\Godot\Godot_v4.3-stable_win64_console.exe`
- Web preset: `Web`
- Android preset: `Android`
- Main scene: `res://Scenes/Main/Main.tscn`
- Runtime manifest: `docs/runtime_asset_manifest.json`
- Required reskin doctrine: `shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md`
- Asset optimization policy: `docs/mobile_html5_asset_optimization_checklist.md`
- Audio policy: `docs/audio_pipeline.md`
- VFX policy: `docs/fake3d_vfx_checklist.md`

## Required Reskin Reading

MUST READ BEFORE RESKIN: `shared/ShinokuteGameCore/docs/reskin_core_skin_boundary.md`.

Ownership rule: Core = behavior; Game skin = game-specific art; Function skin = game-specific presentation for a shared feature. BloxChain owns the block game skin, modal/function skin, board visuals, VFX style, layout, assets, fonts, copy, and export allowlist. `ShinokuteGameCore` owns reusable behavior contracts only.

No fallback: do not invent fallback assets, fallback config, fallback Firebase collection names, fallback score labels, or fallback publish paths unless owner explicitly approves that exact fallback.

## Current Pass Evidence

- Status: package-ready for current generated Web/AAB artifacts.
- Godot MCP/editor evidence: `get_project_info` confirmed project `BloxChain`, path `C:\w\bloxchain-core`, Godot `4.3.stable.official.77dcf97d8`.
- Tests: full sweep `3/3 pass` (`test_bloxchain_game_core_config_contract.gd`, `test_export_packaging_contract.gd`, `test_shared_core_reskin_contract.gd`).
- Import pass: `Godot_v4.3-stable_win64_console.exe --headless --path "C:\w\bloxchain-core" --import`; exit `0`.
- Export preset fix: removed missing `res://icon.png` from selected resources and set `config/icon="res://Assets/Sprites/bloxchain_logo.png"` to keep export logs clean.
- Web export: `Godot_v4.3-stable_win64_console.exe --headless --path "C:\w\bloxchain-core" --export-release Web "Export\bloxchain.html"`; exit `0`.
- Android export: `Godot_v4.3-stable_win64_console.exe --headless --path "C:\w\bloxchain-core" --install-android-build-template --export-release Android "Export\bloxchain.aab"`; exit `0`. Gradle daemon may keep the wrapper alive after `export: end`; stop it with `android\build\gradlew.bat --stop` under the configured JDK.
- Generated artifacts:
  - `Export/bloxchain.html`: 4,873 bytes.
  - `Export/bloxchain.js`: 331,495 bytes.
  - `Export/bloxchain.wasm`: 35,376,909 bytes.
  - `Export/bloxchain.pck`: 7,024,736 bytes (6.70 MB).
  - `Export/bloxchain.aab`: 52,917,968 bytes (50.47 MB).
- Forbidden scan: `godot_publish_audit.ps1` passed for `Export\bloxchain.pck` and `Export\bloxchain.aab`; forbidden markers clean for `debug/`, `Tests/`, `docs/`, `scratch/`, `.claude/`, `.agents/`, `.bak`, `_raw.png`, `Export/`.
- Android signing/package check: JDK `jarsigner.exe -verify -certs Export\bloxchain.aab` returned `jar verified.` with exit `0`. AAB entries include `base/manifest/AndroidManifest.xml`, `installTime/assets/project.binary`, gameplay scripts, main scene scripts, and `ThemeManager.gdc`.
- Web gameplay smoke: served `Export/` from `http://127.0.0.1:49411`, opened `bloxchain.html?v=build-20260704`. Browser path: main menu -> `Play` -> `Classic Start (Empty Grid)` -> gameplay tutorial board -> dragged tutorial piece into board. Visible state changed after drag. Browser console errors/warnings: `[]`.
- Budget comparison:
  - Web PCK: 6.70 MB / 80 MB: pass.
  - Android AAB: 50.47 MB / 140 MB: pass.
  - Texture source total: 8.53 MB / 80 MB: pass.
  - BGM source total: 2.50 MB / 12 MB: pass.
  - SFX source total: 1.32 MB / 20 MB: pass.
  - VFX source total: 4.83 MB / 10 MB: pass.
  - Largest texture source: `res://Assets/Sprites/greeting_bg.png`, 0.43 MB / 6 MB: pass.
- Notes: Web smoke used `Classic Start` because this game has mode selection instead of a `Level 1` button.
- Blockers: none for current package gates.
