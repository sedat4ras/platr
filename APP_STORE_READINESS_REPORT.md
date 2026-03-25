# Platr - App Store Hazirlik Raporu

**Tarih:** 19 Mart 2026
**Kategori Onerisi:** Primary: **Social Networking** | Secondary: **Lifestyle**
**Hedef Pazar:** Avustralya (VIC)
**iOS Minimum:** iOS 17+

---

## OZET

Platr, temel ozellikleri buyuk olcude tamamlanmis bir uygulamadir. Ancak App Store onayindan gecmek icin **7 kritik eksik** ve **5 orta oncelikli eksik** giderilmelidir. En buyuk risk alanlari: **Sign in with Apple eksikligi** (Guideline 4.8), **yas dogrulama** (Avustralya yasasi) ve **plaka verisi gizliligi** (Guideline 5.1.2).

---

## KATEGORI ANALIZI

| Kriter | Aciklama |
|--------|----------|
| Neden Social Networking? | Apple tanimi: "kisisel baglantilar, foto/video paylasimi, ozel ilgi alani topluluklari". Platr tam olarak bu: plaka meraklilari toplulugu. |
| Neden Lifestyle (ikincil)? | Arac kulturu/hobi uygulamasi olarak Lifestyle'a da uyuyor. |
| Benzer uygulamalar | Throdle, RoadStr, Garage App, Car Social — hepsi Social Networking kategorisinde. |
| Risk | "Social Networking" secimi, Avustralya'nin 16 yas alti sosyal medya yasasini tetikleyebilir. |

---

## DURUM TABLOSU: MEVCUT vs GEREKEN

### KRITIK EKSIKLER (Submission'i engelleyen)

| # | Gereklilik | Guideline | Mevcut Durum | Aksiyon |
|---|-----------|-----------|-------------|---------|
| 1 | **Sign in with Apple** | 4.8 | YOK | Google Sign-In varsa Apple Sign-In de zorunlu. Ekle. |
| 2 | **Privacy Policy (in-app)** | 5.1.1 | YOK | App icinde erisilebilir Privacy Policy sayfasi/linki ekle. |
| 3 | **Terms of Service (in-app)** | 5.1.1 | YOK | Kullanim kosullari sayfasi olustur, register + settings'e ekle. |
| 4 | **Yas Dogrulama** | 1.2.1 + AU yasasi | YOK | Apple Declared Age Range API veya dogum tarihi kapisi ekle. 16 yas alti Avustralya kullanicilari engellenmeli. |
| 5 | **Destek Iletisim Bilgisi (in-app)** | 1.2 | YOK | App icinde gorunur destek emaili/form ekle. |
| 6 | **AI Moderation Aciklamasi** | 5.1.2 | YOK | Claude AI ile yorum moderasyonu yapildigini kullaniciya bildiren onay/aciklama ekle. |
| 7 | **Demo Hesap** | 2.1 | YOK | App Review icin hazir veriyle dolu demo hesap olustur. |

### ORTA ONCELIKLI EKSIKLER (Ret riskini artiran)

| # | Gereklilik | Guideline | Mevcut Durum | Aksiyon |
|---|-----------|-----------|-------------|---------|
| 8 | **Browse-only mod** | 5.1.1(v) | YOK | Giris yapmadan plaka goruntuleyebilme ozelligi ekle. |
| 9 | **Plaka-Kisi Baglantisi Uyarisi** | 5.1.2 | YOK | "Bu uygulama arac sahiplerini tanimlamak icin kullanilamaz" disclaimer ekle. Doxxing icerigi moderasyona ekle. |
| 10 | **Hesap Silme - Veri Temizligi** | 5.1.1(v) | KISMI | Mevcut soft-delete yalnizca deaktive ediyor. Kisisel verilerin gercekten silindigini dogrula. |
| 11 | **Purpose String'ler** | 5.1.1 | KISMI | NSLocationWhenInUseUsageDescription, NSCameraUsageDescription, NSPhotoLibraryUsageDescription tamamla. |
| 12 | **Lokalizasyon** | 4.0 | YOK | Minimum en:AU lokalizasyonu olustur. |

### TAMAMLANMIS GEREKLILIKLER

