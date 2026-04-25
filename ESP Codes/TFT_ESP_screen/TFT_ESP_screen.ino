#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <esp_now.h>
#include <WiFi.h>
#include <time.h>

// ─── CYD / ESP32 Pins ─────────────────────────────────────────
#define TFT_BL   21
#define TFT_MISO 12
#define TFT_MOSI 13
#define TFT_SCLK 14
#define TFT_CS   15
#define TFT_DC    2
#define TFT_RST  -1

Adafruit_ILI9341 tft = Adafruit_ILI9341(TFT_CS, TFT_DC, TFT_MOSI, TFT_SCLK, TFT_RST, TFT_MISO);

// ─── WiFi & Time Settings ─────────────────────────────────────
const char* ssid       = " ";      // <-- Put your WiFi Name here 
const char* password   = " ";  // <-- Put your WiFi Password here

const char* ntpServer  = "pool.ntp.org";
const long  gmtOffset_sec = 2 * 3600;           // Egypt Standard Time (UTC+2)
const int   daylightOffset_sec = 3600;          // Egypt Daylight Saving (1 hour)
int lastMinute = -1;                            // Track minute changes to prevent flickering

// ─── App Style Color Palette (RGB565) ───────────────────────
#define COL_BG        0x0821  
#define COL_CARD      0x10A3  
#define COL_TEXT      0xFFFF  
#define COL_SUBTEXT   0x7BEF  
#define COL_HUM       0x1DBF  
#define COL_WIND      0xFC1F  
#define COL_PRES      0x47F1  
#define COL_HERO_ACC  0xFD20  

// ─── Data Structures ────────────────────────────────────────
// Must match the Sender exactly
typedef struct DataPacket {
    float temp; 
    float hum; 
    float pres; 
    float wind;
} DataPacket;

DataPacket incomingData;

struct SensorState {
  float temp = 0.0;
  float hum  = 0.0;
  float pres = 0.0; 
  float wind = 0.0;
};

SensorState current; 
SensorState previous; 
bool firstDraw = true;

// ─── Prototypes ─────────────────────────────────────────────
void drawStaticUI();
void drawStaticCard(int x, int y, int w, int h, String title, String unit, uint16_t color);
void updateDynamicUI();
void updateCardValue(int x, int y, int w, int h, String val, uint16_t color, float currentVal, float &prevVal);
void updateTimeDateUI();

// ═══════════════════════════════════════════════════════════
//  ESP-NOW CALLBACK
// ═══════════════════════════════════════════════════════════
void OnDataRecv(const esp_now_recv_info *info, const uint8_t *incoming, int len) {
  if (len == sizeof(DataPacket)) {
    memcpy(&incomingData, incoming, sizeof(DataPacket));
    current.temp = incomingData.temp;
    current.hum  = incomingData.hum;
    current.pres = incomingData.pres;
    current.wind = incomingData.wind;
  }
}

// ═══════════════════════════════════════════════════════════
//  SETUP
// ═══════════════════════════════════════════════════════════
void setup() {
  Serial.begin(115200);

  // 1. Initialize Screen & Backlight
  pinMode(TFT_BL, OUTPUT);
  digitalWrite(TFT_BL, HIGH); 
  tft.begin();
  tft.setRotation(1); 
  tft.fillScreen(COL_BG);

  // Draw a temporary loading message
  tft.setTextColor(COL_TEXT);
  tft.setTextSize(2);
  tft.setCursor(50, 110);
  tft.print("Connecting to WiFi...");

  // 2. Connect to WiFi & Sync Time
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }
  
  if(WiFi.status() == WL_CONNECTED) {
    configTime(gmtOffset_sec, 0, ntpServer);
    Serial.println("\nTime Synced via NTP");
  } else {
    Serial.println("\nWiFi Failed. Running without live time.");
  }

  // 3. Initialize ESP-NOW
  if (esp_now_init() != ESP_OK) {
    Serial.println("Error initializing ESP-NOW");
    return;
  }
  esp_now_register_recv_cb(OnDataRecv);

  // 4. Draw Initial UI
  drawStaticUI();
  updateDynamicUI();
}

// ═══════════════════════════════════════════════════════════
//  LOOP
// ═══════════════════════════════════════════════════════════
void loop() {
  updateTimeDateUI(); // Checks time and updates if the minute changed
  updateDynamicUI();  // Checks sensors and updates if values changed
  //delay(30); 
}

