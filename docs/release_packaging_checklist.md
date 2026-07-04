# BloxChain Release Packaging Checklist

- Project root: `C:\Users\Admin\Desktop\Game`
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
- Godot MCP/editor evidence: `get_project_info` confirmed project `BloxChain`, path `C:\Users\Admin\Desktop\Game`, Godot `4.3.stable.official.77dcf97d8`.
- Tests: full sweep found 1 test, `res://Tests/test_export_packaging_contract.gd`; passed with `test_export_packaging_contract: PASS`.
- Import pass: `Godot_v4.3-stable_win64_console.exe --import --quit --path "C:\Users\Admin\Desktop\Game" --verbose`; exit `0`. Initial missing imported-resource warnings occurred before import completed after cache clear; import then generated `.godot/imported`. Remaining warning: invalid scene UIDs fell back to text paths.
- Web export: `Godot_v4.3-stable_win64_console.exe --headless --path "C:\Users\Admin\Desktop\Game" --export-release Web "Export/bloxchain.html"`; exit `0`.
- Android export: `Godot_v4.3-stable_win64_console.exe --headless --path "C:\Users\Admin\Desktop\Game" --export-release Android "Export/bloxchain.aab"`; emitted `export: end`, artifact copied, Gradle daemon stopped with configured JDK, wrapper exit `0`.
- Generated artifacts:
  - `Export/bloxchain.html`: 4,873 bytes.
  - `Export/bloxchain.js`: 331,495 bytes.
  - `Export/bloxchain.wasm`: 35,376,909 bytes.
  - `Export/bloxchain.pck`: 7,189,152 bytes (6.86 MB).
  - `Export/bloxchain.aab`: 53,337,414 bytes (50.87 MB).
- Forbidden scan: `godot_publish_audit.ps1` passed for `Export\bloxchain.pck` and `Export\bloxchain.aab`; forbidden markers clean for `debug/`, `Tests/`, `docs/`, `scratch/`, `.claude/`, `.agents/`, `.bak`, `_raw.png`, `Export/`.
- Android signing/package check: JDK `jarsigner.exe -verify -certs Export\bloxchain.aab` returned `jar verified.` with exit `0`. AAB entries include `base/manifest/AndroidManifest.xml`, `installTime/assets/project.binary`, gameplay scripts, main scene scripts, and `ThemeManager.gdc`.
- Web gameplay smoke: served `Export/` from `http://127.0.0.1:8063` with `Cache-Control: no-store, no-cache, must-revalidate` and opened `bloxchain.html?ts=20260703T1853`. Browser path: main menu -> `Play` -> `Classic Start (Empty Grid)` -> gameplay tutorial board -> dragged tutorial piece into board. Visible state changed: score `5`, chain energy `74/100`, combo/clear logs emitted. Browser console after interaction: `Total messages: 12 (Errors: 0, Warnings: 0)`.
- Budget comparison:
  - Web PCK: 6.86 MB / 80 MB: pass.
  - Android AAB: 50.87 MB / 140 MB: pass.
  - Texture source total: 8.53 MB / 80 MB: pass.
  - BGM source total: 2.50 MB / 12 MB: pass.
  - SFX source total: 1.32 MB / 20 MB: pass.
  - VFX source total: 4.83 MB / 10 MB: pass.
  - Largest texture source: `res://Assets/Sprites/greeting_bg.png`, 0.43 MB / 6 MB: pass.
- Notes: Web smoke used `Classic Start` because this game has mode selection instead of a `Level 1` button.
- Blockers: none for current package gates.
