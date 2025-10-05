
-- Tabloları oluşturma

CREATE TABLE Kategori (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(100) NOT NULL
);

CREATE TABLE Satici (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(150) NOT NULL,
    adres VARCHAR(255)
);

CREATE TABLE Musteri (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(50) NOT NULL,
    soyad VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    sehir VARCHAR(50),
    kayit_tarihi DATE DEFAULT CURRENT_DATE
);

CREATE TABLE Urun (
    id SERIAL PRIMARY KEY,
    ad VARCHAR(200) NOT NULL,
    fiyat DECIMAL(10, 2) NOT NULL CHECK (fiyat > 0),
    stok INT NOT NULL CHECK (stok >= 0),
    kategori_id INT,
    satici_id INT,
    FOREIGN KEY (kategori_id) REFERENCES Kategori(id),
    FOREIGN KEY (satici_id) REFERENCES Satici(id)
);

CREATE TABLE Siparis (
    id SERIAL PRIMARY KEY,
    musteri_id INT,
    tarih TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    toplam_tutar DECIMAL(12, 2),
    odeme_turu VARCHAR(50), -- 'Kredi Kartı', 'Havale', 'Kapıda Ödeme' vb.
    FOREIGN KEY (musteri_id) REFERENCES Musteri(id)
);

CREATE TABLE Siparis_Detay (
    id SERIAL PRIMARY KEY,
    siparis_id INT,
    urun_id INT,
    adet INT NOT NULL CHECK (adet > 0),
    fiyat DECIMAL(10, 2) NOT NULL, -- Sipariş anındaki ürün fiyatı
    FOREIGN KEY (siparis_id) REFERENCES Siparis(id) ON DELETE CASCADE,
    FOREIGN KEY (urun_id) REFERENCES Urun(id)
);

-- Örnek Veri Ekleme (INSERT)

-- Kategoriler
INSERT INTO Kategori (ad) VALUES ('Elektronik'), ('Kitap'), ('Giyim'), ('Ev & Yaşam');

-- Satıcılar
INSERT INTO Satici (ad, adres) VALUES ('TeknoMarket', 'İstanbul'), ('KitapDunyasi', 'Ankara'), ('ModaTrend', 'İzmir');

-- Müşteriler
INSERT INTO Musteri (ad, soyad, email, sehir, kayit_tarihi) VALUES
('Ahmet', 'Yılmaz', 'ahmet.yilmaz@example.com', 'İstanbul', '2023-01-15'),
('Ayşe', 'Kaya', 'ayse.kaya@example.com', 'Ankara', '2023-02-20'),
('Mehmet', 'Demir', 'mehmet.demir@example.com', 'İzmir', '2023-03-10'),
('Fatma', 'Çelik', 'fatma.celik@example.com', 'İstanbul', '2023-04-05');

-- Ürünler
INSERT INTO Urun (ad, fiyat, stok, kategori_id, satici_id) VALUES
('Akıllı Telefon', 15000.00, 50, 1, 1),
('Dizüstü Bilgisayar', 25000.00, 30, 1, 1),
('SQL Veri Tabanı Yönetimi', 150.00, 100, 2, 2),
('T-Shirt', 250.00, 200, 3, 3),
('Kahve Makinesi', 2000.00, 40, 4, 1);

-- Sipariş Oluşturma (Önce Siparis, sonra Siparis_Detay)
-- Sipariş 1: Ahmet Yılmaz
INSERT INTO Siparis (musteri_id, toplam_tutar, odeme_turu) VALUES (1, 15150.00, 'Kredi Kartı');
INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat) VALUES
(1, 1, 1, 15000.00),
(1, 3, 1, 150.00);

-- Sipariş 2: Ayşe Kaya
INSERT INTO Siparis (musteri_id, toplam_tutar, odeme_turu) VALUES (2, 250.00, 'Havale');
INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat) VALUES
(2, 4, 1, 250.00);

-- Sipariş 3: Ahmet Yılmaz tekrar sipariş veriyor
INSERT INTO Siparis (musteri_id, toplam_tutar, odeme_turu) VALUES (1, 500.00, 'Kredi Kartı');
INSERT INTO Siparis_Detay (siparis_id, urun_id, adet, fiyat) VALUES
(3, 4, 2, 250.00);

