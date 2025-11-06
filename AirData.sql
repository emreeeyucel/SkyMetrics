
/*
Customers   → Yolcunun bilgisi
Tickets     → Yolcunun satın aldığı bilet
Flights     → Biletin bağlı olduğu uçuş
Sales       → Satış işlemi ve ödeme
Employees   → Satışı yapan personel
Departments → O personelin departmanı
*/
-- Tablo İncelemesi

select * from Customers C
JOIN Tickets T ON C.CustomerID = T.CustomerID
JOIN Flights F ON F.FlightID = T.FlightID
JOIN Sales S ON S.TicketID = T.TicketID
JOIN Employees	E ON E.EmployeeID=S.EmployeeID
JOIN Departments D ON D.DepartmentID = E.DepartmentID




--Her müşterinin toplam kaç bilet satın aldığı bilgisi

SELECT C.CustomerID, C.FirstName,C.LastName, COUNT(C.CustomerID) AS ToplamSatınAlınanBilet from Customers	C
JOIN Tickets T ON T.CustomerID=C.CustomerID
GROUP BY C.CustomerID, C.FirstName,C.LastName
ORDER BY count(C.CustomerID) desc


--Her müşterinin biletlerinden elde edilen toplam gelir bilgisi

SELECT C.CustomerID, C.FirstName,C.LastName,COUNT(DISTINCT T.TicketID)  AS ToplamAlınanBilet,  SUM(S.SaleAmount)  AS ToplamGercekSatis, SUM(T.Price) AS ToplamListeFiyati FROM Customers C
JOIN Tickets T ON T.CustomerID= C.CustomerID
JOIN Sales S ON S.TicketID=T.TicketID
GROUP BY C.CustomerID, C.FirstName,C.LastName
ORDER BY SUM(S.SaleAmount) DESC

-- Müşterilerin  ortalama bilet fiyatı nedir ?
SELECT C.CustomerID, C.FirstName,C.LastName,COUNT(DISTINCT T.TicketID)  AS ToplamAlınanBilet,  AVG(S.SaleAmount)  AS OrtalamaBiletFİyatı FROM Customers C
JOIN Tickets T ON T.CustomerID= C.CustomerID
JOIN Sales S ON S.TicketID=T.TicketID
GROUP BY C.CustomerID, C.FirstName,C.LastName
ORDER BY SUM(S.SaleAmount) DESC


--Her müşterinin uçtuğu varış havaalanı(ArrivalAirport) ve kaç kez uçtukları bilgisi 

WITH MüsteriUçuşlari  AS (SELECT C.CustomerID,C.FirstName,C.LastName,F.DepartureAirport,F.ArrivalAirport,F.DepartureTime,F.ArrivalTime FROM Tickets T
JOIN Flights F ON F.FlightID=T.FlightID
JOIN Customers C ON C.CustomerID=T.CustomerID)

SELECT  CustomerID,FirstName,LastName, ArrivalAirport, COUNT(ArrivalAirport) AS VarışSayısı from MüsteriUçuşlari
GROUP BY CustomerID,  ArrivalAirport,FirstName,LastName
ORDER BY  CustomerID

--Her müşterinin sadece en çok uçtuğu varış havaalanı (ArrivalAirport) bilgisi ile kaç kez uçtuğu bilgisi 

WITH MüsteriUçuşlari AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        F.ArrivalAirport
    FROM Tickets T
    JOIN Flights F ON F.FlightID = T.FlightID
    JOIN Customers C ON C.CustomerID = T.CustomerID
),
VarisSayilari AS (
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        ArrivalAirport,
        COUNT(*) AS VarisSayisi,      -- Tüm sütunlara göre grupladığımız için aynı müşteri birden fazla kez gelir.Sadece CustomerID ve COUNT(*) AS VarisSayisi olsaydı her müşteri birkez gelirdi ve toplam varış sayıları gelirdi 1 1 yerine 2 gelırdi
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY COUNT(*) DESC) AS rn
    FROM MüsteriUçuşlari
    GROUP BY CustomerID, FirstName, LastName, ArrivalAirport
)
SELECT CustomerID, FirstName, LastName, ArrivalAirport, VarisSayisi
FROM VarisSayilari
WHERE rn = 1
ORDER BY CustomerID;



-- Her müşterinin:Toplam aldığı bilet sayısı, İlk aldığı bilet tarihi ve Son aldığı bilet tarihi (Window Functions):
WITH MusteriBiletleri AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        T.TicketID,
        T.PurchaseDate
    FROM Customers C
    JOIN Tickets T ON T.CustomerID = C.CustomerID
)
SELECT DISTINCT
    CustomerID,
    FirstName,
    LastName,
    COUNT(TicketID) OVER(PARTITION BY CustomerID) AS ToplamBiletSayisi,
    MIN(PurchaseDate) OVER(PARTITION BY CustomerID) AS IlkBiletTarihi,
    MAX(PurchaseDate) OVER(PARTITION BY CustomerID) AS SonBiletTarihi
