//
// Test class for MCP3204
//
class ADCTest {

    static MCP3208_STARTBIT      = 0x10;
    static MCP3208_SINGLE_ENDED  = 0x08;
    static MCP3208_DIFF_MODE     = 0x00;

    static MCP3208_CHANNEL_0     = 0x00;
    static MCP3208_CHANNEL_1     = 0x01;
    static MCP3208_CHANNEL_2     = 0x02;
    static MCP3208_CHANNEL_3     = 0x03;
    static MCP3208_CHANNEL_4     = 0x04;
    static MCP3208_CHANNEL_5     = 0x05;
    static MCP3208_CHANNEL_6     = 0x06;
    static MCP3208_CHANNEL_7     = 0x07;

    _spiPin = null;
    _debug = false;

    function constructor(debug) {
        // Configure Hardware
        // Pin T is the power enable to the ADC
        hardware.pinT.configure(DIGITAL_OUT, 1);
        
        _spiPin = hardware.spi0;
        // Configure the operating parameters of the SPI bus
        _spiPin.configure(USE_CS_L, 400);

        this._debug = debug;
    }
    function readADC(channel) {
        _spiPin.chipselect(1);

        // 3 byte command
        local sent = blob();
        sent.writen(0x06 | (channel >> 2), 'b');
        sent.writen((channel << 6) & 0xFF, 'b');
        sent.writen(0, 'b');
        local read = _spiPin.writeread(sent);

        _spiPin.chipselect(0);

        // Extract reading as volts
        local reading = ((((read[1] & 0x0f) << 8) | read[2]) / 4095.0) * 3.3;
        
        if (_debug) {
            _log(format("ch%d = %.2fv", channel, reading));
        }
        return reading;
    }

    function test(resolve, reject) {
        // Read supply voltage; should be 2.4-2.6v
        local supplydiv2 = readADC(MCP3208_CHANNEL_7);
        if (supplydiv2 > 2.40 && supplydiv2 < 2.60) { 
            resolve();
            return;
        }
        reject("ADC Test failed!");
    }

    function _log(str) {
        if (_debug) {
            server.log("[ADC]: " + str);
        }
    }

    function _err(str) {
        if (_debug) {
            server.log("[ADC]: " + str);
        }
    }
}
