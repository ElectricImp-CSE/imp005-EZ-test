
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
	_csPin = null;
	
	function constructor(spiPin= hardware.spi0, powerEnablePin = hardware.pinT, cs=null) { 
		this._spiPin = spiPin; // assume it's already been configured 
		
		// Pin T is the power enable to the ADC
		powerEnablePin.configure(DIGITAL_OUT, 1);
		
		this._csPin = cs;
		
	}
	
	function readADC(channel) {
		CSlow();
		
        // 3 byte command
        local sent = blob();
        sent.writen(0x06 | (channel >> 2), 'b');
        sent.writen((channel << 6) & 0xFF, 'b');
        sent.writen(0, 'b');
        
        local read = _spiPin.writeread(sent);

        CShigh();

        // Extract reading as volts
        local reading = ((((read[1] & 0x0f) << 8) | read[2]) / 4095.0) * 3.3;
        
        return reading;
	}
	function readDifferential(in_minus, in_plus) {
	    CSlow();
	    
	    local select = in_plus; // datasheet
	    local sent = blob();
	    
	    sent.writen(0x04 | (select >> 2), 'b'); // only difference b/w read single
	    // and read differential is the bit after the start bit
        sent.writen((select << 6) & 0xFF, 'b');
        sent.writen(0, 'b');
	    
	    
	    local read = _spiPin.writeread(sent);
	    CShigh();
	    
	    local reading = ((((read[1] & 0x0f) << 8) | read[2]) / 4095.0) * 3.3;
	    return reading;
	}
	function CSlow() {
		if(_csPin == null) {
			_spiPin.chipselect(1);
		}	
		else {
			_csPin.write(0);
		}
	}
	function CShigh() {
		if(_csPin == null) {
			_spiPin.chipselect(0);
		}	
		else {
			_csPin.write(1);
		}
	}
}


/*

myADC <- MCP3208(hardware.spi0, hardware.pinT);
while(true) {
    server.log(format("reading: %.2f v", myADC.readADC(1)));
    server.log(format("difference: %.2f v", myADC.readDifferential(0, 1)));
    imp.sleep(1);
}


*/