const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const cors = require('cors');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));  // ✅ Increased from 100kb to 10mb for audio files

// Store latest device data
let deviceData = {
  id: 'pendant-1',
  name: "Liam's Pendant",
  online: false,
  lastSeen: new Date().toISOString(),
  battery: 75,
  location: {
    latitude: 14.5995,  // Manila coordinates (default for indoor testing)
    longitude: 120.9842,
    accuracy: 90.0,  // Default 90% accuracy (no GPS)
    speed: 0.0  // Default to 0 m/s (REST)
  },
  activity: {
    type: 'REST',  // Default to REST
    steps: 0,
    calories: 0
  },
  accelerometer: {
    x: 0.0,
    y: 0.0,
    z: 0.0
  },
  panicPressed: false
};

// WebSocket connections (Flutter app clients)
const clients = new Set();

wss.on('connection', (ws) => {
  console.log('📱 Flutter app connected');
  console.log(`👥 Total connected clients: ${clients.size + 1}`);
  clients.add(ws);
  
  // Send current device data immediately
  ws.send(JSON.stringify({
    topic: 'devices/pendant-1/telemetry',
    payload: deviceData
  }));

  ws.on('close', () => {
    console.log('📱 Flutter app disconnected');
    clients.delete(ws);
    console.log(`👥 Remaining clients: ${clients.size}`);
  });

  ws.on('message', (message) => {
    try {
      const command = JSON.parse(message);
      console.log('📱 Command from app:', command);
      // Handle commands from app (e.g., request snapshot, start audio)
    } catch (e) {
      console.error('Invalid message from app:', e);
    }
  });
});

// Broadcast to all Flutter app clients
function broadcastToClients(topic, payload) {
  const message = JSON.stringify({ topic, payload });
  clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(message);
    }
  });
}

// ========================================
// 🔵 ARDUINO ENDPOINTS
// ========================================

// Arduino sends telemetry data here
app.post('/api/telemetry', (req, res) => {
  const data = req.body;
  console.log('📡 Telemetry from Arduino:', data);
  
  // Update device data
  deviceData.online = true;
  deviceData.lastSeen = new Date().toISOString();
  
  if (data.location) {
    deviceData.location = {
      latitude: data.location.lat !== undefined ? data.location.lat : deviceData.location.latitude,
      longitude: data.location.lng !== undefined ? data.location.lng : deviceData.location.longitude,
      accuracy: data.location.accuracy !== undefined ? data.location.accuracy : deviceData.location.accuracy,
      speed: data.location.speed !== undefined ? data.location.speed : deviceData.location.speed  // ✅ Allows 0!
    };
  }
  
  if (data.activity) {
    deviceData.activity = {
      type: data.activity.type || deviceData.activity.type,
      steps: data.activity.steps !== undefined ? data.activity.steps : deviceData.activity.steps,
      calories: data.activity.calories !== undefined ? data.activity.calories : deviceData.activity.calories
    };
  }
  
  if (data.accelerometer) {
    deviceData.accelerometer = {
      x: data.accelerometer.x !== undefined ? data.accelerometer.x : 0,
      y: data.accelerometer.y !== undefined ? data.accelerometer.y : 0,
      z: data.accelerometer.z !== undefined ? data.accelerometer.z : 0
    };
  }
  
  if (data.battery !== undefined) {
    deviceData.battery = data.battery;
  }
  
  // Format telemetry for Flutter app (convert to app's expected format)
  const telemetryForApp = {
    deviceId: data.deviceId || 'pendant-1',
    timestamp: deviceData.lastSeen,
    lat: deviceData.location.latitude,
    lon: deviceData.location.longitude,
    accuracyMeters: deviceData.location.accuracy,
    speed: deviceData.location.speed,  // ✅ Now correctly sends 0.0 for REST
    alt: 10.0,  // Default altitude
    batteryPercent: deviceData.battery,
    signalDbm: -70,  // Default signal strength
    motionState: (data.activity?.type || 'REST').toLowerCase(),  // Convert "REST", "WALK", "RUN" to lowercase
    firmwareVersion: '1.0.0'
  };
  
  console.log('📤 Sending to Flutter app:', telemetryForApp);
  
  // Broadcast to Flutter app
  broadcastToClients('devices/pendant-1/telemetry', telemetryForApp);
  
  res.json({ success: true, message: 'Telemetry received' });
});

