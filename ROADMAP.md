# SimpleOS — Roadmap (Faz 10 sonrası uzun vade)

`todos.md` bizi **Faz 10'a** (init + shell + temel userland) kadar götürüyor.
Oraya varınca "komut yazıp çıktı gören" bir OS olacak. Bu dosya bundan
sonrasını — macOS kalitesinde animasyon, modern masaüstü OS özellikleri,
uygulama ekosistemi, platforma özgü fikirler — planlıyor.

**Tasarım ilkeleri**
- **Hız > minimal olmak zorunda degil ama optimize RAM**. Sayfa cache'i, pre-load, JIT derleme serbest.
- **Windows kolaylığı** — tak-çalıştır, sezgisel ayar ekranları, tek tıkla
  kurulum — ama **Linux temizliği** — pipe/composable programlar, /etc
  düz-metin, scriptable her şey.
- **macOS kalitesinde UX** — spring physics animasyon, 60/120 Hz sync,
  SDF-based UI, HiDPI-aware her şey.
- **Monitor-agnostic** — VRR, multi-monitor, mixed DPI, HDR.
- **Özgün olabilir** — Linux/Unix kopyası olmak zorunda değiliz.
  Kullanıcıya ait alanda (UX, compositor, dağıtım) radikal fikirlere açığız.

---

## İlerleme (2026-04-24)

Şimdiye kadar ROADMAP'ten **Faz 11** (ilk GPU stack'i) işlendi. Aşağıdaki
üst-düzey parçalar kernel'de canlı:

- **PCI bus enumeration** — `kernel/src/pci/pci.c`. Class/subclass +
  BAR probe (32/64-bit, size discovery), `pci_find_class` /
  `pci_find_id` / iterator API. Bütün gelecek sürücüler bunu kullanıyor.
- **GPU device probe** — `kernel/src/gpu/gpu.c`. Display-class
  (`0x03`) taraması; Intel/NVIDIA/AMD algılanıyor, log atılıyor,
  gerçek sürücü Faz 12/13'e ertelendi.
- **VirtIO transport** — `kernel/src/gpu/virtio.c`. Modern PCI cap
  layout (common/notify/isr/device), virtqueue setup, feature
  negotiation, submit+poll.
- **VirtIO-GPU 2D driver** — `kernel/src/gpu/virtio_gpu.c`.
  GET_DISPLAY_INFO → RESOURCE_CREATE_2D → ATTACH_BACKING (contiguous
  DMA) → SET_SCANOUT → TRANSFER_TO_HOST_2D + RESOURCE_FLUSH.
  QEMU `-vga virtio` ile ekrana render ediyor.
- **Contiguous PMM alloc** — `pmm_alloc_contig(n)` bitmap üstünde
  N-run bulur, DMA buffer'ları için şart.
- **Display abstraction** — `kernel/src/gpu/display.c`.
  `struct display` (pixels, pitch, width, height, `double_buffered`,
  present). VirtIO-GPU primary; yoksa Limine FB fallback. Üst katmanlar
  backend-agnostik.
- **Single-buffer scanout** — VirtIO-GPU driver'ı artık tek resource'a
  bind ediyor (`SET_SCANOUT` bir kez, her `present` yalnızca
  `TRANSFER_TO_HOST_2D` + `RESOURCE_FLUSH`). SET_SCANOUT'u her frame
  değiştirmek QEMU host display'inde flicker yaratıyordu (Faz 12.4.1).
  İkinci backing hala allocate — future triple-buffer yolu için
  rezerv. Gerçek vblank tabanlı ping-pong Faz 12+'da GPU VSYNC IRQ'ya
  bağlı gelecek.

### Faz 11 sonrası en ivedi kolon yok
Aşağıdaki bölümlerdeki `[ ]` maddeler hala yapılacaklar. Bu
"İlerleme" başlığı her büyük milestone'da güncellensin.

---

## 1. Grafik & kompozisyon katmanı  (Faz 11–13)

"macOS kalitesinde cam netliğinde" burada başlıyor — **CPU 2D blit
kalıcı render modelidir**, GPU shader yolu denenmiyor. Freestanding
kernel + `-mgeneral-regs-only` ile rep-movsq ve manuel vektorleştirmeyle
modern donanımda memory-bandwidth-bound performansta ilerliyoruz.