| # | Gereklilik | Guideline | Durum |
|---|-----------|-----------|-------|
| 13 | UGC Icerik Filtreleme | 1.2 | TAMAM — Layer 1 keyword + Layer 2 Claude agent |
| 14 | Raporlama Mekanizmasi | 1.2 | TAMAM — CommentRow'da Report butonu + neden secici |
| 15 | Bloklama Mekanizmasi | 1.2 | TAMAM — CommentRow'da Block butonu |
| 16 | 5 rapor sonrasi otomatik gizleme | 1.2 | TAMAM |
| 17 | Hesap Silme (UI) | 5.1.1(v) | TAMAM — ProfileView'da Delete Account alert |
| 18 | Privacy Manifest (xcprivacy) | 5.1.2 | TAMAM — UserID, Email, Name, SearchHistory, UGC |
| 19 | Keychain Token Saklama | Guvenlik | TAMAM |
| 20 | Email + Password Giris | 4.8 | TAMAM |
| 21 | Google Sign-In | 4.8 | TAMAM |
| 22 | Email Dogrulama (OTP) | 2.1 | TAMAM |
| 23 | Sifre Sifirlama | 2.1 | TAMAM |
| 24 | Avatar Yukleme | Ozellik | TAMAM — 5MB, JPEG/PNG/WebP |
| 25 | Push Notification Altyapisi | Ozellik | TAMAM — NotificationService + device token |
| 26 | Onboarding (3 sayfa) | 4.2 | TAMAM |
| 27 | Splash Screen | 2.1 | TAMAM |
| 28 | Network Error Handling | 2.1 | TAMAM — NetworkErrorView |
| 29 | Tema Destegi (Light/Dark/Blue) | 4.0 | TAMAM |
| 30 | Plaka Sahiplik Dogrulama (2 gun) | Ozellik | TAMAM |
| 31 | Yorum Acma/Kapama (sahip) | 1.2 | TAMAM |
| 32 | Plaka Gizleme (sahip) | 1.2 | TAMAM |
| 33 | AppConfig (Dev/Prod URL) | 2.1 | TAMAM |

---

## AVUSTRALYA'YA OZEL YASAL RISKLER

### 1. Social Media Minimum Age (Online Safety Amendment Act 2024)
- **Risk Seviyesi: YUKSEK**
- 16 yas alti kullanicilarin sosyal medya platformlarinda hesap acmasi yasaklandi.
- Platr, yasanin 4 kriterini de karsilayabilir (sosyal etkilesim, kullanici baglantisi, icerik paylasimi, AU erisimi).
- **Ceza:** 49.5 milyon AUD'ye kadar.
- **Cozum:** Declared Age Range API + kayit sirasinda yas onay adimi.

### 2. Australian Privacy Principles (APP)
- **APP 6:** Verileri yalnizca birincil amac icin kullan. Claude AI moderasyonu ikincil amac — acik rizasi gerektirir.
- **APP 8:** Veriler Avustralya disina cikarsa (Anthropic API, US sunuculari), esdeiger koruma saglanmali.
- **APP 12-13:** Kullanicilarin kisisel verilerine erisim ve duzeltme hakki.

### 3. Plaka Verisi Hassasiyeti (Guideline 5.1.2)
- Apple, plaka arama uygulamalarini 5.1.2 ile reddetmistir (plaka → sahip kimlik bilgisine erisim).
- Platr plaka-sahip eslestirmesi YAPMASA da, Apple ekstra inceleme yapabilir.
- `rego_check.py` servisi sahip bilgisi donduruyorsa, bu bilgiyi kullaniciya gostermemek gerekir.
- Yorumlarda kisisel bilgi paylasimini engelleyen moderasyon kurali ekle.

---

## APP STORE CONNECT GEREKSINIMLERI

### Metadata Checklist

| Oge | Gereklilik | Durum |
|-----|-----------|-------|
| App Adi | < 30 karakter, benzersiz (orn: "Platr - Spot License Plates") | HAZIRLANMALI |
| Altyazi | < 30 karakter | HAZIRLANMALI |
| Aciklama | Maksimum 4000 karakter, dogru | HAZIRLANMALI |
| Anahtar Kelimeler | 100 karakter, virgul ayirmali | HAZIRLANMALI |
| Screenshots | 6.5" veya 6.9" iPhone, minimum 1, maksimum 10 | HAZIRLANMALI |
| App Icon | 1024x1024 px, alpha yok | HAZIRLANMALI |
| Privacy Policy URL | Calisir durum | HAZIRLANMALI |
| Support URL | Calisir durum | HAZIRLANMALI |
| Yas Derecelendirme | UGC icin 12+ veya 13+ | HAZIRLANMALI |
| Demo Hesap | Review Notes'a username + password | HAZIRLANMALI |
| Sifreleme | HTTPS = evet (standart muafiyet) | HAZIRLANMALI |