FROM MusteriBiletleri
ORDER BY CustomerID;


-- Her müşterinin:Toplam aldığı bilet sayısı, İlk aldığı bilet tarihi  ve Son aldığı bilet tarihi (Group By):
SELECT 
    C.CustomerID,
    C.FirstName,
    C.LastName,
    COUNT(T.TicketID) AS ToplamBiletSayisi,
    MIN(T.PurchaseDate) AS IlkBiletTarihi,
    MAX(T.PurchaseDate) AS SonBiletTarihi
FROM Customers C
JOIN Tickets T ON T.CustomerID = C.CustomerID
GROUP BY C.CustomerID, C.FirstName, C.LastName
ORDER BY C.CustomerID;


--Her müşteri kendi içinde biletlerini satın alma tarihine göre sıralayıp her bilete 1’den başlayan sıra numarası verelim.

SELECT C.CustomerID, C.FirstName, T.PurchaseDate,
ROW_NUMBER () OVER (PARTITION BY C.CustomerID ORDER BY T.PurchaseDate ASC) AS SiraNumarasi 
FROM Customers C
JOIN Tickets T ON T.CustomerID=C.CustomerID


--En fazla gelir getiren ilk 5 müşteriyi bul — yani toplam SaleAmount değerine göre sıralayıp ilk 5 kişiyi getir. 

WITH MüşteriBilgisi AS (
    SELECT 
        C.CustomerID, 
        C.FirstName, 
        C.LastName, 
        S.SaleAmount
    FROM Customers C
    JOIN Tickets T ON T.CustomerID = C.CustomerID
    JOIN Sales S ON S.TicketID = T.TicketID
)
SELECT TOP 5
    CustomerID,
    C.FirstName + ' ' + C.LastName AS CustomerName,
    SUM(SaleAmount) AS BileteHarcananTutar
FROM MüşteriBilgisi C
GROUP BY CustomerID, C.FirstName, C.LastName
ORDER BY SUM(SaleAmount) DESC;


 -- Toplamda en çok farklı havaalanına uçan müşteriyİ bulalım (en çok destinasyon gezen müşteri analizi.)

WITH UçuşBilgisi AS (
SELECT C.CustomerID, C.FirstName, C.LastName,F.ArrivalAirport FROM Customers C
JOIN Tickets T ON T.CustomerID=C.CustomerID
JOIN Flights F ON F.FlightID=T.FlightID
)

select CustomerID, FirstName, LastName, COUNT( DISTINCT ArrivalAirport) AS FarklıUçuşSayısı from UçuşBilgisi
GROUP BY CustomerID, FirstName, LastName
ORDER BY COUNT(DISTINCT  ArrivalAirport) DESC


-- Her müşterinin, uçtuğu toplam sefer sayısını ve genel ortalamaya göre konumunu (yani ortalamanın üstünde mi, altında mı) gösterelim.


WITH MüşteriUçuşBilgileri AS (
SELECT C.CustomerID,C.FirstName,C.LastName, COUNT(C.CustomerID) AS MüşteriToplamUçuşSayısı
FROM Customers C
JOIN Tickets T ON T.CustomerID= C.CustomerID
JOIN Flights F ON F.FlightID=T.FlightID
GROUP BY  C.CustomerID,C.FirstName,C.LastName
),
OrtalamaUçuşBilgisi AS(
SELECT CustomerID,FirstName,LastName, MüşteriToplamUçuşSayısı,
AVG(MüşteriToplamUçuşSayısı) OVER () AS OrtalamaUçuşSayısı
FROM MüşteriUçuşBilgileri
)
SELECT *,
CASE 
WHEN MüşteriToplamUçuşSayısı > OrtalamaUçuşSayısı THEN 'Ortalama Üstü'
WHEN MüşteriToplamUçuşSayısı < OrtalamaUçuşSayısı THEN 'Ortalama Altı'
ELSE 'Ortalama Düzeyinde' END AS UçuşSegmenti
FROM OrtalamaUçuşBilgisi



-- Ortalama üstü müşterilerin toplam harcama ortalamasını karşılaştıralım (Yani çok uçan müşter aynı zamanda çok harcayan müşterimi sorusuna cevap arayalım)

