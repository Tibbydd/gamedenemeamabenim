# CURSOR: Fragments of the Forgotten

**Cursor: Fragments of the Forgotten**, Android cihazlar için geliştirilen, izometrik görünümlü, stilize piksel art grafiklere sahip, randomly generated dungeon crawler türünde bir aksiyon-macera oyunudur.

## 🎮 Oyun Konsepti

Gelecekte, insan zihni dijitalleştirilebilmektedir. Ancak ölen insanların zihinsel verileri Fragment Vaults adı verilen sanal yapılarda kilitli kalır. Oyuncu bir "Cursor"dur — bu sanal yapılara girerek bozulmuş zihinleri temizleyen bir zihin hacker'ı. Her zindan, bir bireyin zihinsel harabelerinden oluşur.

## ✨ Temel Özellikler

### 🌀 Procedural Dungeon Generation
- Her zindan, bir bireyin zihinsel profiline göre AI destekli olarak rastgele oluşturulur
- Duygusal temalar: "Pişmanlık Katı", "Öfke Arenası", "Unutulmuş Oda"
- Her duygu türü farklı zindan yapısı ve zorluk seviyesi oluşturur

### 🧠 Cursor Tool Sistemi
- **CTRL-Z (Time Rewind)**: Ölümden birkaç saniye öncesine dönme
- **Code Injection**: Düşman davranışlarını değiştirme
- **Data Leak**: Gizli yollar ve anıları açığa çıkarma
- **Memory Scan**: Yakındaki hafıza parçalarını tespit etme

### 🧩 Hafıza Sistemi
- Zihin bulmacaları ve anı rekonstrüksiyonu
- Etik seçimler: Hafızayı silmek mi, paylaşmak mı?
- Duygusal bağlantılı hafıza parçaları

### 📱 Mobil Optimizasyon
- Tek parmakla sürükle-bırak kontrol sistemi
- Dokunmatik ekran için optimize edilmiş UI
- Dikey ekran orientasyonu

## 🛠️ Teknik Detaylar

### Platform
- **Engine**: Godot 4.3
- **Target Platform**: Android
- **Rendering**: 2D with isometric view
- **Graphics**: Pixel art style

### Proje Yapısı
```
📁 scenes/          # Oyun sahneleri (.tscn dosyaları)
📁 scripts/         # GDScript kodları
  📁 singletons/    # Global sistem scriptleri
  📁 player/        # Oyuncu kontrol scriptleri
  📁 enemies/       # Düşman AI scriptleri
  📁 systems/       # Oyun sistemleri
📁 assets/          # Grafikler, sesler, vb.
  📁 sprites/       # Sprite dosyaları
  📁 audio/         # Ses dosyaları
  📁 icons/         # UI ikonları
```

### Temel Sistemler
- **GameManager**: Oyun durumu ve ilerleyiş yönetimi
- **DungeonGenerator**: Procedural zindan oluşturma
- **MemorySystem**: Hafıza parçaları ve rekonstrüksiyon
- **HackingSystem**: Cursor tool'ları ve mini oyunlar

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Godot 4.3 veya üzeri
- Android SDK (mobil export için)

### Geliştirme Ortamı
1. Bu repository'yi klonlayın
2. Godot'ta `project.godot` dosyasını açın
3. F5 ile oyunu çalıştırın

### Kontroller
- **Mouse/Touch**: Hareket için sürükle-bırak
- **Z**: Time Rewind hack tool
- **X**: Data Leak hack tool  
- **C**: Memory Scan hack tool

## 🎯 Mevcut Durum

Bu proje henüz geliştirme aşamasındadır. Şu anki durumda:

### ✅ Tamamlanan Özellikler
- ✅ **Temel Framework**: Godot 4.3 projesi, singleton sistemleri
- ✅ **Procedural Graphics**: Duygusal tema bazlı dinamik sprite oluşturma
- ✅ **Enemy AI**: 3 farklı düşman tipi (Corruptor, Looper, PhantomMemory)
  - Corruptor: Saldırgan, corruption yayan, rage modu
  - Looper: Pattern takip eden, duplicate yaratan, temporal saldırılar
  - PhantomMemory: Hayalet, hafıza çalan, illusion yaratan
- ✅ **Cursor Tools**: Tam işlevsel hack araçları
  - Time Rewind (CTRL-Z): Gerçek zaman geri sarma
  - Code Injection: Düşman davranış değiştirme
  - Data Leak: Gizli içerik açığa çıkarma
  - Memory Scan: Hafıza parçası tespiti
- ✅ **Visual Effects**: Cyberpunk stil görsel efektler
  - Glitch efektleri, data stream'ler, explosion parçacıkları
  - Matrix rain, hologram efektleri, scan lines
  - Cyberpunk UI styling (neon borders, glow effects)
- ✅ **Dynamic Dungeon Rendering**: Emotion-based tile generation
- ✅ **Memory System**: Türkçe hafıza içerikleri, emotional profiling
- ✅ **Mobile Touch Controls**: Optimized drag-to-move system

### 🔄 Yeni Eklenen (Bu Güncellemede)
- 🎨 **Procedural Sprite Generation**: Tamamen dinamik piksel art
- 🤖 **Advanced Enemy AI**: Üç benzersiz düşman tipi ve davranışları
- ✨ **Visual Effects System**: 15+ farklı görsel efekt
- 🎮 **Enhanced UI**: Cyberpunk temalı arayüz tasarımı
- 🔧 **Code Injection System**: Düşman hack mekanikleri

### 📋 Gelecek Planlar
- Hikaye modu
- Multiplayer "ghost" sistemi
- Daha gelişmiş procedural generation
- Mobile-specific optimizasyonlar
- Google Play Store yayınlama

## 🎨 Sanat Yönergeleri

### Görsel Stil
- İzometrik 2.5D perspektif
- Piksel art (16x16 base tile size)
- Cyberpunk/digital tema
- Renk paleti: Soğuk mavi, mor, neon aksentleri
- Glitch efektleri ve dijital bozulmalar

### UI Tasarım
- Minimalist ve modern
- Semi-transparent paneller
- Neon çerçeveler
- Cyberpunk tipografi

## 📄 Lisans

Bu proje MIT lisansı altında geliştirilmektedir.

## 🤝 Katkı

Projeye katkıda bulunmak isteyenler:
1. Fork yapın
2. Feature branch oluşturun
3. Değişikliklerinizi commit edin
4. Pull request açın

## 📧 İletişim

Proje hakkında sorularınız için issue açabilirsiniz.

---

**Not**: Bu oyun konsepti ve geliştirme projesi, modern oyun tasarımı prensipleri ve mobil platform gereksinimleri göz önünde bulundurularak tasarlanmıştır.