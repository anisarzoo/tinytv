# TinyTV - Cross-Platform IPTV App (Flutter)

A high-performance, native IPTV streaming app built with **Flutter** and **MediaKit (libmpv)** for Windows, Android, Android TV, and iOS.

---

## 🚀 Key Advantages Over Web Players

1. **Zero Browser CORS Restrictions:** Bypasses web browser same-origin policies; stream connections are made directly at the OS networking layer.
2. **Full Broadcast Codec Support:** Powered by `libmpv` through `media_kit`, decoding AC3 / EAC3 Dolby Digital audio, MPEG-2 video, HEVC/H.265, and raw MPEG-TS (.ts) streams.
3. **Custom Headers & Anti-Bot Spoofing:** Sends custom User-Agent and Referer headers with every stream request to prevent broadcaster rate-limiting or blocks.
4. **Curated High-Uptime FAST Providers:** Built-in support for **Samsung TV Plus (Global)**, **Pluto TV (300+ channels)**, **Plex Live TV**, **Free-TV Worldwide**, and **IPTV-Org** (India, USA, UK, Pakistan, UAE), plus custom M3U playlist loading.
5. **Adaptive UI:** Seamlessly scales from desktop split-screen to mobile portrait and large-screen TV remote navigation.

---

## 🎮 Keyboard & Remote Shortcuts

| Key | Action |
| :--- | :--- |
| **Space** | Play / Pause toggle |
| **Arrow Right (→)** | Next channel |
| **Arrow Left (←)** | Previous channel |
| **Arrow Up (↑)** | Volume up (+5%) |
| **Arrow Down (↓)** | Volume down (-5%) |
| **M** | Mute / Unmute |
| **F** / **Double-Click** | Fullscreen mode |

---

## 💻 How to Run

### Windows Desktop:
```bash
cd tinytv_app
flutter run -d windows
```
Executable binary location:
`tinytv_app/build/windows/x64/runner/Debug/tinytv_app.exe`

### Android (Phone, Tablet, Android TV, Fire TV):
```bash
cd tinytv_app
flutter run -d android
```
Build standalone release APK:
```bash
flutter build apk --release
```