WITH MüşteriUçuşHarcamaları AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        COUNT(T.TicketID) AS ToplamUçuş,
        SUM(S.SaleAmount) AS ToplamHarcama
    FROM Customers C
    JOIN Tickets T ON T.CustomerID = C.CustomerID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
),
Segmentleme AS (
    SELECT *,
           AVG(ToplamUçuş) OVER() AS OrtalamaUçuş,
           CASE 
               WHEN ToplamUçuş > AVG(ToplamUçuş) OVER() THEN 'Ortalama Üstü'
               WHEN ToplamUçuş < AVG(ToplamUçuş) OVER() THEN 'Ortalama Altı'
               ELSE 'Ortalama Düzeyinde'
           END AS UçuşSegmenti
    FROM MüşteriUçuşHarcamaları
)
SELECT 
    UçuşSegmenti,
    COUNT(CustomerID) AS MüşteriSayısı,
    ROUND(AVG(ToplamUçuş), 2) AS OrtalamaUçuşSayısı,
    ROUND(AVG(ToplamHarcama), 2) AS OrtalamaHarcama
FROM Segmentleme
GROUP BY UçuşSegmenti
ORDER BY OrtalamaHarcama DESC;


--Her müşterinin uçuş sıklığına göre (ortalama üstü, altı, düzeyinde) hangi uçuş sınıfında (SeatClass) daha çok bilet aldığını bul.

WITH MüşteriUçuşSegmentleri AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        COUNT(T.TicketID) AS ToplamUçuş
    FROM Customers C
    JOIN Tickets T ON T.CustomerID = C.CustomerID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
),
Segmentleme AS (
    SELECT *,
           AVG(ToplamUçuş) OVER() AS OrtalamaUçuş,
           CASE 
               WHEN ToplamUçuş > AVG(ToplamUçuş) OVER() THEN 'Ortalama Üstü'
               WHEN ToplamUçuş < AVG(ToplamUçuş) OVER() THEN 'Ortalama Altı'
               ELSE 'Ortalama Düzeyinde'
           END AS UçuşSegmenti
    FROM MüşteriUçuşSegmentleri
),
UçuşSınıfAnalizi AS (
    SELECT 
        S.UçuşSegmenti,
        T.SeatClass,
        COUNT(T.TicketID) AS AlınanBiletSayısı
    FROM Segmentleme S
    JOIN Tickets T ON S.CustomerID = T.CustomerID
    GROUP BY S.UçuşSegmenti, T.SeatClass
)
SELECT 
    UçuşSegmenti,
    SeatClass,
    AlınanBiletSayısı,
    RANK() OVER(PARTITION BY UçuşSegmenti ORDER BY AlınanBiletSayısı DESC) AS SınıfSırası
FROM UçuşSınıfAnalizi
ORDER BY UçuşSegmenti, SınıfSırası;


-- Her müşterinin ay bazında: Toplam uçuş sayısı ,Toplam harcaması (SaleAmount) ve Ortalama bilet fiyatı(Uçuş Tarihine Göre Aylık Müşteri Analizi)


WITH UçuşBilgisi AS (
SELECT C.CustomerID, C.FirstName,C.LastName, FORMAT(F.DepartureTime, 'yyyy-MM') AS AyBilgisi, S.SaleAmount FROM Customers C
JOIN Tickets T ON T.CustomerID=C.CustomerID
JOIN Flights F ON F.FlightID=T.FlightID
JOIN Sales S ON S.TicketID=T.TicketID
),

AylikMusteriAnalizi  AS(
SELECT CustomerID,FirstName,LastName,AyBilgisi, 
SUM(SaleAmount) AS ToplamHarcananTutar,
COUNT(CustomerID) AS ToplamUçuşBilgisi,
AVG(SaleAmount) AS OrtalamaBiletTutar
from UçuşBilgisi
group by CustomerID,FirstName,LastName,AyBilgisi
)

SELECT * FROM AylikMusteriAnalizi 
ORDER BY CustomerID



-- Müşteri Sadakat Analizi (Frekans ve Tutarlılık Bazlı)
/*
Toplam uçuş sayısını,
Aktif olduğu ay sayısını,
İlk uçuş tarihi (MIN),
Son uçuş tarihi (MAX),
Ortalama uçuş sıklığını (son - ilk tarih farkı / toplam uçuş sayısı),
Sadakat segmentini (örnek olarak):
Aylık Düzenli → 10+ ay aktif
Ara Sıra Uçan → 4–9 ay aktif
Nadiren Uçan → 3 ay ve altı
*/

