const USB_ENDPOINT_CONTROL = 0x00;
const USB_ENDPOINT_ISCHRONOUS = 0x01;
const USB_ENDPOINT_BULK = 0x02;
const USB_ENDPOINT_INTERRUPT = 0x03;

const USB_SETUP_HOST_TO_DEVICE = 0x00;
const USB_SETUP_DEVICE_TO_HOST =  0x80;
const USB_SETUP_TYPE_STANDARD = 0x00;
const USB_SETUP_TYPE_CLASS = 0x20;
const USB_SETUP_TYPE_VENDOR = 0x40;
const USB_SETUP_RECIPIENT_DEVICE = 0x00;
const USB_SETUP_RECIPIENT_INTERFACE = 0x01;
const USB_SETUP_RECIPIENT_ENDPOINT = 0x02;
const USB_SETUP_RECIPIENT_OTHER = 0x03;

const USB_REQUEST_GET_STATUS = 0;
const USB_REQUEST_CLEAR_FEATURE = 1;
const USB_REQUEST_SET_FEATURE = 3;
const USB_REQUEST_SET_ADDRESS = 5;
const USB_REQUEST_GET_DESCRIPTOR = 6;
const USB_REQUEST_SET_DESCRIPTOR = 7;
const USB_REQUEST_GET_CONFIGURATION = 8;
const USB_REQUEST_SET_CONFIGURATION = 9;
const USB_REQUEST_GET_INTERFACE = 10;
const USB_REQUEST_SET_INTERFACE = 11;
const USB_REQUEST_SYNCH_FRAME = 12;

const USB_DEVICE_DESCRIPTOR_LENGTH = 0x12;
const USB_CONFIGURATION_DESCRIPTOR_LENGTH = 0x09;

const USB_DESCRIPTOR_DEVICE = 0x01;
const USB_DESCRIPTOR_CONFIGURATION = 0x02;
const USB_DESCRIPTOR_STRING = 0x03;
const USB_DESCRIPTOR_INTERFACE = 0x04;
const USB_DESCRIPTOR_ENDPOINT = 0x05;
const USB_DESCRIPTOR_DEVICE_QUALIFIER = 0x06;
const USB_DESCRIPTOR_OTHER_SPEED = 0x07;
const USB_DESCRIPTOR_INTERFACE_POWER = 0x08;
const USB_DESCRIPTOR_OTG = 0x09;
const USB_DESCRIPTOR_HID = 0x21;

const USB_DIRECTION_OUT = 0x0;
const USB_DIRECTION_IN = 0x1;

// Extract the direction from and endpoint address
function directionString(direction) {
    if (direction == USB_DIRECTION_IN) {
        return "IN";
    } else if (direction == USB_DIRECTION_OUT) {
        return "OUT";
    } else {
        return "UNKNOWN";
    }
}

// Extract the endpoint type from attributes byte
function  endpointTypeString(attributes) {
    local type = attributes & 0x3;
    if (type == 0) {
        return "CONTROL";
    } else if (type == 1) {
        return "ISOCHRONOUS";
    } else if (type == 2) {
        return "BULK";
    } else if (type == 3) {
        return "INTERRUPT";
    }
}

class UsbHost {
    _eventHandlers = {};
    _address = 1;
    _usb = null
    _deviceConnected = false;

    constructor(usb) {
        _usb = usb;
        _eventHandlers[USB_DEVICE_CONNECTED] <- UsbHost.onDeviceConnected.bindenv(this);
        _eventHandlers[USB_DEVICE_DISCONNECTED] <- UsbHost.onDeviceDisconnected.bindenv(this);
        _eventHandlers[USB_TRANSFER_COMPLETED] <- UsbHost.onTransferCompleted.bindenv(this);
        _usb.configure(UsbHost.onEvent.bindenv(this)); 
    }

