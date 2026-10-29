# Gang Roh — Dokumen Desain Singkat

## Premis
Sebuah gang kecil di kota bergaya Jepang. Kamu adalah roh penjaga gang yang hidup dari persembahan warga.
Bagi roh, waktu berjalan cepat: **1 hari = 1 bulan manusia**. Kamu menyaksikan (dan memengaruhi)
gang tumbuh dari warung satu lantai menjadi deretan gedung bertingkat.

## Core loop (gaya Kingdom Two Crowns)
1. Siang: toko menghasilkan koin, kuil menerima persembahan.
2. Pungut koin (kantong terbatas), jalan kiri-kanan, naik tangga ke atap.
3. Tanam koin di titik bangun → perancah → lantai baru di awal bulan berikutnya.
4. Malam: developer rakus datang (mulai bulan 2).

## Developer & bangunan menua (v0.2)
- Sore muncul firasat: developer datang dari ujung kiri/kanan (mulai bulan 7: dua ujung).
- Malam developer masuk, mengincar petak terdekat yang kosong atau bobrok → pasang papan DIJUAL.
  Kalau papan masih ada saat dia datang lagi → petak digusur (pagar seng). 4 petak digusur = kalah.
- Lawan: pagar bambu di ujung gang (tiap koin +1, maks 4; didorong −1 tiap 7 dtk),
  uang rokok (2 + bulan/3 koin, dia pergi malam itu), cabut papan (3 koin), rebut petak (10 koin).
- Bangunan menua tiap bulan (makin tinggi makin cepat). Kusam (<60): koin toko lebih jarang, lampu redup.
  Bobrok (<30): toko & sewa berhenti, jadi incaran developer; kondisi 0 → penghuni lantai atas pindah.
  Rawat: tanam koin di depan pintu atau dari atap (+25 per koin).

## Kontrol
Kiri/kanan, atas/bawah (tangga), satu tombol aksi. Di HP: swipe ke arah tujuan lalu tahan (di mana saja kecuali UI), sentuh-tahan di tempat/ketuk = aksi; mendukung portrait dan landscape.

## v0.4: yōkai kesialan & pasukan roh (tahap 1 ✅: Gaki + Tsukumogami, developer siang)
- **Siang**: developer (ancaman ekonomi) — pasang papan DIJUAL di petak kosong/bobrok; usir dengan Doa, cabut papan.
- **Malam**: yōkai kesialan (Kegare) datang dari ujung gang dan dari sarang (bangunan bobrok/tergusur):
  - Gaki (hantu lapar): bergerombol, lemah, memakan Doa di jalan.
  - Binbōgami (dewa kemiskinan): menempel di bangunan, menyedot penghasilan, mempercepat bobrok.
  - Noppera-bō: menakuti penghuni → lantai berkurang.
  - Oni (bos, tiap beberapa bulan): kuat, merusak pagar & bangunan.
- **Pasukan roh**:
  - Tsukumogami (Karakasa payung, Chōchin lentera, Bakezōri sandal) lahir dari bangunan terawat;
    jumlah ∝ lantai. Bangun & rawat = tambah pasukan.
  - Kuil bisa di-upgrade (Doa) memanggil roh: Kitsune-bi (serang jarak jauh), Komainu (penjaga gerbang), Kodama (penyembuh).
  - Kucing: Lambaian Rezeki mengusir yōkai lemah.
- Yōkai punya HP; dikalahkan → menjatuhkan Doa.

## Roh penjaga (dipilih di awal sesi)
| Roh | Fokus | Pasif | Unik |
|---|---|---|---|
| Maneki-neko | Ekonomi | Toko +koin | Lambaian Rezeki (koin bonus), Investasi (bunga) |
| Tanuki | Sosial / tipu daya | Penghuni betah | Menyamar (usir developer), Festival |
| Komainu | Perlindungan | Bangunan menua lambat | Penjaga (tahan bencana), Pondasi Suci (lebih tinggi) |
| Zashiki-warashi (nanti) | Apartemen | Penghuni bahagia | — |

## Tantangan (gabungan)
- **Developer rakus**: datang dari ujung gang, incar petak kosong/terbengkalai.
- **Bangunan menua**: kusam, bocor; penghuni pindah kalau tak dirawat.
- **Bencana**: topan, gempa, mati listrik; ada firasat sebelumnya.
Kalah: kuil tergusur (Ema tetap didapat, dikurangi).

## Sesi
| Sesi | Waktu manusia | Hari main | Bonus |
|---|---|---|---|
| Pendek | 1 tahun | 12 | modal awal besar, Ema ×1 |
| Sedang | 3 tahun | 36 | Ema ×1,5, 1 bencana besar |
| Panjang | 5 tahun | 60 | Ema ×2, peluang unlock langka |

## Sumber daya
- **Doa** (dalam sesi): bola cahaya dari warga yang bahagia (toko, sewa, kuil, Lambaian Rezeki).
  Dipakai untuk membangun, merawat, pagar, dan uang rokok.
- **Ema** (permanen): didapat di akhir sesi = bulan dilalui + total lantai (+10 kalau bertahan setahun;
  dibagi dua kalau kalah).

## Progres permanen (layar Persiapan Roh, sebelum tiap sesi)
- Langkah: +10% kecepatan/lv. Kantong: +2 kapasitas Doa/lv. Berkah: +2 Doa awal/lv.
  Firasat: firasat developer lebih awal, pagar awal lebih kuat. Pesona: Lambaian lebih sering & lebih banyak Doa.
- Level 1–5, biaya naik tiap level.
- Kemampuan unik per roh, level 1–5.

## Roadmap
1. ✅ v0.1 inti: jalan, tangga, koin, bangun, siang/malam, kontrol HP.
2. ✅ Developer rakus + bangunan menua.
3. ✅ Menu, layar akhir + Ema, upgrade permanen + simpan data (pilih roh & panjang sesi menyusul).
4. "Pasukan": warga ronda, Pos Ronda, upgrade kuil + roh pelindung, nyali developer.
5. Tanuki & Komainu, bencana, suara, polish.
