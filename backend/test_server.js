// Test script to verify backend is working
// Run this after starting the server with: node test_server.js

const http = require('http');

const SERVER_URL = 'http://localhost:3000';

console.log('\n╔════════════════════════════════════════╗');
console.log('║  Testing Smart Pendant Backend       ║');
console.log('╚════════════════════════════════════════╝\n');

// Test 1: Health check
console.log('Test 1: Health Check...');
http.get(`${SERVER_URL}/health`, (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    if (res.statusCode === 200) {
      console.log('✅ Health check passed');
      console.log('   Response:', data);
      testTelemetry();
    } else {
      console.log('❌ Health check failed:', res.statusCode);
    }
  });
}).on('error', (err) => {
  console.log('❌ Server not running!');
  console.log('   Please start the server first with: npm start');
  process.exit(1);
});

// Test 2: Send mock telemetry
function testTelemetry() {
  console.log('\nTest 2: Sending mock telemetry...');
  
  const mockData = JSON.stringify({
    deviceId: 'pendant-1',
    battery: 85,
    location: {
      lat: 37.774851,
      lng: -122.419388,
      accuracy: 10.5,
      speed: 2.3
    },
    activity: {
      type: 'WALK',
      steps: 1500,
      calories: 75
    },
    accelerometer: {
      x: 0.12,
      y: -0.05,
      z: 0.98
    }
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/telemetry',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(mockData)
    }
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      if (res.statusCode === 200) {
        console.log('✅ Telemetry test passed');
        console.log('   Response:', data);
        testPanic();
      } else {
        console.log('❌ Telemetry test failed:', res.statusCode);
      }
    });
  });

  req.on('error', (err) => {
    console.log('❌ Request error:', err.message);
  });

  req.write(mockData);
  req.end();
}

// Test 3: Send panic alert
function testPanic() {
  console.log('\nTest 3: Sending panic alert...');
  
  const panicData = JSON.stringify({
    deviceId: 'pendant-1',
    location: {
      lat: 37.774851,
      lng: -122.419388
    }
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/panic',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(panicData)
    }
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', chunk => data += chunk);
    res.on('end', () => {
      if (res.statusCode === 200) {
        console.log('✅ Panic alert test passed');
        console.log('   Response:', data);
        console.log('\n╔════════════════════════════════════════╗');
        console.log('║  ✅ All tests passed!                 ║');
        console.log('║  Backend is ready for Arduino        ║');
        console.log('╚════════════════════════════════════════╝\n');
      } else {
        console.log('❌ Panic test failed:', res.statusCode);
      }
    });
  });

  req.on('error', (err) => {
    console.log('❌ Request error:', err.message);
  });

  req.write(panicData);
  req.end();
}
