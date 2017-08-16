class LIS2DH12TRTest {
    _debug = null;
    _accel = null;
    _accelI2C = null;

    function constructor(debug) {
        local accelI2C = hardware.i2c0;
        accelI2C.configure(CLOCK_SPEED_400_KHZ);

        // Use a non-default I2C address (SA0 pulled high)
        _accel = LIS3DH(accelI2C, 0x32);
        _accel.init();
        _accel.setDataRate(100);

        imp.sleep(1);
        _debug = debug;
    }

    function test(resolve, reject) {
        local val = _accel.getAccel();
        _log("val.x = " + val.x + " val.y = " + val.y + " val.z = " + val.z);
        if (val.x || val.y || val.z) {
            resolve();
        } else {
            reject("LIS2DH12TR Test Failed!");
        }
    }

    function _log(str) {
        if (_debug) {
            server.log("[LIS2DH12TR]: " + str);
        }
    }

    function _err(str) {
        if (_debug) {
            server.log("[LIS2DH12TR]: " + str);
        }
    }
}
