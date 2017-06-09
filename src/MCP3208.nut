/*
	This part is frequency limited. For example, through testing, it was accurate
	within 10% up to ~200kHz clock frequency given 120k impedance. For specific max
	clock frequency as a function of impedance, see figure 4-2 in the datasheet
	
	http://ww1.microchip.com/downloads/en/DeviceDoc/21298c.pdf


*/



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
	
	static ADC_MAX = 4095.0;

    _spiPin = null;
	_csPin = null;
	_vref = null;
	
	function constructor(spiPin, vref, cs=null) { 
		this._spiPin = spiPin; // assume it's already been configured 
		
		this._csPin = cs;
		
		this._vref = vref;
	}
	
	function readADC(channel) {
		csLow();
		
        // 3 byte command
        local sent = blob();
        sent.writen(0x06 | (channel >> 2), 'b'); // for single, bit after start bit is a 1
        sent.writen((channel << 6) & 0xFF, 'b');
        sent.writen(0, 'b');
        
        local read = _spiPin.writeread(sent);

        csHigh();

        // Extract reading as volts
        local reading = ((((read[1] & 0x0f) << 8) | read[2]) / ADC_MAX) * _vref;
        return reading;
	}
	function readDifferential(in_minus, in_plus) {
	    csLow();
	    
	    local select = in_plus; // datasheet
		
		// 3 byte command 
	    local sent = blob();
	    sent.writen(0x04 | (select >> 2), 'b'); // for differential, bit after start bit is a 0
        sent.writen((select << 6) & 0xFF, 'b');
        sent.writen(0, 'b');
	    
	    local read = _spiPin.writeread(sent);
		
	    csHigh();
		
	    // Extract reading as volts 
	    local reading = ((((read[1] & 0x0f) << 8) | read[2]) / ADC_MAX) * _vref;
	    return reading;
	}
	
	function csLow() {
		if(_csPin == null) { // if no cs was passed, assume there is a hardware cs pin
			_spiPin.chipselect(1);
		}	
		else {
			_csPin.write(0);
		}
	}
	
	function csHigh() {
		if(_csPin == null) {
			_spiPin.chipselect(0);
		}	
		else {
			_csPin.write(1);
		}
	}
}
