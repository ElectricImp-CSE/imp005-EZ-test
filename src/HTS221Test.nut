class HTS221Test {

    _debug = null;
    _tempHumid = null;

    function constructor(debug) {
        local temHumI2C = hardware.i2c0;
        temHumI2C.configure(CLOCK_SPEED_400_KHZ);

        _tempHumid = HTS221(temHumI2C);
        _tempHumid.setMode(HTS221_MODE.ONE_SHOT);

        this._debug = debug;
    }

    function test(resolve, reject) {
        _tempHumid.read(function(result) {
            if ("error" in result) {
                reject("HTS221 Test Failed: " + result.error);
            } else {
                resolve();
                _log(format("Current Humidity: %0.2f %s, Current Temperature: %0.2f °C", result.humidity, "%", result.temperature));
            }
        }.bindenv(this));
    }

    function _log(str) {
        if (_debug) {
            server.log("[HTC221Test]: " + str);
        }
    }

    function _err(str) {
        if (_debug) {
            server.log("[HTC221Test]: " + str);
        }
    }    

}