// Arduino sends panic alert
app.post('/api/panic', (req, res) => {
  const startTime = Date.now(); // Track processing time
  
  console.log('🚨 PANIC BUTTON PRESSED!');
  console.log('📦 Request body:', req.body);
  
  deviceData.panicPressed = true;
  
  // Use ISO 8601 timestamp for consistency
  const timestamp = req.body.timestamp || new Date().toISOString();
  
  const alertData = {
    id: `alert-${Date.now()}`,
    deviceId: 'pendant-1',
    type: 'panic',
    timestamp: timestamp,
    location: deviceData.location,
    handled: false
  };
  
  console.log('📢 Broadcasting panic alert to Flutter clients:', alertData);
  console.log(`👥 Connected clients: ${clients.size}`);
  
  // Broadcast alert to Flutter app IMMEDIATELY
  broadcastToClients('devices/pendant-1/alert', alertData);
  
  const processingTime = Date.now() - startTime;
  console.log(`⚡ Alert processed in ${processingTime}ms`);
  
  // Send response immediately (don't wait for anything)
  res.json({ success: true, message: 'Panic alert sent', processingTime });
});

// Store camera frames (keep last 10 frames for "video-like" playback)
const cameraFrames = [];
const MAX_FRAMES = 10;

// Arduino sends image data (OV7670 camera @ 5 FPS)
app.post('/api/image', (req, res) => {
  const data = req.body;
  console.log(`📷 Frame ${data.frameNumber} received from Arduino (${data.format})`);
  
  // Store frame with metadata
  const frame = {
    deviceId: data.deviceId || 'pendant-1',
    frameNumber: data.frameNumber || cameraFrames.length,
    timestamp: new Date().toISOString(),
    width: data.width || 160,
    height: data.height || 120,
    format: data.format || 'grayscale-1bit',
    imageData: data.imageData, // Base64 encoded image data
    imageUrl: `data:image/jpeg;base64,${data.imageData}` // For browser display
  };
  
  // Add to frame buffer
  cameraFrames.push(frame);
  
  // Keep only last MAX_FRAMES (for memory efficiency)
  if (cameraFrames.length > MAX_FRAMES) {
    cameraFrames.shift();
  }
  
  // Update device camera state
  deviceData.camera = {
    latestFrame: frame.imageData,
    frameNumber: frame.frameNumber,
    width: frame.width,
    height: frame.height,
    format: frame.format,
    lastUpdate: frame.timestamp
  };
  
  // Broadcast new frame to connected Flutter apps
  broadcastToClients('devices/pendant-1/camera', frame);
  
  res.json({ 
    success: true, 
    message: 'Frame received',
    frameNumber: frame.frameNumber,
    bufferedFrames: cameraFrames.length
  });
});

// Get latest camera frame
app.get('/api/camera/latest', (req, res) => {
  if (cameraFrames.length === 0) {
    return res.status(404).json({ error: 'No frames available' });
  }
  res.json(cameraFrames[cameraFrames.length - 1]);
});

// Get all camera frames (for cycling through)
app.get('/api/camera/frames', (req, res) => {
  res.json({
    frames: cameraFrames,
    totalFrames: cameraFrames.length,
    fps: cameraFrames.length > 1 ? 2 : 0 // Approximate FPS
  });
});

// ========================================
// 🎵 AUDIO RECORDING ENDPOINT
// ========================================