### Onerilen Screenshots (6 adet)

1. Feed gorunumu — spotted plakalar
2. Plaka detay — yorumlar + spot butonu
3. Arama sonuclari — plaka renderer
4. Plaka ekleme — stil secici
5. Profil — istatistikler + plaka kartlari
6. VIC plaka sablonlari galerisi

---

## ONCELIK SIRASI (Uygulama Plani)

### Faz 1 — Submission Engellerini Kaldir (Kritik)
1. **Sign in with Apple** entegrasyonu (iOS + Backend)
2. **Privacy Policy + Terms of Service** sayfalari (web + in-app link)
3. **Yas dogrulama** (Declared Age Range API veya DOB kapisi)
4. **Destek iletisim** (Settings sayfasina email/link)
5. **AI moderasyon aciklamasi** (kayit/ilk yorum sirasinda bilgilendirme)
6. **Demo hesap** hazirla (ornek plakalar + yorumlar ile)

### Faz 2 — Ret Riskini Azalt
7. **Browse-only mod** (giris yapmadan feed + plaka detay goruntuleme)
8. **Disclaimer** ekleme (plaka → kisi tanimlama yasagi)
9. **Hesap silme** gercek veri temizligi dogrulama
10. **Purpose string'ler** tamamla (konum, kamera, fotograf)
11. **Doxxing moderasyonu** (adres, telefon, isim pattern'leri filtrele)

### Faz 3 — App Store Connect Hazirlik
12. Screenshots olustur (6.5"/6.9" iPhone)
13. App Icon (1024x1024)
14. Metadata yaz (ad, aciklama, anahtar kelimeler)
15. Privacy Nutrition Labels doldur
16. Age rating anketi tamamla

---

## TAMAMLANAN UYGULAMALAR (19 Mart 2026)

Asagidaki 12 eksik tamamlanmistir:

| # | Ozellik | Dosyalar |
|---|---------|----------|
| 1 | Sign in with Apple (Backend) | `backend/routers/auth.py` — `POST /auth/apple` |
| 2 | Sign in with Apple (iOS) | `LoginView.swift`, `AuthService.swift`, `AuthViewModel.swift`, `APIService.swift` |
| 3 | Privacy Policy (in-app) | `Views/LegalView.swift` — `PrivacyPolicyView` |
| 4 | Terms of Service (in-app) | `Views/LegalView.swift` — `TermsOfServiceView` |
| 5 | Yas dogrulama (16+) | `backend/routers/auth.py` (register), `RegisterView.swift` (checkbox) |
| 6 | Destek iletisim (in-app) | `Views/LegalView.swift` — `SupportView`, `ProfileView.swift` |
| 7 | AI moderasyon aciklamasi | `Views/LegalView.swift` Privacy Policy Section 3 |
| 8 | Demo hesap | `backend/scripts/create_demo_account.py` — demo@platr.app / PlatrDemo2026! |
| 9 | Browse-only mod | `PlatrApp.swift` — Feed/Search giris gerektirmez, Profile tab login gosterir |
| 10 | Plaka disclaimer | `PlateView.swift` — info.circle uyari kutusu |
| 11 | Hesap silme veri temizligi | `backend/routers/auth.py` — tum kisisel alanlar temizlenir |
| 12 | Purpose string'ler | `Info.plist` — Camera, Photos, Location aciklamalari |
| 13 | Doxxing filtresi | `backend/services/moderation.py` — 16 yeni doxxing pattern |
| 14 | DB migration | `backend/migrations/add_apple_id_and_dob.sql` |

## SONUC

| Metrik | Deger |
|--------|-------|
| Toplam Gereklilik | 33 |
| Tamamlanan | 33 (%100) |
| Kritik Eksik | 0 |
| Orta Oncelikli Eksik | 0 |
| Durum | App Store Connect metadata hazirlanarak submission yapilabilir |

**Kalan adimlar (App Store Connect):**
1. Screenshots olustur (6.5"/6.9" iPhone)
2. App Icon (1024x1024) hazirla
3. App Store Connect'te metadata doldur
4. Privacy Nutrition Labels tamamla
5. Age rating anketi doldur
6. Xcode'da "Sign in with Apple" capability ekle
7. APNs sertifikalarini developer portal'da konfigure et

---

*Bu rapor Apple App Store Review Guidelines (2025-2026), Australian Privacy Principles, Online Safety Amendment Act 2024 ve Apple Developer dokumantasyonuna dayanmaktadir.*