WITH MusteriUcusAnalizi AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        MIN(F.DepartureTime) AS IlkUcusTarihi,
        MAX(F.DepartureTime) AS SonUcusTarihi,
        COUNT(T.TicketID) AS ToplamUcusSayisi
    FROM Customers C
    JOIN Tickets T ON C.CustomerID = T.CustomerID
    JOIN Flights F ON F.FlightID = T.FlightID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
),
SadakatAnalizi AS (
    SELECT 
        *,
        CASE 
            WHEN ToplamUcusSayisi > 1 THEN DATEDIFF(DAY, IlkUcusTarihi, SonUcusTarihi) / (ToplamUcusSayisi - 1)
            ELSE NULL
        END AS OrtalamaGunAraligi
    FROM MusteriUcusAnalizi
)
SELECT 
    CustomerID,
    FirstName,
    LastName,
    IlkUcusTarihi,
    SonUcusTarihi,
    ToplamUcusSayisi,
    OrtalamaGunAraligi,
    CASE 
        WHEN OrtalamaGunAraligi <= 30 THEN 'Sık Uçan (Sadık)'
        WHEN OrtalamaGunAraligi BETWEEN 31 AND 90 THEN 'Orta Sıklıkta Uçan'
        ELSE 'Nadiren Uçan'
    END AS SadakatSegmenti
FROM SadakatAnalizi
ORDER BY OrtalamaGunAraligi DESC, ToplamUcusSayisi DESC;



-- Müşterinin zaman içinde uçuşları artıyor mu azalıyor mu?

WITH AylikTrend AS (
  SELECT 
    C.CustomerID,
    YEAR(F.DepartureTime) AS Yil,
    MONTH(F.DepartureTime) AS Ay,
    COUNT(T.TicketID) AS UcusSayisi
  FROM Customers C
  JOIN Tickets T ON T.CustomerID = C.CustomerID
  JOIN Flights F ON F.FlightID = T.FlightID
  GROUP BY C.CustomerID, YEAR(F.DepartureTime), MONTH(F.DepartureTime)
)

SELECT *,
       UcusSayisi - LAG(UcusSayisi) OVER(PARTITION BY CustomerID ORDER BY Yil, Ay) AS Degisim
FROM AylikTrend;


--  Uçuş Tarihine Göre Geliştirilmiş Aylık Müşteri Analizi

WITH UçuşBilgisi AS (
    SELECT 
        C.CustomerID, 
        C.FirstName, 
        C.LastName, 
        FORMAT(F.DepartureTime, 'yyyy-MM') AS AyBilgisi, 
        S.SaleAmount
    FROM Customers C
    JOIN Tickets T ON T.CustomerID = C.CustomerID
    JOIN Flights F ON F.FlightID = T.FlightID
    JOIN Sales S ON S.TicketID = T.TicketID
),

AylikMusteriAnalizi AS (
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        AyBilgisi,
        COUNT(CustomerID) AS ToplamUcusSayisi,
        SUM(SaleAmount) AS ToplamHarcananTutar,
        AVG(SaleAmount) AS OrtalamaBiletTutari
    FROM UçuşBilgisi
    GROUP BY CustomerID, FirstName, LastName, AyBilgisi
),

TrendAnalizi AS (
    SELECT
        *,
        LAG(ToplamHarcananTutar) OVER(PARTITION BY CustomerID ORDER BY AyBilgisi) AS OncekiAyHarcamasi,
        (ToplamHarcananTutar - LAG(ToplamHarcananTutar) OVER(PARTITION BY CustomerID ORDER BY AyBilgisi)) AS AylikDegisim,
        RANK() OVER(PARTITION BY CustomerID ORDER BY ToplamHarcananTutar DESC) AS HarcamaSirasi
    FROM AylikMusteriAnalizi
)

SELECT
    CustomerID,
    FirstName,
    LastName,
    AyBilgisi,
    ToplamUcusSayisi,
    ToplamHarcananTutar,
    OrtalamaBiletTutari,
    OncekiAyHarcamasi,
    AylikDegisim,
    CASE WHEN HarcamaSirasi = 1 THEN 'En Yüksek Harcama Ayı' ELSE '' END AS EnYuksekAy
FROM TrendAnalizi
ORDER BY CustomerID, AyBilgisi;


-- En kârlı müşteri segmenti analizi

WITH MusteriGelir AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        COUNT(T.TicketID) AS ToplamUcusSayisi,
        SUM(S.SaleAmount) AS ToplamGelir,
        AVG(S.SaleAmount) AS OrtalamaBiletTutari
    FROM Customers C
    JOIN Tickets T ON C.CustomerID = T.CustomerID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
)
SELECT 
    CustomerID,
    FirstName,
    LastName,
    ToplamUcusSayisi,
    ToplamGelir,
    OrtalamaBiletTutari,
    CASE 
        WHEN ToplamGelir >= (SELECT AVG(ToplamGelir) FROM MusteriGelir) THEN 'Yüksek Gelirli Müşteri'
        ELSE 'Düşük Gelirli Müşteri'
    END AS GelirSegmenti,
    CASE 
        WHEN ToplamUcusSayisi >= (SELECT AVG(ToplamUcusSayisi) FROM MusteriGelir) THEN 'Sık Uçan Müşteri'
        ELSE 'Az Uçan Müşteri'
    END AS UcusSegmenti
