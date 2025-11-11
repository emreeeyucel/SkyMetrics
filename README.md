# 🚀 SkyMetrics: MSSQL ile Havayolu Veri Analizi ve RFM Segmentasyonu

Bu projede, gerçek dünyadaki bir havayolu e-ticaret sistemini temsil eden bir veri seti tasarladım ve **iş zekâsı odaklı SQL analizleri** gerçekleştirdim.

---

## 🎯 Projenin Amacı

Havayolu şirketinin uçuş verileri üzerinden **müşteri sadakati, gelir kârlılığı, uçuş alışkanlıkları ve çalışan performansını** kapsamlı SQL analizleriyle inceleyerek **veri odaklı içgörüler üretmek**.  
Amaç, **müşteri segmentasyonu, gelir optimizasyonu ve operasyonel verimlilik** açısından stratejik kararları destekleyecek analitik bir altyapı oluşturmaktır.

---

## 🧩 Veri Modeli (ERD)

Aşağıda projede kullanılan veri modelinin (Entity Relationship Diagram) görseli yer almaktadır:

![ERD Diagram](A_Entity-Relationship_Diagram_(ERD)_in_a_digital_2.png)

**Tablolar:**
- Customers  
- Tickets  
- Flights  
- Sales  
- Employees  
- Departments  

---

## 📊 Gerçekleştirilen Analizler

### 🔹 Müşteri Analizi
- Toplam bilet sayısı, toplam gelir, ortalama bilet fiyatı  
- En çok uçulan varış noktaları  
- En fazla gelir getiren ilk 5 müşteri  
- Ortalama üstü müşterilerin harcama davranışları (çok uçan = çok harcayan mı?)  
- Sadakat ve frekans bazlı segmentasyon  
- Uçuş sınıfı (SeatClass) tercih analizi  
- Zaman bazlı (aylık) müşteri harcama ve trend analizi  
- Churn (terk) analizi  

### 🔹 RFM Analizi ve Segmentasyon
- Recency, Frequency, Monetary skorları  
- VIP, Sadık, Orta ve Düşük Değerli müşteri grupları  
- **PERCENTILE_CONT** fonksiyonu ile dinamik yüzde dilimlerine göre segmentasyon  
- Normalizasyon ve K-Means için hazır veri üretimi  

### 🔹 Uçuş ve Rota Analizi
- En kârlı rotalar  
- Mevsimsellik (Yoğun/Sakin dönem) analizi  
- **Rota bazlı mevsimsellik analizi:** her uçuş hattının yoğun/sakin dönemleri tespit edilmiştir  
- Rota bazlı gelir karşılaştırmaları  

### 🔹 Çalışan Performans Analitiği
- Satış performansı sıralaması  
- Maaş ve kıdem verimliliği üzerinden **Performans Endeksi** hesaplama  
- **Z-score yaklaşımıyla** maaş, kıdem ve satış metrikleri normalize edilerek çalışan segmentasyonu yapılmıştır  

---

## 🧠 Kullanılan SQL Teknikleri
- **CTE (Common Table Expressions)**  
- **Window Functions (ROW_NUMBER, RANK, LAG, AVG OVER)**  
- **RFM scoring & segmentation**  
- **PERCENTILE_CONT** ile dinamik yüzdelik dilim hesaplama  
- **Zaman serisi & trend analizi**  
- **CASE yapıları** ve segment bazlı koşullu analizler  
- **Z-score normalizasyonu** ile çalışan performansını standartlaştırma  



## 💡 Sonuç
Bu proje, SQL’in analitik gücünü kullanarak **müşteri davranışı, gelir trendleri ve çalışan performansını** bütünsel şekilde analiz eden kapsamlı bir **veri zekâsı çalışmasıdır**.


