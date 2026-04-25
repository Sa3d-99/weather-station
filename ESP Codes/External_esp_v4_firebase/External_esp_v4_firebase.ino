/*
  ════════════════════════════════════════════════════════════════
  External Sensor ESP32 — v4 (Firebase Direct + ESP-NOW)
  تم تحديث دالة OnDataSent لتتوافق مع مكتبات ESP32 3.x.x
  ════════════════════════════════════════════════════════════════
*/

#include <esp_now.h>
#include <WiFi.h>
#include <time.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BMP280.h>
#include "DHT.h"
#include <FirebaseESP32.h>

// ─── Pin Definitions ──────────────────────────────────────────
#define DHTPIN     4
#define DHTTYPE    DHT11
#define WIND_PIN   13 

// ─── WiFi Credentials ─────────────────────────────────────────
const char* ssid     = "enter your wifi name here";      // ← FILL IN
const char* password = "enter your wifi password here";  // ← FILL IN

// ─── Firebase Credentials ─────────────────────────────────────
#define FIREBASE_HOST  "YOUR_PROJECT_ID-default-rtdb.firebaseio.com"  // ← FILL IN
#define FIREBASE_AUTH  "YOUR_DATABASE_SECRET_TOKEN"                   // ← FILL IN

// ─── NTP ──────────────────────────────────────────────────────
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 2 * 3600;
const int   daylightOffset_sec = 3600;

// ─── CYD Screen MAC Address ───────────────────────────────────
uint8_t broadcastAddress[] = {0x"nn", 0x"nn", 0x"nn", 0x"nn", 0x"nn", 0x"nn"};  // put your MAC address here change nn and put your address number in order

// ─── Objects ──────────────────────────────────────────────────
DHT dht(DHTPIN, DHTTYPE);
Adafruit_BMP280 bmp;
FirebaseData fbdo;
FirebaseAuth fbAuth;
FirebaseConfig fbConfig;
bool firebaseReady = false;

struct DataPacket {
  float temp;
  float hum;
  float pres;
  float wind;
};
DataPacket myData;

const float RADIUS_M = 0.09;
volatile uint32_t pulseCount = 0;

void IRAM_ATTR countPulse() {
  pulseCount++;
}

unsigned long lastSensorRead = 0;
unsigned long lastFirebasePush = 0;
unsigned long lastEspNowSend = 0;

const unsigned long SENSOR_INTERVAL_MS   = 1000;
const unsigned long FIREBASE_INTERVAL_MS = 1000;
const unsigned long ESPNOW_INTERVAL_MS   = 1000;

float lastValidTemp = 25.0;
float lastValidHum  = 50.0;

// ─── التعديل هنا ليتوافق مع الإصدار الحديث 3.x.x ───────────────
void OnDataSent(const esp_now_send_info_t *info, esp_now_send_status_t status) {
  // هذه الدالة تعمل الآن كـ Callback متوافق مع المكتبة الجديدة
}

void setup() {
  Serial.begin(115200);
  
  dht.begin();
  if (!bmp.begin(0x76)) bmp.begin(0x77);

  pinMode(WIND_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(WIND_PIN), countPulse, RISING);

  WiFi.mode(WIFI_AP_STA);
  WiFi.begin(ssid, password);
  
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(300);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
    fbConfig.host = FIREBASE_HOST;
    fbConfig.signer.tokens.legacy_token = FIREBASE_AUTH;
    Firebase.begin(&fbConfig, &fbAuth);
    Firebase.reconnectWiFi(true);
    firebaseReady = true;
  }

  // 6. ESP-NOW init
  if (esp_now_init() == ESP_OK) {
    // تم ربط الدالة هنا
    esp_now_register_send_cb(OnDataSent);
    
    esp_now_peer_info_t peerInfo = {};
    memcpy(peerInfo.peer_addr, broadcastAddress, 6);
    peerInfo.channel = 0;
    peerInfo.encrypt = false;
    esp_now_add_peer(&peerInfo);
  }
}

void loop() {
  unsigned long now = millis();

  if (now - lastSensorRead >= SENSOR_INTERVAL_MS) {
    lastSensorRead = now;
    noInterrupts();
    uint32_t count = pulseCount;
    pulseCount = 0;
    interrupts();
    myData.wind = (2.0f * 3.14159265f * RADIUS_M) * (float)count;

    float t = dht.readTemperature();
    float h = dht.readHumidity();
    if (!isnan(t)) { myData.temp = t; lastValidTemp = t; } else { myData.temp = lastValidTemp; }
    if (!isnan(h)) { myData.hum = h; lastValidHum = h; } else { myData.hum = lastValidHum; }
    
    float p = bmp.readPressure() / 100.0F;
    myData.pres = (p > 800 && p < 1200) ? p : 1013.25;
  }

  if (now - lastEspNowSend >= ESPNOW_INTERVAL_MS) {
    lastEspNowSend = now;
    esp_now_send(broadcastAddress, (uint8_t*)&myData, sizeof(myData));
  }

  if (firebaseReady && now - lastFirebasePush >= FIREBASE_INTERVAL_MS) {
    lastFirebasePush = now;
    time_t ts_sec; time(&ts_sec);
    long ts = (long)ts_sec * 1000L;

    FirebaseJson liveJson;
    liveJson.set("temp", myData.temp);
    liveJson.set("hum", myData.hum);
    liveJson.set("pres", myData.pres);
    liveJson.set("wind", myData.wind);
    liveJson.set("timestamp", ts);

    Firebase.setJSON(fbdo, "/weather_station", liveJson);
  }
}