FROM MusteriGelir
ORDER BY ToplamGelir DESC;


--Uçuş sayısı ortalamanın üstünde ama toplam harcaması ortalamanın altında olan müşteriler.
WITH MusteriAnalizi AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        COUNT(T.TicketID) AS UcusSayisi,
        SUM(S.SaleAmount) AS ToplamHarcama
    FROM Customers C
    JOIN Tickets T ON T.CustomerID = C.CustomerID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
),
OrtalamaDegerler AS (
    SELECT 
        *,
        AVG(UcusSayisi) OVER () AS OrtalamaUcusSayisi,
        AVG(ToplamHarcama) OVER () AS OrtalamaHarcama
    FROM MusteriAnalizi
)
SELECT 
    CustomerID,
    FirstName,
    LastName,
    UcusSayisi,
    ToplamHarcama,
    OrtalamaUcusSayisi,
    OrtalamaHarcama
FROM OrtalamaDegerler
WHERE 
    UcusSayisi > OrtalamaUcusSayisi 
    AND ToplamHarcama < OrtalamaHarcama
ORDER BY UcusSayisi DESC;


--Müşteri Segmentlerine Göre Rota Bazlı Karlılık Analizi

WITH MusteriSegment AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        COUNT(T.TicketID) AS UcusSayisi,
        SUM(S.SaleAmount) AS ToplamGelir,
        AVG(S.SaleAmount) AS OrtalamaBiletTutari,
        CASE 
            WHEN COUNT(T.TicketID) >= 10 THEN 'Sadık Müşteri'
            WHEN COUNT(T.TicketID) BETWEEN 5 AND 9 THEN 'Orta Düzey Müşteri'
            ELSE 'Tekil / Düşük Etkileşimli'
        END AS MusteriSegmenti
    FROM Customers C
    JOIN Tickets T ON C.CustomerID = T.CustomerID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
),
RotaBazliAnaliz AS (
    SELECT 
        F.DepartureAirport,
        F.ArrivalAirport,
        MS.MusteriSegmenti,
        COUNT(T.TicketID) AS ToplamUcus,
        SUM(S.SaleAmount) AS ToplamGelir,
        AVG(S.SaleAmount) AS OrtalamaGelir
    FROM Flights F
    JOIN Tickets T ON F.FlightID = T.FlightID
    JOIN Sales S ON S.TicketID = T.TicketID
    JOIN MusteriSegment MS ON T.CustomerID = MS.CustomerID
    GROUP BY F.DepartureAirport, F.ArrivalAirport, MS.MusteriSegmenti
)
SELECT 
    DepartureAirport,
    ArrivalAirport,
    MusteriSegmenti,
    ToplamUcus,
    ToplamGelir,
    OrtalamaGelir
FROM RotaBazliAnaliz
ORDER BY ToplamGelir DESC, MusteriSegmenti;

---- CHURN (TERK) ANALİZİ
WITH SonUcus AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        MAX(F.DepartureTime) AS SonUcusTarihi
    FROM Customers C
    JOIN Tickets T ON T.CustomerID = C.CustomerID
    JOIN Flights F ON F.FlightID = T.FlightID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
)
SELECT 
    CustomerID,
    FirstName,
    LastName,
    SonUcusTarihi,
    DATEDIFF(DAY, SonUcusTarihi, GETDATE()) AS GunFarki,
    CASE 
        WHEN DATEDIFF(DAY, SonUcusTarihi, GETDATE()) <= 60 THEN 'Aktif'
        WHEN DATEDIFF(DAY, SonUcusTarihi, GETDATE()) BETWEEN 61 AND 180 THEN 'Churn Riski'
        ELSE 'Kaybedilmiş Müşteri'
    END AS MusteriDurumu
FROM SonUcus
ORDER BY GunFarki DESC;


-- Genel Kârlılık Skoru (RFM Analizi)

