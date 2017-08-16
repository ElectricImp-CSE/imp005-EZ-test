// USB Library
#require "USB.device.lib.nut:0.1.0"
// ADC Library
#require "MCP3208.device.lib.nut:1.0.0"
// Temp/Humid Sensor Library
#require "HTS221.class.nut:1.0.0"
// Accelerometer Library
#require "LIS3DH.device.lib.nut:2.0.0"
// LED Library
#require "APA102.device.lib.nut:2.0.0"

// Promise Library for Async Testing 
#require "promise.class.nut:3.0.1"
// Factory Tools Lib
#require "FactoryTools.class.nut:2.1.0"
// Factory Fixture Keyboard/Display Lib
#require "CFAx33KL.class.nut:1.1.0"
// Printer Driver
#require "QL720NW.device.lib.nut:1.0.0"

// USB Driver for FTDI board
class FtdiUsbDriver extends USB.DriverBase {

    static VERSION = "1.0.0";

    // FTDI vid and pid
    static VID = 0x0403;
    static PID = 0x6001;

    // FTDI driver
    static FTDI_REQUEST_FTDI_OUT = 0x40;
    static FTDI_SIO_SET_BAUD_RATE = 3;
    static FTDI_SIO_SET_FLOW_CTRL = 2;
    static FTDI_SIO_DISABLE_FLOW_CTRL = 0;

    _deviceAddress = null;
    _bulkIn = null;
    _bulkOut = null;


    // 
    // Metafunction to return class name when typeof <instance> is run
    // 
    function _typeof() {
        return "FtdiUsbDriver";
    }


    // 
    // Returns an array of VID PID combination tables.
    // 
    // @return {Array of Tables} Array of VID PID Tables
    // 
    function getIdentifiers() {
        local identifiers = {};
        identifiers[VID] <-[PID];
        return [identifiers];
    }


    // 
    // Write string or blob to usb
    // 
    // @param  {String/Blob} data data to be sent via usb
    // 
    function write(data) {
        local _data = null;

        // Convert strings to blobs
        if (typeof data == "string") {
            _data = blob();
            _data.writestring(data);
        } else if (typeof data == "blob") {
            _data = data;
        } else {
            throw "Write data must of type string or blob";
            return;
        }

        // Write data via bulk transfer
        _bulkOut.write(_data);
    }
    

    // 
    // Handle a transfer complete event
    // 
    // @param  {Table} eventdetails Table with the transfer event details
    // 
    function _transferComplete(eventdetails) {
        local direction = (eventdetails["endpoint"] & 0x80) >> 7;
        if (direction == USB_DIRECTION_IN) {
            local readData = _bulkIn.done(eventdetails);
            if (readData.len() >= 3) {
                readData.seek(2);
                _onEvent("data", readData.readblob(readData.len()));
            }
            // Blank the buffer
            _bulkIn.read(blob(64 + 2));
        } else if (direction == USB_DIRECTION_OUT) {
            _bulkOut.done(eventdetails);
        }
    }


    // 
    // Initialize the buffer.
    // 
    function _start() {
        _bulkIn.read(blob(64 + 2));
    }

// Testing Factory Code
class Imp005EZEval_TestingFactory {

    constructor(ssid, password) {
        FactoryTools.isFactoryFirmware(function(isFactoryEnv) {
            if (isFactoryEnv) {
                FactoryTools.isFactoryImp() ? RunFactoryFixture(ssid, password) : RunDeviceUnderTest();
            } else {
              server.log("This firmware is not running in the Factory Environment");
            }
        }.bindenv(this))
    }

