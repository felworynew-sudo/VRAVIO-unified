# VRAVIO на macOS

CI собирает универсальный пакет `VRAVIO_*.dmg` для Apple Silicon и Intel из тех же веб-ресурсов, что опубликованы на GitHub Pages. Файл находится в артефакте `vravio-macos-universal` успешного запуска [Build web](https://github.com/felworynew-sudo/VRAVIO-unified/actions/workflows/web.yml). В `src-tauri/tauri.macos.conf.json` включены формат DMG и ad-hoc подпись. Apple-нотарификация не настроена; macOS может попросить разрешить запуск в **Системные настройки → Конфиденциальность и безопасность**. Поведение на конкретном Mac требуется проверить после установки.

Для локальной сборки нужны Xcode Command Line Tools, Rust, Node.js и исходники подмодулей. В корне проекта:

```sh
git submodule update --init --recursive
rustup target add aarch64-apple-darwin x86_64-apple-darwin wasm32-unknown-unknown
npm ci
```

Полная сборка веб-ресурсов использует PowerShell 7, Trunk и `wasm-bindgen-cli` 0.2.129 (см. `README.md`). После неё:

```sh
npx tauri build --target universal-apple-darwin --bundles dmg
```

Для быстрой сборки локально можно скачать готовый артефакт `vravio-web-bundle` из того же запуска CI, распаковать его содержимое в `dist/` и выполнить только команду Tauri. Пакет содержит четыре редактора, модели реставрации и файлы лицензий. Пересылка одной лишь исходной папки без `dist/` не даёт готового приложения.
