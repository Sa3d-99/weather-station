#include <WiFi.h>

void setup() {
  Serial.begin(115200);
  delay(2000); 
  
  // تشغيل الواي فاي ضروري قبل قراءة الماك
  WiFi.mode(WIFI_STA);
  delay(100);
  
  Serial.println("\n--- REFRESHING MAC ADDRESS ---");
  
  // قراءة الماك بأكتر من طريقة للتأكد
  String mac = WiFi.macAddress();
  
  if (mac == "00:00:00:00:00:00") {
    Serial.println("Warning: Still getting zeros, restarting WiFi...");
    WiFi.disconnect();
    delay(500);
    WiFi.mode(WIFI_STA);
    mac = WiFi.macAddress();
  }

  Serial.print("SUCCESS! MAC Address is: ");
  Serial.println(mac);
  Serial.println("------------------------------");
}

void loop() {}