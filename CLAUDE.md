# Gang Roh — catatan untuk Claude

Baca file ini dulu; jangan menjelajahi seluruh proyek kecuali perlu. Desain lengkap: `docs/GDD.md`.

## Ringkas
Game pixel art side-scroller (Godot 4.7.2, GDScript, renderer GL Compatibility) untuk PC, Web, dan Android,
portrait maupun landscape. Pemain = roh penjaga gang (prototipe: Maneki-neko). Kumpulkan koin persembahan,
tanam di titik bangun → bangunan tumbuh lantai demi lantai. 1 hari game = 1 bulan manusia. Sesi pendek 12 bulan.
Pemilik proyek berbahasa Indonesia, pemula Godot/GitHub: jelaskan singkat dan sederhana.

## Alur kerja
- Repo: github.com/onicoode/gang-roh (publik). Folder lokal di PC: `D:\CodeProject\Sandbox\gang-roh`.
- Push ke `main` → GitHub Actions (`.github/workflows/build.yml`): smoke test script, export Web + APK,
  deploy ke GitHub Pages: https://onicoode.github.io/gang-roh/ (APK: /gang-roh.apk).
- Sesi cloud (dari HP) tidak punya Godot: andalkan CI untuk cek error. Setelah push, cek hasil Actions.
- Hemat usage: kerjakan satu fitur per sesi, jangan baca file yang tidak relevan, jangan generate ulang sprite tanpa perlu.

## Aturan GDScript (Godot 4.7 menganggap warning ini sebagai error)
- Jangan `var x := a if cond else b` → tulis tipe eksplisit: `var x: float = a if cond else b`.
- Jangan `:=` dari nilai Variant (hasil `get_node()` tanpa cast, elemen Array/Dictionary tanpa tipe).
- Komentar dan teks UI dalam Bahasa Indonesia.

## Struktur
| Path | Isi |
|---|---|
| `scenes/main.tscn` + `scripts/main.gd` | SubViewport pixel-perfect (sisi terpendek ≈180 px game), HUD, tombol sentuh, panel akhir sesi |
| `scenes/world.tscn` + `scripts/world.gd` | Gang: petak, kuil, siklus hari/bulan, warna langit, parallax, spawn koin |
| `scripts/building.gd` | Satu petak: lantai, biaya, konstruksi, sprite toko/apartemen/atap/tangga, slot koin |
| `scripts/cat.gd` | Pemain: state GROUND/CLIMB/ROOF, tanam koin (tahan aksi), Lambaian Rezeki |
| `scripts/coin.gd` | Koin memantul + dipungut |
| `shaders/` | `sky` (gradasi), `wind` (goyang jemuran/tanaman) |
| `tools/gen_sprites.py` | Generator sprite placeholder (Python murni). `python tools/gen_sprites.py` |

## Ukuran sprite (kalau diganti buatan sendiri)
- `cat.png` 12 frame 16×16: 0-3 diam, 4-7 jalan, 8-9 memanjat, 10-11 melambai (menghadap kanan).
- `shop.png` / `apt.png` (+ `_lights`): 3 gaya × 48×32. `roof.png` 3 × 48×10. `ladder.png` 6×32 (diulang).

## Tes lokal (PC)
- Error check: `Godot_console.exe --headless --path . --quit-after 300 -- --demo`
- Argumen debug: `-- --demo` (gedung acak bertingkat), `--time=0.8` (jam: 0 pagi … 0.75 malam).

## Status (update di akhir tiap sesi)
- v0.1 prototipe: jalan, tangga, atap, koin, bangun 0→5 lantai, siang/malam, lampu, AC, jemuran, awan,
  kontrol sentuh, layout portrait/landscape, ringkasan akhir sesi.
- Belum: developer rakus, bangunan menua, bencana, roh lain (Tanuki, Komainu), Ema/upgrade, pilihan sesi, suara.