WITH MusteriRFM AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        MAX(T.PurchaseDate) AS SonAlimTarihi,
        COUNT(T.TicketID) AS UcusSayisi,
        SUM(S.SaleAmount) AS ToplamGelir,
        DATEDIFF(DAY, MAX(T.PurchaseDate), GETDATE()) AS GecenGun
    FROM Customers C
    JOIN Tickets T ON C.CustomerID = T.CustomerID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
),
SkorHesap AS (
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        ToplamGelir,
        UcusSayisi,
        GecenGun,
        -- R (Recency): Son alışverişe göre ters skor
        CASE 
            WHEN GecenGun <= 30 THEN 5
            WHEN GecenGun <= 90 THEN 4
            WHEN GecenGun <= 180 THEN 3
            WHEN GecenGun <= 365 THEN 2
            ELSE 1
        END AS R_Skor,
        -- F (Frequency): Uçuş sayısına göre skor
        CASE 
            WHEN UcusSayisi >= 15 THEN 5
            WHEN UcusSayisi BETWEEN 10 AND 14 THEN 4
            WHEN UcusSayisi BETWEEN 5 AND 9 THEN 3
            WHEN UcusSayisi BETWEEN 2 AND 4 THEN 2
            ELSE 1
        END AS F_Skor,
        -- M (Monetary): Toplam harcamaya göre skor
        CASE 
            WHEN ToplamGelir >= 5000 THEN 5
            WHEN ToplamGelir BETWEEN 3000 AND 4999 THEN 4
            WHEN ToplamGelir BETWEEN 1500 AND 2999 THEN 3
            WHEN ToplamGelir BETWEEN 500 AND 1499 THEN 2
            ELSE 1
        END AS M_Skor
    FROM MusteriRFM
)
SELECT 
    CustomerID,
    FirstName,
    LastName,
    ToplamGelir,
    UcusSayisi,
    GecenGun,
    (R_Skor + F_Skor + M_Skor) AS GenelSkor,
    CASE 
        WHEN (R_Skor + F_Skor + M_Skor) >= 13 THEN 'VIP / Premium Müşteri'
        WHEN (R_Skor + F_Skor + M_Skor) BETWEEN 9 AND 12 THEN 'Sadık Müşteri'
        WHEN (R_Skor + F_Skor + M_Skor) BETWEEN 6 AND 8 THEN 'Orta Seviye'
        ELSE 'Düşük Değerli Müşteri'
    END AS MusteriSegmenti
FROM SkorHesap
ORDER BY GenelSkor DESC;

-- En yüksek gelir getiren uçuş rotaları(Bu analizde her DepartureAirport → ArrivalAirport rotasının toplam gelirini hesaplayacağız.)

SELECT 
    F.DepartureAirport,
    F.ArrivalAirport,
    COUNT(T.TicketID) AS UcusSayisi,
    SUM(S.SaleAmount) AS ToplamGelir,
    AVG(S.SaleAmount) AS OrtalamaGelir
FROM Flights F
JOIN Tickets T ON F.FlightID = T.FlightID
JOIN Sales S ON S.TicketID = T.TicketID
GROUP BY F.DepartureAirport, F.ArrivalAirport
ORDER BY SUM(S.SaleAmount) DESC;


-- Çalışan Satış Performansı Analizi

WITH CalisanSatis AS (
    SELECT 
        E.EmployeeID,
        E.FirstName,
        E.LastName,
        D.DepartmentName,
        SUM(S.SaleAmount) AS ToplamSatis,
        AVG(S.SaleAmount) AS OrtalamaSatis
    FROM Employees E
    JOIN Sales S ON S.EmployeeID = E.EmployeeID
    JOIN Departments D ON D.DepartmentID = E.DepartmentID
    GROUP BY E.EmployeeID, E.FirstName, E.LastName, D.DepartmentName
),
PerformansAnalizi AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY ToplamSatis DESC) AS SatisSirasi,
        AVG(ToplamSatis) OVER () AS GenelOrtalama
    FROM CalisanSatis
)
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    DepartmentName,
    ToplamSatis,
    OrtalamaSatis,
    SatisSirasi,
    CASE 
        WHEN ToplamSatis > GenelOrtalama THEN 'Ortalama Üstü'
        ELSE 'Ortalama Altı'
    END AS PerformansDurumu
FROM PerformansAnalizi
ORDER BY SatisSirasi;


-- Çalışan Performans Endeksi

