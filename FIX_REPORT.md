# Ders Programı Uygulaması - Düzeltme Notları

Bu sürümde mevcut ekranlar ve özellikler korunarak hata ve kararlılık odaklı düzenlemeler yapıldı.

## Düzeltilen başlıca noktalar

- Projenin kendi `.metadata` ve `pubspec.lock` bilgileriyle uyumlu SDK çizgisi netleştirildi: Flutter 3.38.9 / Dart 3.10.x.
- Android Firebase başlatması, Android uygulamasına ait Firebase kimliğiyle eşleştirildi; web yapılandırması web için korunuyor.
- Firebase başlatma hatalarının sessizce yutulup daha sonra belirsiz hatalara dönüşmesi engellendi.
- Auth / Firestore stream aboneliklerinin giriş-çıkışlarda üst üste binmesi ve çoğalması engellendi.
- Ders, not ve yapılacak verilerini dinleyen abonelikler kullanıcı değişiminde ve provider kapanırken temizleniyor.
- Ders saatleri için HH:mm doğrulaması eklendi; bozuk saat verisinin program gridini çökertmesi engellendi.
- Ders süresi artık başlangıç/bitiş saatinden hesaplanıyor.
- Not hesaplama penceresinde her rebuild'de controller oluşturulması ve Cancel sonrası verinin istemeden değişmesi düzeltildi.
- Ders / not / görev dialoglarındaki controller yaşam döngüsü temizlendi.
- Firestore'da sayıların geçmişte string olarak saklanmış olması gibi veri tipi farklılıklarına karşı model dönüşümleri sağlamlaştırıldı.
- Uzun ders adlarının not/görev kartlarında RenderFlex taşmasına yol açma ihtimali azaltıldı.
- Eski Flutter counter template testi kaldırılıp uygulamanın Course/Note/Todo modellerini kontrol eden testler eklendi.
- AndroidManifest biçimi temizlendi; INTERNET izni korunuyor.
- Makineye özel/generated dosyalar (`.dart_tool`, `build`, `android/.gradle`, `local.properties`, IDE cache'leri ve platform ephemeral klasörleri) paketten çıkarıldı. Bunlar `flutter pub get` / `flutter run` ile yeniden oluşur.
- Uygulamayla ilgisi olmayan GitHub recovery-code dosyası paketten çıkarıldı. Aktifse GitHub hesabından yeni recovery code seti üretmek güvenli olur.

## İlk açılış

VS Code terminalinde proje klasöründe:

```bash
flutter --version
flutter clean
flutter pub get
flutter analyze
flutter run
```

`flutter --version` çıktısında bu proje için **Flutter 3.38.9** kullanılması önerilir. Eski 3.32.8 SDK yolu bu projedeki yeni Flutter API'leri ve Android template sürümleriyle uyuşmuyordu.

## Doğrulama notu

Düzeltme ortamında Flutter SDK kurulu olmadığı için `flutter analyze`, `flutter test` ve gerçek cihaz/emülatör çalıştırması burada yürütülemedi. Dart dosyaları için sözdizimi/blok kontrolü; JSON/XML/YAML dosyaları için parse doğrulaması yapıldı. Son çalışma zamanı kontrolü yukarıdaki komutlarla yerel Flutter 3.38.9 ortamında yapılmalıdır.