    RunFactoryFixture = class {

        static FIXTURE_BANNER = "EZ Eval Tests";

        // How long to wait (seconds) after triggering BlinkUp before allowing another
        static BLINKUP_TIME = 5;

        // Flag used to prevent new BlinkUp triggers while BlinkUp is running
        sendingBlinkUp = false;

        FactoryFixture_005 = null;
        lcd = null;
        printer = null;

        _ssid = null;
        _password = null;

        constructor(ssid, password) {
            imp.enableblinkup(true);
            _ssid = ssid;
            _password = password;

            // Factory Fixture HAL
            FactoryFixture_005 = {
                "LED_RED" : hardware.pinF,
                "LED_GREEN" : hardware.pinE,
                "BLINKUP_PIN" : hardware.pinM,
                "GREEN_BTN" : hardware.pinC,
                "FOOTSWITCH" : hardware.pinH,
                "LCD_DISPLAY_UART" : hardware.uart2,
                "USB_PWR_EN" : hardware.pinR,
                "USB_FAULT_L" : hardware.pinW,
                "RS232_UART" : hardware.uart0,
                "FTDI_UART" : hardware.uart1,
            }

            // Initialize front panel LEDs to Off
            FactoryFixture_005.LED_RED.configure(DIGITAL_OUT, 0);
            FactoryFixture_005.LED_GREEN.configure(DIGITAL_OUT, 0);

            // Intiate factory BlinkUp on either a front-panel button press or footswitch press
            configureBlinkUpTrigger(FactoryFixture_005.GREEN_BTN);
            configureBlinkUpTrigger(FactoryFixture_005.FOOTSWITCH);

            lcd = CFAx33KL(FactoryFixture_005.LCD_DISPLAY_UART);
            setDefaultDisply();
            configurePrinter();

            // Open agent listener
            agent.on("data.to.print", printLabel.bindenv(this));
        }

        function configureBlinkUpTrigger(pin) {
            // Register a state-change callback for BlinkUp Trigger Pins
            pin.configure(DIGITAL_IN, function() {
                // Trigger only on rising edges, when BlinkUp is not already running
                if (pin.read() && !sendingBlinkUp) {
                    sendingBlinkUp = true;
                    imp.wakeup(BLINKUP_TIME, function() {
                        sendingBlinkUp = false;
                    }.bindenv(this));

                    // Send factory BlinkUp
                    server.factoryblinkup(_ssid, _password, FactoryFixture_005.BLINKUP_PIN, BLINKUP_FAST | BLINKUP_ACTIVEHIGH);
                }
            }.bindenv(this));
        }

        function setDefaultDisply() {
            lcd.clearAll();
            lcd.setLine1("Electric Imp");
            lcd.setLine2(FIXTURE_BANNER);
            lcd.setBrightness(100);
            lcd.storeCurrentStateAsBootState();
        }

        function configurePrinter() {
            FactoryFixture_005.RS232_UART.configure(9600, 8, PARITY_NONE, 1, NO_CTSRTS, function() {
                server.log(uart.readstring());
            });

            printer = QL720NW(FactoryFixture_005.RS232_UART).setOrientation(QL720NW.PORTRAIT);
        }

        function configurePinterFontSettings() {
            printer.setFont(QL720NW_FONT_HELSINKI)
                   .setFontSize(QL720NW_FONT_SIZE_48);
        }

        function printLabel(data) {
            if (printer == null) configurePrinter();

            if ("mac" in data) {
                // Set 1st label font settings
                configurePinterFontSettings();
                // Add 2D barcode of mac address to 1st label
                printer.write2dBarcode(data.mac, QL720NW_BARCODE_2D_QR, {"cell_size": 5 });
                // Add mac address to 1st label
                printer.write(data.mac).pageFeed();

                // Set 2nd label font settings
                configurePinterFontSettings();
                // Add 2D barcode of mac address to 2nd label
                printer.write2dBarcode(data.mac, QL720NW_BARCODE_2D_QR, {"cell_size": 5 });
                // Add mac address to 2nd label
                printer.write(data.mac);

                // Print label
                printer.print();

                // Log status
                server.log("Printed: " + data.mac);
            }
        }
    }


