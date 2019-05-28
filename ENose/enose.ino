#include <Arduino.h>
#include <SPI.h>
#include <stdlib.h>

// configuration variables
static unsigned long Ts = 4000; // micros = 250 Hz sampling rate
static const int nAverage = 2; // sample averaging to avoid malicious spikes
static const int mcpCS[4] = {2, 3, 4, 5};
static const int flowControlPin = 0;

// globals
static int16_t measurements[8] = {0};
static float t; // seconds
static bool measuring = false;
static unsigned long lastMeasurement = 0;

// notifyOK sends ok -- lets the client know that the command was successful
void notifyOK(){
    Serial.println("ok");
    Serial.flush();
}

// notifyError sends error messages
void notifyError(const char* msg){
    Serial.print("error: ");
    Serial.println(msg);
    Serial.flush();
}

// shouldMeasure returns true if a certain amount of ms has passed (sampling frequency)
bool shouldMeasure() {
    if (!measuring) return false;

    unsigned long tMicro = micros();
    unsigned long delta = tMicro - lastMeasurement;

    if (delta > Ts) {
        t += static_cast<float>(delta) / 1000000;

        return true;
    }

    return false;
}

// setSensitivity controls the digital potentiometers on the controller
void setSensitivity(short nSensor, byte scale) {
    byte channel = nSensor % 2 + 1; // Select the proper channe
    short chip = nSensor / 2;          // Select the proper chip

    digitalWrite(mcpCS[chip], LOW);     // Set CS pin to LOW
    SPI.transfer(B00010000 | channel);           // Write bit that selects channel and mode
    SPI.transfer(scale);               // Write byte that selects potmeter value
    digitalWrite(mcpCS[chip], HIGH);     // Set CS pin to HIGH
}

void readSamplingRate(){
    if (measuring) return;

    // begin setting of sampling rate
    float fsNew = Serial.parseFloat();
    if (fsNew <= 0) {
        Serial.println("error: invalid frequency in Hz given");
        Serial.flush();
        return;
    } else if (fsNew > 10000) {
        Serial.println("error: frequency exceeds limit (10kHz)");
        Serial.flush();
        return;
    }

    Ts = static_cast<unsigned long>(1000000 / fsNew);

    notifyOK();
}

void readCalibration() {
    short sensor = Serial.parseInt();
    short value = Serial.parseInt();

    if (sensor < 1 || sensor > 8){
        notifyError("invalid sensor")
        measuring = false;
    } else if (value < 0 || value > 255){
        notifyError("invalid value")
        measuring = false;
    }

    setSensitivity(sensor,value);

    if (measuring) return;

    notifyOK();
}

void readFlow(){
    // read through which chamber the flow should go
    short chamber = Serial.parseInt();

    // validate the input
    if (sensor != 0 && sensor != 1){
        notifyError("invalid flow direction")
    }

    // since we have only two directions, simply write the binary value
    digitalWrite(flowControlPin, (sensor==0) ? LOW : HIGH);

    notifyOK();
}

// executeCommand reads the command currently in Serial input and acts accordingly
void executeCommand() {
    // read value on Serial and cast to char
    auto cmd = Serial.read();
    switch (cmd) {
        case 'm': // Measure
            if (measuring) break;

            notifyOK();

            // Set starting environment
            measuring=true;
            lastMeasurement = micros() - Ts * 2;
            t = 0.0f;

            break;
        case 'i': // Info
            if (measuring) break;

            notifyOK();
            Serial.println(static_cast<int>(1 / (static_cast<double>(Ts)) * 1000000));

            break;
        case 'r': // Reset
            measuring=false;

            notifyOK();

            break;
        case 's': // Samping rate
            readSamplingRate();
            break;
        case 'f': // Select flow
            readFlow();
            break;
        case 'c': // Calibrate
            readCalibration();
            break;
    }
}

// write a measurement in MATLAB vector format
void writeMeasurement() {
    // Last measurement is taken now
    lastMeasurement = micros();

    // Reset measurements array and notify lastMeasurement time in order to reset
    memset(measurements, 0, 16);

    // Read measurements
    for (int i = 0; i < nAverage; i++) {
        measurements[0] += analogRead(A0);
        measurements[1] += analogRead(A1);
        measurements[2] += analogRead(A2);
        measurements[3] += analogRead(A3);
        measurements[4] += analogRead(A4);
        measurements[5] += analogRead(A5);
        measurements[6] += analogRead(A6);
        measurements[7] += analogRead(A7);
    }
    for (int i = 0; i < 8; i++) {
        measurements[i] /= nAverage;
    }

    // Check if we're not too quick
    if (Serial.availableForWrite() < 20) {
        Serial.println("error: serial buffer overfow");
        measuring=false;
        return;
    }

    // Output to Serial
    Serial.write(reinterpret_cast<byte *>(&t), 4); // type of t is float => 4 bytes
    Serial.write(reinterpret_cast<byte *>(measurements),
                 16); // type of measurement is int => 2 bytes => 8 measurements = 16 bytes
}


// setup function
void setup() {
    // setup pins
    for (int i = 0; i < 4; i++) {
        pinMode(mcpCS[i], OUTPUT);
        pinMode(mcpCS[i], HIGH);
    }
    SPI.begin();
    for (int i = 1; i <= 8; i++) {
        setSensitivity(i, 128); // initialize with 50% sensitivity
    }

    pinMode(A0, INPUT);
    pinMode(A1, INPUT);
    pinMode(A2, INPUT);
    pinMode(A3, INPUT);
    pinMode(A4, INPUT);
    pinMode(A5, INPUT);
    pinMode(A6, INPUT);
    pinMode(A7, INPUT);

    // initialize serial communication @ 115200 Baud
    Serial.begin(115200);

    // announce that we're ready for commands
    Serial.println("ready");
    Serial.flush();
}

// main loop
void loop() {
    // if there is a command available, read it and set the status accordingly
    while (Serial.available()) {
        executeCommand();
    }
    if (shouldMeasure()) {
        writeMeasurement();
    }
}