    function logDescriptors(speed, descriptor) {
        local maxPacketSize = descriptor["maxpacketsize0"];
        server.log("USB Device Connected, speed="+speed+" Mbit/s");
        server.log(format("usb = 0x%04x", descriptor["usb"]));
        server.log(format("class = 0x%02x", descriptor["class"]));
        server.log(format("subclass = 0x%02x", descriptor["subclass"]));
        server.log(format("protocol = 0x%02x", descriptor["protocol"]));
        server.log(format("maxpacketsize0 = 0x%02x", maxPacketSize));
        local manufacturer = getStringDescriptor(0, speed, maxPacketSize, descriptor["manufacturer"]);
        // server.log(format("VID = 0x%04x (%s)", descriptor["vendorid"], manufacturer));
        local product = getStringDescriptor(0, speed, maxPacketSize, descriptor["product"]);
        // server.log(format("PID = 0x%04x (%s)", descriptor["productid"], product));
        local serial = getStringDescriptor(0, speed, maxPacketSize, descriptor["serial"]);
        // server.log(format("device = 0x%04x (%s)", descriptor["device"], serial));

        local configuration = descriptor["configurations"][0];
        local configurationString = getStringDescriptor(0, speed, maxPacketSize, configuration["configuration"]);
        // server.log(format("Configuration: 0x%02x (%s)", configuration["value"], configurationString));
        // server.log(format("  attributes = 0x%02x", configuration["attributes"]));
        // server.log(format("  maxpower = 0x%02x", configuration["maxpower"]));

        foreach (interface in configuration["interfaces"]) {                        
            local  interfaceDescription = getStringDescriptor(0, speed, maxPacketSize, interface["interface"]);
            server.log(format("  Interface: 0x%02x (%s)", interface["interfacenumber"], interfaceDescription));
            server.log(format("    altsetting = 0x%02x", interface["altsetting"]));
            server.log(format("    class=0x%02x", interface["class"]));
            server.log(format("    subclass = 0x%02x", interface["subclass"]));
            server.log(format("    protocol = 0x%02x", interface["protocol"]));

            foreach (endpoint in interface["endpoints"]) {
                local address = endpoint["address"];
                local endpointNumber = address & 0x3; 
                local direction = (address & 0x80) >> 7;
                local attributes = endpoint["attributes"];
                local type = endpointTypeString(attributes); 
                server.log(format("    Endpoint: 0x%02x (ENDPOINT %d %s %s)", address, endpointNumber, type, directionString(direction)));
                server.log(format("      attributes = 0x%02x", attributes));
                server.log(format("      maxpacketsize = 0x%02x", endpoint["maxpacketsize"]));
                server.log(format("      interval = 0x%02x", endpoint["interval"]));
            }
        }
    }

    function controlTransfer(speed, deviceAddress, requestType, request, value, index, maxPacketSize) {
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            requestType,
            request,
            value,
            index,
            maxPacketSize
        );
    }

    function setAddress(address, speed, maxPacketSize) {
        _usb.controltransfer(
            speed,
            0,
            0,
            USB_SETUP_HOST_TO_DEVICE | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_SET_ADDRESS,
            address,
            0,
            maxPacketSize
        );
    }

    function setConfiguration(deviceAddress, speed, maxPacketSize, value) {
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            USB_SETUP_HOST_TO_DEVICE | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_SET_CONFIGURATION,
            value,
            0,
            maxPacketSize
        );
    }            

    function getStringDescriptor(deviceAddress, speed, maxPacketSize, index) {
        if (index == 0) {
            return "";
        }
        local buffer = blob(2);
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            USB_SETUP_DEVICE_TO_HOST | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_GET_DESCRIPTOR,
            (USB_DESCRIPTOR_STRING << 8) | index,
            0,
            maxPacketSize,
            buffer
        );
                
        local stringSize = buffer[0];
        buffer = blob(2+stringSize);
        _usb.controltransfer(
            speed,
            deviceAddress,
            0,
            USB_SETUP_DEVICE_TO_HOST | USB_SETUP_RECIPIENT_DEVICE,
            USB_REQUEST_GET_DESCRIPTOR,
            (USB_DESCRIPTOR_STRING << 8) | index,
            0,
            maxPacketSize,
            buffer
        );
                
        // String descriptors are zero-terminated, unicode. 
        // This could be done better.
        buffer.seek(2, 'b');
        local description = blob();
        while (!buffer.eos()) {
            local char = buffer.readn('b');
            if (char != 0) {
                description.writen(char, 'b');
            }
            buffer.readn('b'); 
        }
        return description.tostring();
    }

    function bulkTransfer(address, endpoint, type, data) {
        _usb.generaltransfer(address, endpoint, type, data);
    }

    function openEndpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress) {
        _usb.openendpoint(speed, deviceAddress, interfaceNumber, type, maxPacketSize, endpointAddress);
    }

    function onDeviceConnected(eventdetails) {
        local speed = eventdetails["speed"];
        local descriptors = eventdetails["descriptors"];
        logDescriptors(speed, descriptors);
        _deviceConnected = true;
    }

    function onDeviceDisconnected(eventdetails) {
        server.log("Device gone");
    }

    function onTransferCompleted(eventdetails) {
        _driver.transferComplete(eventdetails);
    }

    function onEvent(eventtype, eventdetails) {
        _eventHandlers[eventtype](eventdetails);
    }
};


class USBTest {
    _debug = null;

    _usbHost = null;

    function constructor(debug) {
        hardware.pinW.configure(DIGITAL_IN_PULLUP);

        hardware.pinR.configure(DIGITAL_OUT, 0);
        hardware.pinR.write(1);

        _usbHost = UsbHost(hardware.usb);

        _debug = debug;
    }

    function test(resolve, reject) {
        imp.wakeup(1, function() {
            if (_usbHost._deviceConnected) {
                resolve();
            } else {
                reject("USB Test Failed!");
            }
        }.bindenv(this));
    }

    function _log(str) {
        if (_debug) {
            server.log("[USB]: " + str);
        }
    }

    function _err(str) {
        if (_debug) {
            server.log("[USB]: " + str);
        }
    }
}