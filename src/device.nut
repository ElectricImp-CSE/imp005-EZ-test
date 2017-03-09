#require "promise.class.nut:3.0.0"
#require "HTS221.class.nut:1.0.0"
#require "LIS3DH.class.nut:1.3.0"

@include "ADCTest.nut"
@include "LEDTest.nut"
@include "HTS221Test.nut"
@include "LIS2DH12TRTest.nut"

const DEBUG = 1;

local series = [
    Promise(@(resolve, reject) ADCTest(DEBUG).test(resolve, reject)),
    Promise(@(resolve, reject) LEDTest(DEBUG).test(resolve, reject)),
    Promise(@(resolve, reject) HTS221Test(DEBUG).test(resolve, reject)),
    Promise(@(resolve, reject) LIS2DH12TRTest(DEBUG).test(resolve, reject))
];

local p = Promise.all(series);
p.then(
    function(values) {
        server.log("All Tests Passed!")
        // Blink the green LED
    },
    function(reason) {
        server.log("Failed: " + reason);
        // Blink the red LED
    }
);