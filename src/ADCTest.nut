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

        local sent = blob();
        sent.writen(3 << 2 | channel >> 1, 'b');
        sent.writen((channel << 6) & 0xFF, 'b');
        local read = _spiPin.writeread(sent);

        if (_debug) {
            local co = "";
            sent.seek(0);
            for (local i = 0; i < sent.len(); i++) {
                co += format("%02x", sent.readn('b')) + " ";
            }
            _log(co);
        }

        _spiPin.chipselect(0);
        return read;
    }

    function test(resolve, reject) {
        local channels = [
            MCP3208_CHANNEL_0,
            MCP3208_CHANNEL_1,
            MCP3208_CHANNEL_2,
            MCP3208_CHANNEL_3,
            MCP3208_CHANNEL_4,
            MCP3208_CHANNEL_5,
            MCP3208_CHANNEL_6,
            MCP3208_CHANNEL_7
        ];

        foreach (c in channels) {
            local read = readADC(c);
            read.seek(0);
            for (local i = 0; i < read.len(); i++) {
                local val = read.readn('b');
                _log("read val = " + val);
                if (val != 0xFF && val != 0) {
                    resolve();
                    return;
                }
            }
        }
        reject("ADC Test failed!");
    }

    function _log(str) {
        if (_debug) {
            server.log("[ADCTest]: " + str);
        }
    }

    function _err(str) {
        if (_debug) {
            server.log("[ADCTest]: " + str);
        }
    }
}
