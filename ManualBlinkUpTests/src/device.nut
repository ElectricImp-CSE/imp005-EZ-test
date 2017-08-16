#require "promise.class.nut:3.0.0"
#require "HTS221.class.nut:1.0.0"
#require "LIS3DH.class.nut:1.3.0"

@include "ADCTest.nut"
@include "LEDTest.nut"
@include "HTS221Test.nut"
@include "LIS2DH12TRTest.nut"
@include "USBTest.nut"

const DEBUG = 1;

hardware.i2c0.configure(CLOCK_SPEED_400_KHZ);

local series = [
    Promise(@(resolve, reject) ADCTest(DEBUG).test(resolve, reject)),
    Promise(@(resolve, reject) LEDTest(DEBUG).test(resolve, reject)),
    Promise(@(resolve, reject) HTS221Test(DEBUG).test(resolve, reject)),
    Promise(@(resolve, reject) LIS2DH12TRTest(DEBUG).test(resolve, reject)),
    Promise(@(resolve, reject) USBTest(DEBUG).test(resolve, reject))
];

local p = Promise.all(series);
p.then(
    function(values) {
        server.log("All Tests Passed!")
        local led = LEDTest(DEBUG);
        // Check accel
        local c = hardware.i2c0.read(0x32, "\x00", 1);
        if (c != null) {
            // it's there
            server.log("found accel");
            led.setLED(0x10, 0x00,0x00,0x20);
        } else {
            server.log("no accel :(");
            led.setLED(0x10, 0x00,0x20,0x00);
        }
    },
    function(reason) {
        server.log("Failed: " + reason);
        local led = LEDTest(DEBUG);
        // Blink the red LED
        led.setLED(0x10, 0x20,0x00,0x00);
    }
);    