    RunDeviceUnderTest = class {

        static LED_FEEDBACK_AFTER_TEST = 1;
        static PAUSE_BTWN_TESTS = 0.5;

        test = null;

        constructor() {
            test = Imp005EZEval_TestingFactory.RunDeviceUnderTest.EZTestingSuite(LED_FEEDBACK_AFTER_TEST, PAUSE_BTWN_TESTS, testsDone.bindenv(this));
            test.run();
        }

        function testsDone(passed) {
            // Only print label for passing hardware
            if (passed) {
                local deviceData = {};
                deviceData.mac <- imp.getmacaddress();
                deviceData.id <- hardware.getdeviceid();
                server.log("Sending Label Data: " + deviceData.mac);
                agent.send("set.label.data", deviceData);
            }

            // Clear wifi credentials on power cycle
            imp.clearconfiguration();
        }


        // Static testing class
        // All tests return promises that resolve if test passes or reject if test fails
        // NOTE: LED test are not included in this class
        EZTests = class {

            function ADCTest(adc, chan, expected, range) {
                server.log("ADC test.");
                return Promise(function(resolve, reject) {
                    local lower = expected - range;
                    local upper = expected + range;
                    local reading = adc.readADC(chan);
                    return (reading > lower && reading < upper) ? resolve("ADC readings on chan " + chan + " in range.") : reject("ADC readings not in range. Chan : " + chan + " Reading: " + reading);
                }.bindenv(this))
            }

            function ic2test(i2c, addr, reg, expected) {
                server.log("i2c read register test.");
                return Promise(function(resolve, reject) {
                    local result = i2c.read(addr, reg.tochar(), 1);
                    if (result == null) return reject("i2c read error: " + i2c.readerror());
                    return (result == expected.tochar()) ? resolve("I2C read returned expected value.") : reject("I2C read returned " + result);
                }.bindenv(this))
            }

            // Test written for HTS221, with Electric Imp Library Driver
            // Test DOES NOT configure sensor or set into a mode that takes readings
            function tempHumidTest(sensor, t_expected, t_range, h_expected, h_range) {
                server.log("Temp/Humid reading test.");
                return Promise(function(resolve, reject) {
                    local result = sensor.read();
                    if ("error" in result) return reject("Temp/Humid read error: " + result.error);
                    
                    if ("temperature" in result && "humidity" in result) {
                        local t_lower = t_expected - t_range;
                        local t_upper = t_expected + t_range;
                        local h_lower = h_expected - h_range;
                        local h_upper = h_expected + h_range;
                        if (result.temperature > t_lower && result.temperature < t_upper && result.humidity > h_lower && result.humidity < h_upper) {
                            return resolve("Temperature and humidity readings within range.");
                        } else {
                            return reject("Temperature and humidity readings NOT in range.")
                        }
                    } else {
                        return reject("Error: tempHumid reading missing temperature or humidity value.");
                    }
                }.bindenv(this))
            }

            // Test written for LIS3DH or LIS2DH, with Electric Imp Library Driver
            // Test DOES NOT configure sensor or set into a mode that takes readings
            function accelTest(sensor, expected, range) {
                server.log("Accelerometer reading test.");
                return Promise(function(resolve, reject) {
                    local result = sensor.getAccel();
                    if ("error" in result) return reject("Accelerometer read error: " + result.error);
                    
                    if ("x" in result && "y" in result && "z" in result) {
                        local lower = expected - range;
                        local upper = expected + range;
                        if (result.x > lower && result.x < upper && result.y > lower && result.y < upper && result.z > lower && result.z < upper) {
                            return resolve("Accelerometer readings within range.");
                        } else {
                            return reject("Accelerometer readings NOT in range.")
                        }
                    } else {
                        return reject("Error: Accelerometer reading missing axis data.");
                    }
                }.bindenv(this))
            }

            // Requires a USB FTDI device
            // Initializes USB host and FTDI driver
            // Looks for an onConnected FTDI device
            function usbFTDITest() {
                server.log("USB test.");
                return Promise(function(resolve, reject) {
                    // Setup usb
                    local usbHost = USB.Host(hardware.usb);
                    usbHost.registerDriver(FtdiUsbDriver, FtdiUsbDriver.getIdentifiers());
                    local timeout = imp.wakeup(5, function() {
                        return reject("FTDI USB Driver not found. USB test failed.");
                    }.bindenv(this))
                    usbHost.on("connected", function(device) {
                        imp.cancelwakeup(timeout);
                        if (typeof device == "FtdiUsbDriver") {
                            return resolve("FTDI USB Driver found. USB test passed.");
                        } else {
                            return reject("FTDI USB Driver not found. USB test failed.");
                        }
                    }.bindenv(this));
                }.bindenv(this))
            }

        }

        EZTestingSuite = class {

            // NOTE: LED tests are included in this class not the test class

            static LED_RED    = [50, 0, 0];
            static LED_GREEN  = [0, 50, 0];
            static LED_YELLOW = [45, 45, 0];
            static LED_OFF    = [0, 0, 0];

            feedbackTimer = null;
            pauseTimer = null;
            done = null;

            ezEval = null;
            tests = null;       
            tempHumid = null;
            accel = null;
            adc = null;
            led = null;

            failedCount = 0;

            constructor(_feedbackTimer, _pauseTimer, _done) {
                feedbackTimer = _feedbackTimer;
                pauseTimer = _pauseTimer;
                done = _done;

                // assign HAL here 
                ezEval = { "LED_SPI_CLK"    : hardware.pinT,
                           "LED_SPI_DATA"   : hardware.pinY,
                           "SENSOR_I2C"     : hardware.i2c0,
                           "TEMPHUMID_ADDR" : 0xBE,
                           "ACCEL_ADDR"     : 0x32,
                           "ADC_SPI"        : hardware.spi0,
                           "USB_EN"         : hardware.pinR,
                           "USB_LOAD_FLAG"  : hardware.pinW };

                // Configure Hardware
                configureLEDs();
                configureTempHumid();
                configureAccel();
                configureADC();

                // Create Pointer to tests
                tests = Imp005EZEval_TestingFactory.RunDeviceUnderTest.EZTests;
            }

            // This method runs all tests
            // When testing complete should call done with one param - allTestsPassed (bool)
            function run() {
                pause()
                    .then(function(msg) {
                        server.log(msg);
                        return ledTest();
                    }.bindenv(this))
                    .then(passed.bindenv(this), failed.bindenv(this))
                    .then(function(msg) {
                        server.log(msg);
                        return tests.usbFTDITest();
                    }.bindenv(this))
                    .then(passed.bindenv(this), failed.bindenv(this))
                    .then(function(msg) {
                        server.log(msg);
                        local expectedTemp = 25;
                        local tempRange = 50;
                        local expectedHumid = 50;
                        local humidRange = 50;
                        return tests.tempHumidTest(tempHumid, expectedTemp, tempRange, expectedHumid, humidRange);
                    }.bindenv(this))
                    .then(passed.bindenv(this), failed.bindenv(this))
                    .then(function(msg) {   
                        server.log(msg);
                        local expected = 0;
                        local range = 2;
                        return tests.accelTest(accel, expected, range);
                    }.bindenv(this))
                    .then(passed.bindenv(this), failed.bindenv(this))       
                    .then(function(msg) {   
                        server.log(msg);
                        local chan = 6;
                        local expected = 0;
                        local range = 0.2;
                        return tests.ADCTest(adc, chan, expected, range);
                    }.bindenv(this))
                    .then(passed.bindenv(this), failed.bindenv(this))   
                    .then(function(msg) {   
                        server.log(msg);
                        local chan = 7;
                        local expected = 2.5; // expecting 2.5
                        local range = 0.2;
                        return tests.ADCTest(adc, chan, expected, range);
                    }.bindenv(this))
                    .then(passed.bindenv(this), failed.bindenv(this))                               
                    .then(function(msg) {
                        local passing = (failedCount == 0);
                        led.fill(LED_YELLOW).draw();
                        imp.wakeup(pauseTimer, function() {
                            (passing) ? led.fill(LED_GREEN).draw() : led.fill(LED_RED).draw();
                            done(passing); 
                        }.bindenv(this))
                    }.bindenv(this))
            }

            // HARDWARE CONFIGURATION HELPERS
            // -----------------------------------------------------------------------------
            function configureLEDs() {
                local numLEDs = 1;
                led = APA102(null, numLEDs, ezEval.LED_SPI_CLK, ezEval.LED_SPI_DATA).draw();
            }

            function configureTempHumid() {
                ezEval.SENSOR_I2C.configure(CLOCK_SPEED_400_KHZ);
                tempHumid = HTS221(ezEval.SENSOR_I2C, ezEval.TEMPHUMID_ADDR);
                tempHumid.setMode(HTS221_MODE.ONE_SHOT);
            }

            function configureAccel() {
                ezEval.SENSOR_I2C.configure(CLOCK_SPEED_400_KHZ);
                accel = LIS3DH(ezEval.SENSOR_I2C, ezEval.ACCEL_ADDR);
                accel.reset();
                accel.setDataRate(100);
            }

            function configureADC() {
                local speed = 100;
                local vref = 3.3;
                ezEval.ADC_SPI.configure(CLOCK_IDLE_LOW | MSB_FIRST | USE_CS_L, speed);
                adc = MCP3208(ezEval.ADC_SPI, vref);
            }

            // TESTING HELPERS
            // -----------------------------------------------------------------------------

            // Used to space out tests
            function pause(double = false) {
                local pauseTime = (double) ? pauseTimer * 2 : pauseTimer;
                return Promise(function(resolve, reject) {
                    imp.wakeup(pauseTime, function() {
                        return resolve("Start...");
                    });
                }.bindenv(this))
            }

            function passed(msg) {
                server.log(msg);
                return Promise(function (resolve, reject) {
                    led.fill(LED_GREEN).draw();
                    imp.wakeup(feedbackTimer, function() {
                        led.fill(LED_OFF).draw();
                        imp.wakeup(pauseTimer, function() {
                            return resolve("Start...");
                        });
                    }.bindenv(this));
                }.bindenv(this))
            }

            function failed(errMsg) {
                server.error(errMsg);   
                return Promise(function (resolve, reject) {
                    led.fill(LED_RED).draw();
                    failedCount ++;
                    imp.wakeup(feedbackTimer, function() {
                        led.fill(LED_OFF).draw();
                        imp.wakeup(pauseTimer, function() {
                            return resolve("Start...");
                        });
                    }.bindenv(this));
                }.bindenv(this))
            }

            function ledTest() {
                server.log("Testing LEDs.");
                // turn LEDs on one at a time
                // then pass a passing test result  
                return Promise(function (resolve, reject) {
                    led.fill(LED_RED).draw();
                    imp.wakeup(feedbackTimer, function() {
                        led.fill(LED_OFF).draw();
                        imp.wakeup(pauseTimer, function() {
                            led.fill(LED_YELLOW).draw();
                            imp.wakeup(feedbackTimer, function() {
                                led.fill(LED_OFF).draw();
                                imp.wakeup(pauseTimer, function() {
                                    led.fill(LED_GREEN).draw();
                                    imp.wakeup(feedbackTimer, function() {
                                        led.fill(LED_OFF).draw();
                                        return resolve("LEDs Testing Done.");
                                    }.bindenv(this))
                                }.bindenv(this))
                            }.bindenv(this))
                        }.bindenv(this))
                    }.bindenv(this))
                }.bindenv(this))
            }

        } // Close EZTestingSuite

    } // Close RunDeviceUnderTest

} // Close Imp005EZEval_TestingFactory


// // Factory Code
// // ------------------------------------------
server.log("Device Running...");

const SSID = "";
const PASSWORD = "";

Imp005EZEval_TestingFactory(SSID, PASSWORD);