- [x] **Display backend**: Bochs / std VGA üstünden Limine framebuffer
  (tek yol, GPU/VirtIO-GPU kodu Faz 12.6'da silindi). Software shadow
  buffer, IRQ-off atomic publish (cli/sfence), rep-movsq rect memcpy;
  1280x800 @ 120 Hz'te frame 3-4 ms.
- [x] **CPU 2D compositor**: surface + z-sort + alpha blit + 120 Hz
  thread + per-surface damage tracking + scissor-clipped clear+blit.
  Statik sahnede ~3 µs frame, animasyonlu sahnede ~3-4 ms, frame'lerin
  çoğu zero-damage ile short-circuit (present bile yok).
- [x] **Damage tracking + atomic rect publish** (Faz 12.5): per-surface
  prev-vs-curr diff, greedy-merge damage list (max 16 rect, overflow'da
  bbox'a collapse), scissor-clipped clear+blit, shadow→hw_fb rect
  memcpy IRQ-off + sfence.
- [x] **Multi-core compositor** (Faz 12.6): damage bbox horizontal
  band'lere bölünüyor, her online CPU bir band'i (BSP + APs) atomic
  fetch-add tile counter üzerinden claim edip scissor-clipped compose
  ediyor. APs artık idle değil — compositor_ap_worker'da epoch üzerinde
  bekliyor, frame başına uyanıyor. Min band = 32 rows; üstünde tile
  sayısı CPU count ile eşleşiyor. Stats: `cpus=4 bsp-tiles=N ap-tiles=M`.
- [x] **Animation engine** (Faz 12.3): spring physics (stiffness/
  damping, semi-implicit Euler), easing curves (linear, in/out/in-out
  cubic, out-back), Q16.16 fixed-point (kernel float yok), retarget,
  ping-pong loop, bind-to-i32/u8. Profesyonel tamamlama Faz 12.5.5'te
  (bezier, cubic-bezier arbitrary, declarative `animate()` API).
- [ ] **SIMD blit** (Faz 12.5.x): SSE2 / AVX2 alpha blend fast-path.
  `-mgeneral-regs-only` gerekli özel include + runtime CPUID detect.
- [ ] **Vsync senkronu**: Host display refresh'i ile kilitlenme (şimdilik
  120 Hz uniform); gerçek VSYNC IRQ gerçek donanım sürücüsüyle gelecek.
- [ ] **Rounded corners + shadow + gradient** (Faz 12.7): SDF-based
  corner mask, box shadow convolution, linear/radial gradient shader.
- [ ] **Font rendering** (Faz 12.9): stb_truetype entegrasyonu, subpixel
  AA, harfler için SDF cache, UTF-8, Türkçe + Emoji.
- [ ] **Vector graphics**: path rasterizer (2D, anti-aliased).
- [ ] **Color management**: sRGB ↔ linear, HDR10, per-monitor ICC profilleri

## 2. Pencere sistemi  (Faz 11–12)

- [ ] **Display server**: Wayland-ish — her client kendi surface'ini submit
  eder, compositor birleştirir. Protocol kendi tasarımımız (basit, tip-güvenli)
- [ ] **Window manager**: move/resize/minimize/maximize, snap layouts,
  virtual desktops, pencere geçiş animasyonları
- [ ] **Input routing**: klavye fokusu, pointer capture, drag & drop
- [ ] **IME**: Türkçe F/Q klavye düzeni, dead-key, CJK/emoji girişi için
  compose protocol
- [ ] **Wayland/Xwayland köprüsü**: Linux binary'leri çalıştırmak istersek
  (opsiyonel — kendi native app modeli yeterli de olabilir)

## 3. UI toolkit & tema  (Faz 13)

- [ ] **Widget library**: button, label, textfield, slider, scrollview,
  list, grid, toolbar, tab, tree, chart. Hepsi animasyonlu.
- [ ] **Layout**: constraint-based (iOS Auto Layout benzeri), grid, flex
- [ ] **Theming**: tek bir JSON/TOML ile tüm sistem rengi, köşe yumuşaklığı,
  typography değişsin
- [ ] **Accessibility primitives**: VoiceOver benzeri screen reader API,
  focus rings, high-contrast mode
- [ ] **Dark / light**: system-wide switch, per-app override, otomatik
  sunrise/sunset
- [ ] **Declarative UI framework**: SwiftUI / Jetpack Compose tarzı — state
  değişir, view ağacı otomatik diff'lenir

## 4. Display yönetimi  (Faz 11)

- [ ] **EDID/DisplayID parse** — monitor native resolution, Hz, HDR cap'leri
- [ ] **Multi-monitor topology** — sanal geniş canvas, pencereler monitörler
  arasında sürüklensin, her monitörün DPI'ı ayrı uygulansın
- [ ] **Resolution + refresh switch** — runtime mode set (GPU CRTC reprogram)
- [ ] **Variable Refresh Rate (VRR / Adaptive Sync)** — G-Sync/FreeSync
- [ ] **HDR** — 10-bit framebuffer, tone mapping
- [ ] **Monitor hot-plug** — takılınca otomatik düzenleme
- [ ] **Rotation & scaling** — dikey monitor, 150%/200% HiDPI
- [ ] **Night shift / true tone** — color temperature shift
- [ ] **Per-app fullscreen with mode switch**

## 5. Ses  (Faz 14)

- [ ] HDA / Intel AC'97 / VirtIO-sound sürücüsü
- [ ] Kernel audio subsystem: PCM stream'leri, sample rate conversion,
  mixing (düşük latency)
- [ ] System audio server (PulseAudio/PipeWire tarzı) — user-space mixer
- [ ] Volume control, per-app volume, audio device switch
- [ ] Spatial audio hook'u (future)

## 6. Depolama & dosya sistemleri  (Faz 14–15)

- [ ] **Disk sürücüleri**: AHCI (SATA), NVMe, VirtIO-blk
- [ ] **Read/write FS**: önce ext2 yazma, sonra basit kendi COW FS
  ("SimpleFS") — snapshot destekli
- [ ] **Block cache** (LRU, write-back, periodic flush)
- [ ] **VFS mount points**, bind mounts
- [ ] **Partition tablosu**: GPT okuma, partition oluşturma
- [ ] **LUKS-benzeri disk şifreleme** (opsiyonel ama güvenlik için iyi)
- [ ] **initramfs → root FS geçişi**
- [ ] **USB storage** (USB subsystem + mass storage class)

## 7. Ağ  (Faz 15–16)

- [ ] **NIC sürücüsü**: önce VirtIO-net, sonra Intel e1000/e1000e/rtl8139
- [ ] **TCP/IP stack**: IPv4/IPv6, TCP, UDP, ICMP, ARP
- [ ] **Socket API** (POSIX-uyumlu), epoll/kqueue tarzı async I/O
- [ ] **DNS resolver**, DHCP client
- [ ] **TLS**: BearSSL veya kendi küçük TLS 1.3 impl
- [ ] **HTTP stack** (client + server library)
- [ ] **WiFi**: çok büyük iş. İleride, belki iwd portu
- [ ] **Firewall** (nftables-ish, kural listesi kernel'de)

## 8. Proses, IPC, çekirdek olgunlaşması  (Faz 11+)

- [ ] Per-process PML4 (Faz 10 sonrası gerçek `fork()`)
- [ ] `fork()` + `execve()` + `waitpid()` + `pipe()`
- [ ] **Signals**: SIGTERM, SIGINT, SIGCHLD + handler restart
- [ ] **Shared memory** (`shm_open`, `mmap`)
- [ ] **Message passing** (Mach-ports benzeri veya D-Bus basit hali)
- [ ] **Futex** (user-space mutex/condvar için)
- [ ] **Threads** (pthread-compat)
- [ ] **POSIX AIO** / **io_uring** tarzı async I/O
- [ ] **cgroups** benzeri resource sınırlaması (CPU quota, mem limit)
- [ ] **seccomp-bpf** tarzı syscall filtering

## 9. Uygulama çerçevesi (SDK)  (Faz 13+)

Kullanıcının uygulama yazabilmesi için gereken her şey.

- [ ] **Stable syscall ABI** — sürümler arası kırılmasın
- [ ] **libc genişleme** — tam POSIX uyum (ideal olarak musl uyumlu)
- [ ] **C++ support** — libstdc++ ya da libc++ port
- [ ] **Standart kütüphaneler**: UI, file, network, audio, graphics
- [ ] **Native app format**: ELF + manifest (permissions, app id, icon)
- [ ] **Sandboxing model**: capability-based (her app ne izin istiyor beyan eder)
- [ ] **App lifecycle**: launch, suspend, resume, quit, state restore
- [ ] **IPC for apps**: broker-mediated, manifest'e göre izinli
- [ ] **Language bindings**: Rust, Go, Zig için SDK
- [ ] **IDE / SDK dağıtımı**: SimpleOS üstünde SimpleOS app yazabilmeli

## 10. Paket yöneticisi  (Faz 15+)

- [ ] Binary paket formatı (signed, transactional kurulum)
- [ ] Dependency resolver
- [ ] Central repo + mirror sistemi (ileride self-host, başta bir sunucu yeter)
- [ ] Atomic update (snapshot + rollback)
- [ ] User-space pkg (Homebrew tarzı, admin gerekmeden kullanıcı için)
- [ ] GUI store (screenshot, rating, install tek tık)
- [ ] Developer'lar için tek komutla `simpleos-pkg publish`

## 11. Kullanıcı deneyimi  (Faz 12+)

- [ ] **Boot splash** — logo + progress, animasyonlu
- [ ] **Login ekranı** — kullanıcı avatar, Touch-ID-benzeri (şifre + PIN)
- [ ] **Setup sihirbazı (OOBE)** — ilk açılışta dil/zaman/kullanıcı oluştur
- [ ] **Desktop environment** — wallpaper, dock, menu bar, notifications
- [ ] **Launcher / Spotlight** — ⌘+Space tarzı — fuzzy search, system-wide
- [ ] **Notification center**
- [ ] **Control center** — WiFi, Bluetooth, brightness, volume pop-up
- [ ] **Settings app** — modular, search-enabled
- [ ] **System-wide undo** hedefi — dosya sil undo, ayar değişikliği undo
- [ ] **Screenshot / screen recording** — ⌘⇧4 kadrajla, sürükle bırak
- [ ] **Clipboard history** (default on — verimlilik için)
- [ ] **Widgets** — desktop yan paneline canlı bilgi

## 12. Güvenlik  (Faz 13+)

- [ ] **Authentication** — `/etc/passwd` → sonra secure enclave benzeri
  credential store; PIN + şifre + parmak izi (donanım destekli)
- [ ] **Per-user home dir**, uid/gid, permission model
- [ ] **App sandboxing** (bkz. Faz 9 SDK)
- [ ] **Code signing** — native app'ler imzalı olmak zorunda (bypass modu var)
- [ ] **Secure boot chain** — UEFI Secure Boot + kernel imzası doğrulama
- [ ] **Full-disk encryption** (LUKS-ish)
- [ ] **Syscall audit log** (opsiyonel, debug için)
- [ ] **Mandatory access control** (SELinux/AppArmor tipi, basitleştirilmiş)

## 13. Geliştirici araçları  (Faz 14+)

- [ ] **Terminal emulator** (native, GPU-accelerated, ligature destekli)
- [ ] **Text editor** — built-in, VS Code tarzı ama native
  (LSP, syntax highlight, debugger entegre)
- [ ] **Derleyici**: GCC veya Clang port (kendi system-local derleme)
- [ ] **Debugger**: gdb benzeri, entegre UI
- [ ] **Performance tracer** — system-wide profiler (perf + flamegraph)
- [ ] **API browser** — sistem API'lerini keşfedebilen dökümanlı UI

## 14. Varsayılan uygulamalar  (Faz 14+)

- [ ] **Dosya yöneticisi** (Finder/Files tarzı)
- [ ] **Web tarayıcı** (belki Ladybird portu — WebKit çok büyük)
- [ ] **Mail / takvim / kişiler**
- [ ] **Fotoğraf galerisi + basit editör**
- [ ] **Video oynatıcı** (donanım hızlandırmalı)
- [ ] **Müzik çalar**
- [ ] **PDF okuyucu**
- [ ] **Notlar / markdown editor**
- [ ] **Hesap makinesi, saat, hava durumu** (klasikler)

## 15. Güç yönetimi  (Faz 15+)

- [ ] **ACPI sleep states** (S0/S1/S3)
- [ ] **CPU frequency scaling** (P-states, C-states)
- [ ] **Display brightness adaptation**
- [ ] **Battery / charging UI**, kalan süre tahmini
- [ ] **Thermal throttling**
- [ ] **Wake reasons** — neden uyandı log'u

## 16. Erişilebilirlik  (Faz 13+)

- [ ] **Screen reader** — system-wide, ARIA-benzeri attribute'lardan okur
- [ ] **Zoom** — magnifier, per-app font scaling
- [ ] **High contrast tema**
- [ ] **Voice control**
- [ ] **Switch control** — tek butonla tüm OS
- [ ] **Subtitle/caption** sistem genelinde

## 17. Yerelleştirme (i18n/l10n)

- [ ] **Full Unicode** — UTF-8 her yerde, CJK + RTL (Arapça/İbranice)
- [ ] **Translation framework** — .po benzeri ya da JSON-based
- [ ] **Tarih/saat/sayı formatı** (CLDR benzeri)
- [ ] **Timezone database** — tzdata
- [ ] **Klavye düzeni** — Türkçe F/Q native

## 18. SimpleOS'e özgü fikirler (beyin fırtınası)

Buraya tamamen özgün fikirler yazıyoruz — "diğer OS'ler yapmıyor ama biz
yapabiliriz". Zamanla genişlesin.

- [ ] **Time-machine her dosya için** — COW FS + otomatik snapshot, "5 dk
  öncesine dön" butonu sistem genelinde
- [ ] **Action history** — her uygulama yaptıklarını kaydetsin, global
  "geri al / ileri al" bandı
- [ ] **Unified search** — dosya + ayar + uygulama + yardım + web aynı
  arama çubuğunda
- [ ] **Cross-app drag** — her şey sürüklenebilir (seçili metin,
  sekme, dosya parçası) ve diğer uygulama akıllı kabul etsin
- [ ] **Ephemeral apps** — kurulmadan tek seferlik çalışsın
- [ ] **System-wide AI assistant** (local inference, opsiyonel)
- [ ] **Programmable desktop** — kullanıcı shortcut/automation'u GUI ile
  yazabilsin (AppleScript + Shortcuts birleşimi)
- [ ] **Glass blur everywhere** — menu bar, dock, modal'lar arka planı
  bulanıklaştırsın, varsayılan açık
- [ ] **Zero-config multi-device** — aynı kullanıcı hesabı ile 2 cihaz
  açık → clipboard, dosya, browser tab otomatik senkron (local network)

## Milestones (hedefler)

- **SimpleOS 0.5 — "komut satırı"**: Faz 10 bitti, TTY'de shell çalışıyor,
  coreutils var.
- **SimpleOS 0.7 — "ekosistem temeli"**: disk FS, ağ, paket yöneticisi,
  kullanıcı hesapları.
- **SimpleOS 0.9 — "görsel"**: compositor, animasyon motoru, ilk GUI app.
- **SimpleOS 1.0 — "kullanılabilir"**: login → desktop → dosya yöneticisi +
  terminal + text editor + tarayıcı. Günlük iş akışı için yeterli.
- **SimpleOS 1.5 — "polish"**: multi-monitor, HDR, VRR, erişilebilirlik,
  dil desteği.
- **SimpleOS 2.0 — "özgün OS"**: 18. maddedeki fikirlerden en az 3'ü
  hayatta. Kendi kimliği olmuş bir masaüstü.

---

## Çalışma akışı (plan)

1. **Şimdi**: Faz 10 bitti (shell canlı), Faz 11 bitti (VirtIO-GPU +
   display abstraction). Sıradaki doğal kol: gerçek donanım GPU
   sürücüleri (Intel / AMD / NVIDIA) ve / veya compositor başlangıcı.
2. **Ardından**: kategoriler bağımsız ilerleyebilir (ağ ve grafik
   paralel olabilir); gerektiğinde yeni "Faz" numarası açılır,
   `todos.md`'ye yazılır, bu dosyadaki madde `[x]` yapılır.

`[~]` = "kısmen tamam" — bir alt-madde canlı, geri kalanı bekliyor.

Bu dosya her milestone'da genişler. Yeni fikirler **18. bölüme** gider,
sonradan uygun kategoriye dağıtılır.
