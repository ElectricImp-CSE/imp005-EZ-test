
class LEDTest {

    static PACKET_LENGTH = 12;
    spiSclk = null;
    spiData = null;

    _debug = false;

    function constructor(debug) {
        spiSclk = hardware.pinT;
        spiData = hardware.pinY;

        spiSclk.configure(DIGITAL_OUT, 1);
        spiData.configure(DIGITAL_OUT, 0);

        this._debug = debug;
    }

    function swSPIWrite(data) {
        for (local j = 0; j < 8 ; j++){
            spiData.write(data & 0x80);
            spiSclk.write(0);
            imp.sleep(0.000001);
            spiSclk.write(1);   
            data = data << 1; 
        }
    }

    function setLED(brightness, red, green, blue) {
        local packet = blob(PACKET_LENGTH);
        local globalByte = 0xE0 | (brightness & 0x1F);
        
        packet[0] = 0x00;
        packet[1] = 0x00;
        packet[2] = 0x00;
        packet[3] = 0x00;        
        packet[4] = globalByte;
        packet[5] = blue;
        packet[6] = green;
        packet[7] = red;
        packet[8] = 0xFF;
        packet[9] = 0xFF;
        packet[10] = 0xFF;
        packet[11] = 0xFF;       
        
        for (local i = 0 ; i < PACKET_LENGTH ; i++) {   
            swSPIWrite(packet[i]);
        }
    }

    function test(resolve, reject) {
        setLED(0x10, 0x20, 0x00, 0x00);
        imp.sleep(0.5);
        setLED(0x10, 0x00, 0x20, 0x00);
        imp.sleep(0.5);
        setLED(0x10, 0x00, 0x00, 0x20);
        imp.sleep(0.5);
        setLED(0x00, 0x00, 0x00, 0x00);
        resolve();
    }

    function _log(str) {
        if (_debug) {
            server.log("[LED]: " + str);
        }
    }

    function _err(str) {
        if (_debug) {
            server.log("[LED]: " + str);
        }
    }    
}