WITH CalisanPerformans AS (
    SELECT 
        E.EmployeeID,
        E.FirstName,
        E.LastName,
        D.DepartmentName,
        E.Salary,
        E.HireDate,
        DATEDIFF(YEAR, E.HireDate, GETDATE()) AS KidemYili,
        SUM(S.SaleAmount) AS ToplamSatis
    FROM Employees E
    JOIN Sales S ON S.EmployeeID = E.EmployeeID
    JOIN Departments D ON D.DepartmentID = E.DepartmentID
    GROUP BY E.EmployeeID, E.FirstName, E.LastName, D.DepartmentName, E.Salary, E.HireDate
),
PerformansSkoruHesap AS (
    SELECT 
        *,
        CASE WHEN Salary > 0 THEN CAST(ToplamSatis AS FLOAT) / Salary ELSE NULL END AS MaasVerimliligi,
        CASE WHEN KidemYili > 0 THEN CAST(ToplamSatis AS FLOAT) / KidemYili ELSE NULL END AS KidemVerimliligi
    FROM CalisanPerformans
),
NormalizeSkor AS (
    SELECT 
        *,
        -- Normalize etmek için z-score yaklaşımı: (değer / ortalama)
        ToplamSatis / AVG(ToplamSatis) OVER () AS SatışSkoru,
        MaasVerimliligi / AVG(MaasVerimliligi) OVER () AS MaasSkoru,
        KidemVerimliligi / AVG(KidemVerimliligi) OVER () AS KidemSkoru
    FROM PerformansSkoruHesap
),
PerformansEndeksi AS (
    SELECT 
        *,
        -- Bileşik Performans Skoru (ağırlıklı ortalama)
        (0.5 * SatışSkoru) + (0.3 * MaasSkoru) + (0.2 * KidemSkoru) AS PerformansSkoru
    FROM NormalizeSkor
)
SELECT 
    EmployeeID,
    FirstName,
    LastName,
    DepartmentName,
    Salary,
    KidemYili,
    ROUND(ToplamSatis, 2) AS ToplamSatis,
    ROUND(MaasVerimliligi, 2) AS MaasVerimliligi,
    ROUND(KidemVerimliligi, 2) AS KidemVerimliligi,
    ROUND(PerformansSkoru, 3) AS PerformansSkoru,
    CASE 
        WHEN PerformansSkoru >= 1.2 THEN 'Yüksek Performanslı'
        WHEN PerformansSkoru BETWEEN 0.8 AND 1.19 THEN 'Orta Performanslı'
        ELSE 'Düşük Performanslı'
    END AS PerformansSegmenti
FROM PerformansEndeksi
ORDER BY PerformansSkoru DESC;


-- Mevsimsellik Analizi
WITH AylikUcusGelir AS (
    SELECT 
        YEAR(F.DepartureTime) AS Yil,
        MONTH(F.DepartureTime) AS Ay,
        DATENAME(MONTH, F.DepartureTime) AS AyAdi,
        COUNT(T.TicketID) AS ToplamUcusSayisi,
        SUM(S.SaleAmount) AS ToplamGelir,
        AVG(S.SaleAmount) AS OrtalamaBiletTutari
    FROM Flights F
    JOIN Tickets T ON F.FlightID = T.FlightID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY 
        YEAR(F.DepartureTime),
        MONTH(F.DepartureTime),
        DATENAME(MONTH, F.DepartureTime)
)
SELECT 
    Yil,
    Ay,
    AyAdi,
    ToplamUcusSayisi,
    ToplamGelir,
    OrtalamaBiletTutari,
    CASE 
        WHEN ToplamUcusSayisi >= (SELECT AVG(ToplamUcusSayisi) FROM AylikUcusGelir) THEN 'Yoğun Sezon'
        ELSE 'Sakin Sezon'
    END AS MevsimSegmenti
FROM AylikUcusGelir
ORDER BY Yil, Ay;

-- Rota Bazlı Mevsimsellik Analizi

WITH RotaAylikAnaliz AS (
    SELECT 
        F.DepartureAirport AS Kalkis,
        F.ArrivalAirport AS Varis,
        YEAR(F.DepartureTime) AS Yil,
        MONTH(F.DepartureTime) AS Ay,
        DATENAME(MONTH, F.DepartureTime) AS AyAdi,
        COUNT(T.TicketID) AS ToplamUcusSayisi,
        SUM(S.SaleAmount) AS ToplamGelir,
        AVG(S.SaleAmount) AS OrtalamaBiletTutari
    FROM Flights F
    JOIN Tickets T ON F.FlightID = T.FlightID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY 
        F.DepartureAirport,
        F.ArrivalAirport,
        YEAR(F.DepartureTime),
        MONTH(F.DepartureTime),
        DATENAME(MONTH, F.DepartureTime)
),

RotaOrtalamalari AS (
    SELECT 
        Kalkis,
        Varis,
        AVG(ToplamUcusSayisi) AS RotaOrtalamaUcus,
        AVG(ToplamGelir) AS RotaOrtalamaGelir
    FROM RotaAylikAnaliz
    GROUP BY Kalkis, Varis
)

SELECT 
    R.Kalkis,
    R.Varis,
    R.Yil,
    R.Ay,
    R.AyAdi,
    R.ToplamUcusSayisi,
    R.ToplamGelir,
    R.OrtalamaBiletTutari,
    CASE 
        WHEN R.ToplamUcusSayisi >= RO.RotaOrtalamaUcus THEN 'Yoğun Sezon'
        ELSE 'Sakin Sezon'
    END AS UcusMevsimi,
    CASE 
        WHEN R.ToplamGelir >= RO.RotaOrtalamaGelir THEN 'Yüksek Gelir Dönemi'
        ELSE 'Düşük Gelir Dönemi'
    END AS GelirMevsimi
FROM RotaAylikAnaliz R
JOIN RotaOrtalamalari RO
    ON R.Kalkis = RO.Kalkis
    AND R.Varis = RO.Varis
