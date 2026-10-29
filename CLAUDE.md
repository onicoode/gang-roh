# Gang Roh — catatan untuk Claude

Baca file ini dulu; jangan menjelajahi seluruh proyek kecuali perlu. Desain lengkap: `docs/GDD.md`.

## Ringkas
Game pixel art side-scroller (Godot 4.7.2, GDScript, renderer GL Compatibility) untuk PC, Web, dan Android,
portrait maupun landscape. Pemain = roh penjaga gang (prototipe: Maneki-neko). Kumpulkan koin persembahan,
warga berdoa → Doa muncul → roh mengabulkan keinginan warga → tukang membangun. 1 hari game = 1 bulan manusia. Sesi pendek 12 bulan.
Pemilik proyek berbahasa Indonesia, pemula Godot/GitHub: jelaskan singkat dan sederhana.

## Alur kerja
- Repo: github.com/onicoode/gang-roh (publik). Folder lokal di PC: `D:\CodeProject\Sandbox\gang-roh`.
- **Kerjakan langsung di `main`** (permintaan pemilik): jangan buat branch/PR baru kecuali diminta.
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
| `scenes/menu.tscn` + `scripts/menu.gd` | Scene awal: menu utama + layar Persiapan Roh (upgrade dengan Ema). UI dibuat dari kode |
| `scripts/save.gd` | Autoload `Save`: Ema, level kemampuan (`SKILLS`), simpan ke `user://save.cfg`, `finish_session()` |
| `scripts/ui_theme.gd` | Tema UI bersama (tombol/panel/warna) |
| `scenes/main.tscn` + `scripts/main.gd` | Game: SubViewport pixel-perfect (sisi terpendek ≈180 px game), HUD Doa, jeda (tombol II/Back/Esc), panel akhir + Ema |
| `scripts/swipe_input.gd` | Kontrol sentuh tak terlihat: swipe+tahan = gerak, sentuh diam/ketuk = aksi (`_unhandled_input`, UI makan sentuhan dulu) |
| `scenes/world.tscn` + `scripts/world.gd` | Gang: petak, kuil, siklus hari/bulan, langit, parallax, koin, jadwal developer, target koin, kalah, shake, teks melayang |
| `scripts/building.gd` | Satu petak: lantai, kondisi (menua), hokora, papan DIJUAL/digusur, `Job` (bangun/rawat/batal jual/rebut/hokora), gelembung keinginan, tukang, kirim warga berdoa |
| `scripts/developer.gd` | Developer rakus (siang, digambar `_draw`): pasang papan DIJUAL, gusur; disialkan roh (awan hujan) |
| `scripts/warga.gd` | Warga: keluar rumah/datang dari ujung gang, berdoa di kuil pusat (2 Doa) atau hokora (1 Doa). Satu-satunya sumber Doa |
| `scripts/gaki.gd` | Yokai Gaki (malam): makan Doa di jalan, pukul pagar & Tsukumogami, curi persembahan kuil; HP 3 |
| `scripts/spirit.gd` | Pasukan roh (`STATS` per jenis): Tsukumogami Bakezori/Karakasa/Chochin (dari bangunan), Kitsune-bi & Komainu (dari kuil) |
| `scripts/shrine.gd` | Kuil pusat: level 1–5 (upgrade dengan Doa, `COSTS`), hiasan, jumlah Kitsune-bi; Lv4 Kodama merawat, Lv5 aura |
| `scripts/gate.gd` | Pagar roh di ujung gang, menahan yokai (hp 0–4, tanam Doa = +1) |
| `scripts/sfx.gd` | Efek suara dibuat dari kode (tanpa file audio): `world.sfx.play("pickup")` |
| `scripts/cat.gd` | Pemain: state GROUND/CLIMB/ROOF, pakai Doa (tahan aksi), Lambaian Rezeki (mendatangkan pengunjung) |
| `scripts/coin.gd` | Koin memantul + dipungut |
| `shaders/` | `sky` (gradasi), `wind` (goyang jemuran/tanaman) |
| `tools/gen_sprites.py` | Generator sprite placeholder (Python murni). `python tools/gen_sprites.py` |

## Ukuran sprite (kalau diganti buatan sendiri)
- `cat.png` 12 frame 16×16: 0-3 diam, 4-7 jalan, 8-9 memanjat, 10-11 melambai (menghadap kanan).
- `shop.png` / `apt.png` (+ `_lights`): 3 gaya × 48×32. `roof.png` 3 × 48×10. `ladder.png` 6×32 (diulang).

## Tes lokal (PC)
- Error check: `Godot_console.exe --headless --path . --quit-after 300 -- --demo`
- Argumen debug apa pun membuat menu langsung masuk game; `-- --menu` = uji menu.
- Argumen debug: `-- --demo` (gedung acak bertingkat), `--time=0.8` (jam: 0 pagi … 0.75 malam),
  `--month=8` (bulan awal), `--speed=10` (percepat waktu).
- CI juga jalan di setiap PR ke `main` (cek error + build, tanpa deploy).

## Status (update di akhir tiap sesi)
- v0.1 prototipe: jalan, tangga, atap, koin, bangun 0→5 lantai, siang/malam, lampu, AC, jemuran, awan,
  kontrol sentuh swipe (tanpa tombol), layout portrait/landscape, ringkasan akhir sesi.
- v0.2: developer rakus (malam, mulai bulan 2; dua ujung mulai bulan 7), pagar, uang rokok, papan DIJUAL → gusur,
  kalah bila 4 petak digusur, bangunan menua (kusam/bobrok, rawat dengan koin), suara sintetis, shake, teks "+1".
- v0.3: menu utama, layar Persiapan Roh (5 kemampuan, Ema, tersimpan), jeda, HUD baru,
  sumber daya koin → **Doa** (bola cahaya; variabel kode masih bernama `coins`).
- v0.4 tahap 1: developer pindah ke siang; malam = Gaki (dari ujung + sarang bangunan bobrok/tergusur)
  vs Tsukumogami (terawat 1/lantai, kusam separuh, bobrok 0). Lempar Doa ke Gaki = 2 dmg.
- v0.5: Doa hanya dari warga yang berdoa (pengunjung kuil pagi + dari luar gang, penghuni tiap bangunan);
  hokora per bangunan (3 Doa); gelembung keinginan; tukang; developer disialkan. Toko/sewa tidak lagi memberi Doa.
- v0.6: kuil bisa di-upgrade Lv1–5 (6/10/15/20 Doa): Kitsune-bi (Lv2+), Komainu di pagar (Lv3+),
  Kodama merawat tiap pagi (Lv4+), aura (Lv5: pengunjung 3 Doa, roh +1 nyawa).
- Tahap berikut: Binbogami, Noppera-bo, Oni (bos).
- Belum: bencana, roh lain (Tanuki, Komainu), Ema/upgrade, pilihan sesi, suara.