// ═══════════════════════════════════════════════════════════
//  UI DRAWING FUNCTIONS
// ═══════════════════════════════════════════════════════════

void drawStaticUI() {
  tft.fillScreen(COL_BG);
  
  // Static Location Text
  tft.setTextColor(COL_TEXT);
  tft.setTextSize(2);
  tft.setCursor(15, 20); 
  tft.print("Badr City"); 

  // Sun Graphic
  //tft.fillCircle(250, 75, 20, COL_HERO_ACC); 
  //tft.drawCircle(250, 75, 25, COL_HERO_ACC); 

  // Bottom Cards
  drawStaticCard(5, 120, 100, 110, "HUMIDITY", "%", COL_HUM);
  drawStaticCard(110, 120, 100, 110, "WIND", "m/s", COL_WIND);
  drawStaticCard(215, 120, 100, 110, "PRESSURE", "hPa", COL_PRES);
}

void drawStaticCard(int x, int y, int w, int h, String title, String unit, uint16_t color) {
  tft.fillRoundRect(x, y, w, h, 8, COL_CARD); 
  tft.drawFastHLine(x + 10, y + 10, w - 20, color);
  tft.drawFastHLine(x + 10, y + 11, w - 20, color);

  int16_t tx, ty; uint16_t tw, th;
  tft.setTextColor(COL_SUBTEXT);
  tft.setTextSize(1);
  tft.getTextBounds(title, 0, 0, &tx, &ty, &tw, &th);
  tft.setCursor(x + (w / 2) - (tw / 2), y + 20);
  tft.print(title);

  tft.getTextBounds(unit, 0, 0, &tx, &ty, &tw, &th);
  tft.setCursor(x + (w / 2) - (tw / 2), y + h - 15);
  tft.print(unit);
}

void updateTimeDateUI() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) return;

  // Only redraw if the minute has changed to prevent screen flicker
  if (timeinfo.tm_min != lastMinute) {
    lastMinute = timeinfo.tm_min;

    // Erase old time/date area
    tft.fillRect(15, 45, 180, 40, COL_BG);

    // Format Time (e.g., 10:30 AM)
    char timeStr[10];
    strftime(timeStr, sizeof(timeStr), "%I:%M %p", &timeinfo);
    
    // Format Date (e.g., Friday, Oct 24)
    char dateStr[30];
    strftime(dateStr, sizeof(dateStr), "%A, %b %d", &timeinfo);

    tft.setTextColor(COL_SUBTEXT);
    tft.setTextSize(1);
    tft.setCursor(15, 45); 
    tft.print(timeStr); 
    tft.setCursor(15, 60); 
    tft.print(dateStr); 
  }
}

void updateDynamicUI() {
  int16_t tx, ty; uint16_t tw, th;
  
  // ─── Update Temperature ───
  if (firstDraw || abs(current.temp - previous.temp) > 0.1) {
    tft.fillRect(175, 20, 135, 45, COL_BG); 
    tft.setTextColor(COL_TEXT);
    tft.setTextSize(4); 
    String tempStr = String(current.temp, 1) + "\xF7";
    tft.getTextBounds(tempStr, 0, 0, &tx, &ty, &tw, &th);
    tft.setCursor(300 - tw, 26); 
    tft.print(tempStr);
    previous.temp = current.temp;
  }

  // ─── Update Bottom Cards ───
  updateCardValue(5, 120, 100, 110, String(current.hum, 1), COL_HUM, current.hum, previous.hum);
  updateCardValue(110, 120, 100, 110, String(current.wind, 1), COL_WIND, current.wind, previous.wind);
  updateCardValue(215, 120, 100, 110, String(current.pres, 1), COL_PRES, current.pres, previous.pres);

  firstDraw = false;
}

void updateCardValue(int x, int y, int w, int h, String val, uint16_t color, float currentVal, float &prevVal) {
  if (firstDraw || abs(currentVal - prevVal) > 0.05) {
    tft.fillRect(x + 10, y + 40, w - 20, 40, COL_CARD); 
    tft.setTextColor(color);
    tft.setTextSize(2);
    int16_t tx, ty; uint16_t tw, th;
    tft.getTextBounds(val, 0, 0, &tx, &ty, &tw, &th);
    tft.setCursor(x + (w / 2) - (tw / 2), y + (h / 2) - 5); 
    tft.print(val);
    prevVal = currentVal; 
  }
}