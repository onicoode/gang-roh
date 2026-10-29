# Gang Roh — Dokumen Desain Singkat

## Premis
Sebuah gang kecil di kota bergaya Jepang. Kamu adalah roh penjaga gang yang hidup dari persembahan warga.
Bagi roh, waktu berjalan cepat: **1 hari = 1 bulan manusia**. Kamu menyaksikan (dan memengaruhi)
gang tumbuh dari warung satu lantai menjadi deretan gedung bertingkat.

## Core loop (gaya Kingdom Two Crowns)
1. Siang: toko menghasilkan koin, kuil menerima persembahan.
2. Pungut koin (kantong terbatas), jalan kiri-kanan, naik tangga ke atap.
3. Tanam koin di titik bangun → perancah → lantai baru di awal bulan berikutnya.
4. Malam: tantangan datang (belum di prototipe).

## Kontrol
Kiri/kanan, atas/bawah (tangga), satu tombol aksi. Di HP: swipe ke arah tujuan lalu tahan (di mana saja kecuali UI), sentuh-tahan di tempat/ketuk = aksi; mendukung portrait dan landscape.

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

## Progres permanen
Mata uang **Ema** (papan doa) dari hasil sesi.
- Kemampuan umum (per karakter): Langkah, Kantong, Firasat, Berkah, Pesona.
- Kemampuan unik per roh, level 1–5.

## Roadmap
1. ✅ v0.1 inti: jalan, tangga, koin, bangun, siang/malam, kontrol HP.
2. Developer rakus + bangunan menua.
3. Menu: pilih roh & panjang sesi; layar akhir + Ema.
4. Upgrade permanen + simpan data.
5. Tanuki & Komainu, bencana, suara, polish.