ORDER BY R.Kalkis, R.Varis, R.Yil, R.Ay;


-- Müşteri – Rota Bazlı Uçuş Analizi





-- RFM Normalizasyonu ve K-Means Tabanlı Müşteri Segmentasyonu Analizi

/* ==========================================================
   Amaç: Müşterileri Recency, Frequency, Monetary değerlerine
   göre analiz etmek, RFM skorları hesaplamak, segment atamak
   ve veriyi normalize ederek modellemeye hazır hale getirmek.
   ========================================================== */

WITH RFM_HamVeri AS (
    SELECT 
        C.CustomerID,
        C.FirstName,
        C.LastName,
        -- R: Son satın alma tarihinden bugüne geçen gün sayısı
        DATEDIFF(DAY, MAX(T.PurchaseDate), GETDATE()) AS Recency,
        -- F: Toplam satın alma (bilet) sayısı
        COUNT(T.TicketID) AS Frequency,
        -- M: Toplam harcama (bilet satış tutarları)
        SUM(S.SaleAmount) AS Monetary
    FROM Customers C
    JOIN Tickets T ON C.CustomerID = T.CustomerID
    JOIN Sales S ON S.TicketID = T.TicketID
    GROUP BY C.CustomerID, C.FirstName, C.LastName
),

RFM_SkorHesap AS (
    SELECT 
        *,
        -- R Skoru (Az gün = yüksek skor)
        CASE 
            WHEN Recency <= PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Recency) OVER() THEN 5
            WHEN Recency <= PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Recency) OVER() THEN 4
            WHEN Recency <= PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Recency) OVER() THEN 3
            WHEN Recency <= PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Recency) OVER() THEN 2
            ELSE 1
        END AS R_Skor,

        -- F Skoru (Çok alışveriş = yüksek skor)
        CASE 
            WHEN Frequency >= PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Frequency) OVER() THEN 5
            WHEN Frequency >= PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Frequency) OVER() THEN 4
            WHEN Frequency >= PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Frequency) OVER() THEN 3
            WHEN Frequency >= PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Frequency) OVER() THEN 2
            ELSE 1
        END AS F_Skor,

        -- M Skoru (Yüksek harcama = yüksek skor)
        CASE 
            WHEN Monetary >= PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY Monetary) OVER() THEN 5
            WHEN Monetary >= PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY Monetary) OVER() THEN 4
            WHEN Monetary >= PERCENTILE_CONT(0.4) WITHIN GROUP (ORDER BY Monetary) OVER() THEN 3
            WHEN Monetary >= PERCENTILE_CONT(0.2) WITHIN GROUP (ORDER BY Monetary) OVER() THEN 2
            ELSE 1
        END AS M_Skor
    FROM RFM_HamVeri
),

RFM_Segment AS (
    SELECT 
        *,
        (R_Skor + F_Skor + M_Skor) AS ToplamRFM_Skoru,
        CASE 
            WHEN (R_Skor + F_Skor + M_Skor) >= 13 THEN 'VIP Müşteri'
            WHEN (R_Skor + F_Skor + M_Skor) BETWEEN 9 AND 12 THEN 'Sadık Müşteri'
            WHEN (R_Skor + F_Skor + M_Skor) BETWEEN 6 AND 8 THEN 'Orta Seviye Müşteri'
            ELSE 'Düşük Değerli Müşteri'
        END AS MusteriSegmenti
    FROM RFM_SkorHesap
),

RFM_Normalized AS (
    SELECT 
        CustomerID,
        FirstName,
        LastName,
        Recency,
        Frequency,
        Monetary,
        R_Skor,
        F_Skor,
        M_Skor,
        ToplamRFM_Skoru,
        MusteriSegmenti,
        -- Normalize edilmiş değerler (0-1 arası)
        CAST(Recency * 1.0 / MAX(Recency) OVER() AS DECIMAL(4,3)) AS R_Scaled,
        CAST(Frequency * 1.0 / MAX(Frequency) OVER() AS DECIMAL(4,3)) AS F_Scaled,
        CAST(Monetary * 1.0 / MAX(Monetary) OVER() AS DECIMAL(4,3)) AS M_Scaled
    FROM RFM_Segment
)

-- 🔹 Final Çıktı: K-Means Modeline Hazır Veri Seti
SELECT 
    CustomerID,
    FirstName,
    LastName,
    Recency,
    Frequency,
    Monetary,
    R_Skor,
    F_Skor,
    M_Skor,
    ToplamRFM_Skoru,
    MusteriSegmenti,
    R_Scaled,
    F_Scaled,
    M_Scaled
FROM RFM_Normalized
ORDER BY ToplamRFM_Skoru DESC;