// Flutter app sends audio recording to be forwarded to Arduino
app.post('/api/audio/send', async (req, res) => {
  const { audio, deviceId, timestamp } = req.body;
  
  if (!audio) {
    return res.status(400).json({ error: 'No audio data provided' });
  }
  
  console.log(`🎵 Audio recording received (${audio.length} bytes base64)`);
  console.log(`📅 Timestamp: ${timestamp}`);
  
  try {
    // Forward audio to Arduino
    // ⚠️ IMPORTANT: Set ARDUINO_IP environment variable or update default IP below
    // Find Arduino IP by uploading code and checking Serial Monitor for "IP Address: x.x.x.x"
    const arduinoIp = process.env.ARDUINO_IP || '192.168.1.67'; // ⚠️ UPDATE THIS WITH YOUR ARDUINO'S IP!
    const arduinoUrl = `http://${arduinoIp}/audio`;
    
    console.log(`📤 Forwarding audio to Arduino at ${arduinoUrl}`);
    
    // Use node's http module to send to Arduino
    const axios = require('axios');
    const arduinoResponse = await axios.post(arduinoUrl, {
      audio: audio,
      timestamp: timestamp
    }, {
      timeout: 10000, // 10 second timeout
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`✅ Audio successfully sent to Arduino`);
    console.log(`   Arduino response:`, arduinoResponse.data);
    
    res.json({ 
      success: true, 
      message: 'Audio sent to Arduino',
      arduinoResponse: arduinoResponse.data
    });
    
  } catch (error) {
    console.error(`❌ Failed to send audio to Arduino:`, error.message);
    
    // Still return success to Flutter app even if Arduino is offline
    res.json({ 
      success: true, 
      message: 'Audio received but Arduino is offline',
      error: error.message,
      note: 'Audio will be cached for later delivery (TODO: implement caching)'
    });
  }
});

// ========================================
// 🔵 FLUTTER APP ENDPOINTS
// ========================================

// Get device list
app.get('/api/devices', (req, res) => {
  res.json([deviceData]);
});

// Get specific device
app.get('/api/devices/:deviceId', (req, res) => {
  res.json(deviceData);
});

// Get device telemetry
app.get('/api/devices/:deviceId/telemetry', (req, res) => {
  res.json(deviceData);
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Get local IP address automatically
function getLocalIPAddress() {
  const { networkInterfaces } = require('os');
  const nets = networkInterfaces();
  
  for (const name of Object.keys(nets)) {
    for (const net of nets[name]) {
      // Skip internal (loopback) and non-IPv4 addresses
      const familyV4Value = typeof net.family === 'string' ? 'IPv4' : 4;
      if (net.family === familyV4Value && !net.internal) {
        return net.address;
      }
    }
  }
  return 'localhost';
}

// Start server - Listen on all network interfaces (0.0.0.0)
const PORT = process.env.PORT || 3000;
const localIP = getLocalIPAddress();

server.listen(PORT, '0.0.0.0', () => {
  console.log(`
╔════════════════════════════════════════════════════════╗
║  🚀 Smart Pendant Backend Server Running              ║
║  📡 HTTP API:      http://${localIP}:${PORT}${' '.repeat(Math.max(0, 15 - localIP.length))}║
║  🔌 WebSocket:     ws://${localIP}:${PORT}${' '.repeat(Math.max(0, 17 - localIP.length))}║
║  📱 Flutter app can connect now                       ║
║  🤖 Arduino should POST to /api/telemetry             ║
║  ⚠️  Listening on ALL network interfaces (0.0.0.0)   ║
║      Make sure Arduino uses the correct IP above      ║
╚════════════════════════════════════════════════════════╝
  `);
  console.log(`\n💡 Server accessible at:`);
  console.log(`   - http://localhost:${PORT}`);
  console.log(`   - http://${localIP}:${PORT}`);
  console.log(`   - http://0.0.0.0:${PORT}\n`);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('Shutting down gracefully...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});
