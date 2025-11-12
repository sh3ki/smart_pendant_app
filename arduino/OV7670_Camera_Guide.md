# OV7670 Camera Integration Guide

## 📹 Camera Specifications

### Frame Rate Capabilities
- **QQVGA (160x120)**: Up to 120 FPS (ESP32 can handle 20-30 FPS)
- **QVGA (320x240)**: Up to 60 FPS (ESP32 can handle 10-15 FPS)  
- **VGA (640x480)**: Up to 30 FPS (ESP32 can handle 5-10 FPS)

### Recommended Settings for WiFi Streaming
- **Resolution**: QVGA (320x240) - Best balance
- **Frame Rate**: 2-5 FPS - Stable over WiFi
- **Format**: JPEG compression
- **Quality**: 50-70% - Reduces bandwidth

## 🔌 OV7670 Pin Connections to Arduino Nano ESP32

```
OV7670 Pin    →    Nano ESP32 Pin    →    Function
────────────────────────────────────────────────────
3.3V          →    3.3V               →    Power
GND           →    GND                →    Ground
SIOC (SCL)    →    A5 (GPIO19)        →    I2C Clock (shared with ADXL345)
SIOD (SDA)    →    A4 (GPIO18)        →    I2C Data (shared with ADXL345)
VSYNC         →    D2 (GPIO2)         →    Vertical Sync
HREF          →    D3 (GPIO3)         →    Horizontal Ref
PCLK          →    D8 (GPIO8)         →    Pixel Clock
XCLK          →    D10 (GPIO10)       →    Master Clock (PWM)
D0-D7         →    D11-D18            →    8-bit parallel data
RESET         →    D6 (GPIO6)         →    Reset pin
PWDN          →    GND                →    Power down (tie to GND = active)
```

## ⚠️ Important Notes

1. **Shared I2C Bus**: OV7670 shares I2C with ADXL345 (both on A4/A5)
2. **Power**: OV7670 requires clean 3.3V (add 100µF capacitor)
3. **Bandwidth**: Each QVGA JPEG frame ~5-15KB, 2 FPS = ~10-30 KB/s
4. **Memory**: ESP32 has ~300KB RAM, can buffer 10-20 frames
5. **Processing**: Capturing takes ~100-200ms per frame

## 📊 Streaming Options

### Option 1: HTTP POST (Current Implementation)
- Arduino captures frame → POST to `/api/image`
- Flutter polls `/api/camera/latest` every 500ms
- **Pros**: Simple, works with existing code
- **Cons**: Slight delay, not real-time

### Option 2: WebSocket Streaming (Recommended for Video)
- Arduino captures frame → Send via WebSocket
- Flutter receives frames in real-time
- **Pros**: True streaming, lower latency
- **Cons**: More complex code

### Option 3: MJPEG Stream
- Arduino creates MJPEG stream server
- Flutter displays stream URL
- **Pros**: Standard format, smooth video
- **Cons**: Requires separate HTTP server on Arduino

## 🚀 Recommended Approach

Start with **Option 1** (HTTP POST) at 2 FPS:
1. Simple to implement
2. Reliable over WiFi
3. Easy to debug
4. Can upgrade to WebSocket later

## 💾 Storage Strategy

### Backend Server
- Store last 10 frames in memory (~150KB)
- Save panic alert images to disk
- Auto-delete old images after 1 hour

### Flutter App
- Cache last 5 frames
- Display most recent frame
- Cycle through frames for "video-like" effect

## 📝 Implementation Steps

1. **Arduino**: Add OV7670 library and capture code
2. **Backend**: Add `/api/image` endpoint with storage
3. **Flutter**: Update camera screen to poll/cycle frames
4. **Testing**: Start with 1 FPS, increase gradually