SORGULAR

-- En çok sipariş veren 5 müşteri
SELECT m.ad, m.soyad, COUNT(s.id) AS siparis_sayisi
FROM Musteri m
JOIN Siparis s ON m.id = s.musteri_id
GROUP BY m.id, m.ad, m.soyad
ORDER BY siparis_sayisi DESC
LIMIT 5;

-- En çok satılan ürünler
SELECT u.ad, SUM(sd.adet) AS toplam_satilan_adet
FROM Siparis_Detay sd
JOIN Urun u ON sd.urun_id = u.id
GROUP BY u.id, u.ad
ORDER BY toplam_satilan_adet DESC;

-- En yüksek cirosu olan satıcılar
SELECT sa.ad, SUM(sd.adet * sd.fiyat) AS toplam_ciro
FROM Satici sa
JOIN Urun u ON sa.id = u.satici_id
JOIN Siparis_Detay sd ON u.id = sd.urun_id
GROUP BY sa.id, sa.ad
ORDER BY toplam_ciro DESC;

-- Şehirlere göre müşteri sayısı
SELECT sehir, COUNT(id) AS musteri_sayisi
FROM Musteri
GROUP BY sehir
ORDER BY musteri_sayisi DESC;

-- Kategori bazlı toplam satışlar (Ciro)
SELECT k.ad, SUM(sd.adet * sd.fiyat) AS kategori_cirosu
FROM Kategori k
JOIN Urun u ON k.id = u.kategori_id
JOIN Siparis_Detay sd ON u.id = sd.urun_id
GROUP BY k.id, k.ad
ORDER BY kategori_cirosu DESC;

-- Aylara göre sipariş sayısı (PostgreSQL)
SELECT TO_CHAR(tarih, 'YYYY-MM') AS ay, COUNT(id) AS siparis_sayisi
FROM Siparis
GROUP BY ay
ORDER BY ay;

-- Siparişlerde müşteri + ürün + satıcı bilgisi
SELECT
    s.id AS siparis_no,
    s.tarih,
    m.ad AS musteri_ad,
    m.soyad AS musteri_soyad,
    u.ad AS urun_ad,
    sd.adet,
    sd.fiyat,
    sa.ad AS satici_ad
FROM Siparis s
JOIN Musteri m ON s.musteri_id = m.id
JOIN Siparis_Detay sd ON s.id = sd.siparis_id
JOIN Urun u ON sd.urun_id = u.id
JOIN Satici sa ON u.satici_id = sa.id
WHERE s.id = 1; -- Örnek olarak 1 numaralı siparişin detayı

-- Hiç satılmamış ürünler (LEFT JOIN)
SELECT u.ad, u.fiyat, u.stok
FROM Urun u
LEFT JOIN Siparis_Detay sd ON u.id = sd.urun_id
WHERE sd.id IS NULL;

-- Hiç sipariş vermemiş müşteriler
SELECT m.ad, m.soyad, m.email
FROM Musteri m
LEFT JOIN Siparis s ON m.id = s.musteri_id
WHERE s.id IS NULL;

-- En çok kazanç sağlayan ilk 3 kategori
SELECT k.ad, SUM(sd.adet * sd.fiyat) AS toplam_kazanc
FROM Kategori k
JOIN Urun u ON k.id = u.kategori_id
JOIN Siparis_Detay sd ON u.id = sd.urun_id
GROUP BY k.id, k.ad
ORDER BY toplam_kazanc DESC
LIMIT 3;

-- Ortalama sipariş tutarını geçen siparişleri bul (Subquery/Alt Sorgu)
SELECT id, musteri_id, toplam_tutar
FROM Siparis
WHERE toplam_tutar > (SELECT AVG(toplam_tutar) FROM Siparis);

-- En az bir kez "Elektronik" ürün satın alan müşteriler
SELECT DISTINCT m.id, m.ad, m.soyad, m.email
FROM Musteri m
JOIN Siparis s ON m.id = s.musteri_id
JOIN Siparis_Detay sd ON s.id = sd.siparis_id
JOIN Urun u ON sd.urun_id = u.id
JOIN Kategori k ON u.kategori_id = k.id
WHERE k.ad = 'Elektronik';