# imp005 EZ Eval Testing Factory Code

Factory Test Code for imp005 EZ Eval

## Setup

For all tests to pass the following hardware must be plugged into the Fieldbus gateway.  

| Port        | External Hardware            | Instructions         |
| ----------- | ---------------------------- | -------------------- |
| USB         | USB FTDI232 board            | Must be plugged in for the 2nd test | 


## Tests

The factory code runs through the following tests. 

After each test an LED blinks, green if test pass, red if test fails. 

When tests have all run, if all tests have passed the LED turns GREEN and 2 labels are printed. If any test failed the LED turns RED and no label is printed.  

### Test 1 LEDs

RGB LED is tested. LED will turn on one color at a time with the colors listed below.

1st: Red
2nd: Blue
3rd: Green 

*Note* The code always marks this test as passing.

### Test 2 USB FTDI

This test requires a USB FTDI device (FTDI232). The test works best if the USB device is plugged in before the test starts. The test: 

* Initializes USB host and FTDI driver
* If a device is plugged in the onConnected FTDI callback triggers a test pass

### Test 3 Temp/Humid Reading

The test uses the onboard Temperature/Humidity sensor to: 

* Take a reading
* Check that Temperature and Humidity values are returned and are in range

### Test 4 Accelerometer Reading

The test uses the onboard Accelerometer sensor to: 

* Take a reading
* Check that a x, y, and z values are returned and are in range

### Test 5 ADC Channel 6

This test reads Channel 6 on the ADC. The test:

* Reads channel 6 - the expected value is 0
* Checks that the reading is within a &plusmn;0.2 range

### Test 6 ADC Channel 7

This test reads Channel 7 on the ADC. The test:

* Reads channel 7 - the expected value is 2.5
* Checks that the reading is within a &plusmn;0.2 range
