
class MCP3208 {

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
	
	function constructor(sspin = hardware.spi0) { // need to pass hardware pin to constructor
		this._spiPin = sspin;
		_spiPin.configure(USE_CS_L, 400);
		
		// Pin T is the power enable to the ADC
		hardware.pinT.configure(DIGITAL_OUT, 1);
		
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
        
        return reading;
	}
	function readDifferential(in_minus, in_plus) {
	    _spiPin.chipselect(1);
	    
	    local select = in_plus; // datasheet
	    local sent = blob();
	    
	    sent.writen(0x04 | (select >> 2), 'b'); // only difference b/w read single
	    // and read differential is the bit after the start bit
        sent.writen((select << 6) & 0xFF, 'b');
        sent.writen(0, 'b');
	    
	    
	    local read = _spiPin.writeread(sent);
	    _spiPin.chipselect(0);
	    
	    local reading = ((((read[1] & 0x0f) << 8) | read[2]) / 4095.0) * 3.3;
	    return reading;
	}

}

/*

myADC <- MCP3208(hardware.spi0);
while(true) {
    server.log(format("reading: %.2f v", myADC.readADC(1)));
    server.log(format("difference: %.2f v", myADC.readDifferential(0, 1)));
    imp.sleep(1);
}
*/