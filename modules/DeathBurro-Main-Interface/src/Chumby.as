/*
Chuby.as (for Adobe Flash Actionscript 2.0)

Based on ChumbyNative.as from Chumby Industries
Original Source: http://wiki.chumby.com/index.php/ChumbyNative

Additions & Modifications by Kristoffer Smith
Changes Copyright (c) Kristoffer Smith 2011
http://theksmith.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/


/*
designed for the Chumby One device with Firmware 1.7, may work with other hardware/versions
majority of functionality is available as static methods
advanced funtionality requires an instance
*/

class Chumby
{
	//------------- non-static public additions to original ChumbyNative.as -------------//
	
	
	/*
	for long running commands where output is needed
	execute a file or command asynchronously and trigger a callback function with the final output when complete
	if ignoring output and SHORT running cmd - use static fileExecuteAsynch() instead
	
	example usage (ignore output):
		var chmb:Chumby = new Chumby();
		chmb.fileExecuteAsynch('network_status.sh');
	
	example usage:
		var fileExecCallback = function(returnMsg, originalCmd) {
			trace('fileExecCallback() - file or cmd executed: ' + originalCmd);
			trace('fileExecCallback() - system return msg: ' + returnMsg);
		}
		var chmb:Chumby = new Chumby();
		chmb.fileExecuteAsynch('network_status.sh', fileExecCallback, this);
	*/
	public function fileExecuteAsynch(cmd:String, fnCallback:Function, objCallbackContainer:Object):Void {
		var exec:LoadVars = new LoadVars();
		exec.onData = function(rawData) {
			if (typeof(fnCallback) == typeof(Function)) {
				fnCallback.apply(objCallbackContainer, new Array(rawData, cmd));
			}
		}
		exec.load('exec://' + cmd);
	}

	/*
	output hi/lo (1/0) to a GPIO pin
	if you don't mind a 1 second process block - use static gpioSet() instead

	example usage (ignore output):
		var chmb:Chumby = new Chumby();
		chmb.gpioSetAsynch(0, 1, 1);
		
	example usage:
		var gpioSetCallback = function(returnMsg, returnSuccess, bank, pin, val) {
			trace('gpioSetCallback() - original bank/pin/val: ' + bank + '/' + pin + '/' + val);
			trace('gpioSetCallback() - cmd success: ' + returnSuccess);
			trace('gpioSetCallback() - cmd return msg: ' + returnMsg);
		}
		var chmb:Chumby = new Chumby();
		chmb.gpioSetAsynch(0, 1, 1, gpioSetCallback, this);
	*/
	public function gpioSetAsynch(bank:Number, pin:Number, val:Number, fnCallback:Function, objCallbackContainer:Object):Void {
		var cmd:String = _gpioGetSetCmdStr(bank, pin, val);

		var exec:LoadVars = new LoadVars();
		exec.onData = function(rawData) {
			if (typeof(fnCallback) == typeof(Function)) {
				var okCount:Number = 0;
				for (var i = 0; i < rawData.length; i++) {
					i = rawData.indexOf('ok', i);
					if (i == -1) break;
					i = i+2;
					okCount++;
				}
				var success:Boolean = (okCount == 3);
				fnCallback.apply(objCallbackContainer, new Array(rawData, success, bank, pin, val));
			}
		}
		exec.load('exec://' + cmd);
	}
		
	public function networkGetAllInfoAsynch(fnCallback:Function, objCallbackContainer:Object):Void {
		var xdoc:XML = new XML();
		xdoc.ignoreWhite = true;
		xdoc.onLoad = function(success) {
			if (typeof(fnCallback) == typeof(Function)) {
				fnCallback.apply(objCallbackContainer, new Array(xdoc, success));
			}
		}	
		xdoc.load('exec://network_status.sh');
	}

	public function networkGetStatusAsynch(fnCallback:Function, objCallbackContainer:Object):Void {
		var xdoc:XML = new XML();
		xdoc.ignoreWhite = true;
		xdoc.onLoad = function(success) {
			if (typeof(fnCallback) == typeof(Function)) {				
				var xnode = xdoc.firstChild.firstChild;
				fnCallback.apply(objCallbackContainer, new Array(xnode.attributes.up, xnode.attributes.ip));
			}
		}	
		xdoc.load('exec://network_status.sh');
	}
	
	
	//------------- static public additions to original ChumbyNative.as -------------//


	//output hi/lo (1/0) to a GPIO pin
	//returns 0 on success, else error msg
	//usage: var setOK:String = Chumby.gpioSet(0, 1, 1);
	public static function gpioSet(bank:Number, pin:Number, val:Number):String {
		var cmd:String = _gpioGetSetCmdStr(bank, pin, val);

		var output:String = fileExecute(cmd);
		var okCount:Number = 0;
		for (var i = 0; i < output.length; i++) {
			i = output.indexOf('ok', i);
			if (i == -1) break;
			i = i+2;
			okCount++;
		}
		
		if (okCount == 3) return '0';
		else return output;
	}

	//synchronous! for quick commands!
	//execute a file or command synchronously & return output
	public static function fileExecute(path:String):String {
		return _backtick(path);
	}

	//synchronous! for quick commands!
	//execute a file or command synchronously & return output chomped
	public static function fileExecuteChomped(path:String):String {
		return _chomp(_backtick(path));		
	}

	public static function filePut(path:String, rawData):Void {
		_putFile(path, rawData + '\n');
	}

	public static function fileExists(path:String):Boolean {
		return (_fileExists(path) == FILE_FOUND);
	}
	
	//synchronous! for short files!
	public static function fileGet(path:String):String {
		return _getFile(path);
	}

	//synchronous! for short files!
	public static function fileGetChomped(path:String):String {
		return _chomp(_getFile(path));
	}

	//true if running on a chumby (or a chumby dev environment) 
	//anyone know a better way?
	public static function isChumby():Boolean {
		return fileExists('/etc/firmware_build');
	}
	
	public static function touchclickIsEnabled():Boolean {
		return (_getTouchClick() == TOUCHCLICK_ON);
	}

	public static function touchclickSet(enable:Boolean):Void {
		if (enable) _setTouchClick(TOUCHCLICK_ON);
		else _setTouchClick(TOUCHCLICK_OFF);
	}
	
	public static function hasKeyboard():Boolean {
		return (_hasKeyboard() == 1)
	}	

	public static function soundGetVolume():Number {
		return (_getSystemVolume() == undefined) ? 0 : _getSystemVolume();
	}

	public static function soundSetVolume(percent:Number):Void {
		if (percent == undefined || percent == null || percent < 0) percent = 0;
		if (percent > 100) percent = 100;
		_setSystemVolume(percent);
	}
	
	public static function soundIsSpeakerMuted():Boolean {
		return (_getSpeakerMute() == SPEAKER_UNMUTED);
	}

	public static function soundSetSpeakerMuted(mute:Boolean):Void {
		if (mute) _setSpeakerMute(SPEAKER_MUTED);
		else  _setSpeakerMute(SPEAKER_UNMUTED);
	}

	public static function soundIsMuted():Boolean {
		return (_getSystemMute() == AUDIO_MUTE_ON);
	}

	public static function soundSetMuted(mute:Boolean):Void {
		if (mute) _setSystemMute() == AUDIO_MUTE_ON;
		else _setSystemMute() == AUDIO_MUTE_OFF;
	}

	public static function soundHasHeadphones():Boolean {
		return (_headphonesIn() == HEADPHONE_IN);
	}
	
	public static function buttonIsPressed():Boolean {
		return (_bent() == BENT);
	}

	public static function powerIsBattery():Boolean {
		//_powerSource() in original ChumbyNative.as not working
		return (fileGetChomped('/sys/class/power_supply/ac/online') == '0');
	}

	public static function powerIsBatteryPresent():Boolean {
		return (fileGetChomped('/sys/class/power_supply/battery/present') == '1');
	}
	
	public static function powerGetBatteryVolts():Number {
		//todo: how can i normalize this into a real-world value? divide by 1000000?
		//todo: should i use voltage_avg instead (how long is the average for)?
		//_batteryVolts() in original ChumbyNative.as not working
		return fileGetChomped('/sys/class/power_supply/battery/voltage_now') / 1000000;
	}

	public static var BATTERY_STATUS_UNKOWN:Number = 0;
	public static var BATTERY_STATUS_FULL:Number = 1;
	public static var BATTERY_STATUS_CHARGING:Number = 2;
	public static var BATTERY_STATUS_DISCHARGING:Number = 3;
	
	public static function powerGetBatteryStatus():Number {
		var stat:String = fileGetChomped('/sys/class/power_supply/battery/status');
		
		if (stat == 'Not charging') return BATTERY_STATUS_FULL;
		else if (stat == 'Charging') return BATTERY_STATUS_CHARGING;
		else if (stat == 'Discharging') return BATTERY_STATUS_DISCHARGING;
		else return BATTERY_STATUS_UNKOWN;
	}

	public static function powerGetBatteryStatusString():String {
		return fileGetChomped('/sys/class/power_supply/battery/status');
	}

	public static var BATTERY_HEALTH_UNKOWN:Number = 0;
	public static var BATTERY_HEALTH_GOOD:Number = 1;

	public static function powerGetBatteryHealth():Number {
		var health:String = fileGetChomped('/sys/class/power_supply/battery/health');
		
		//todo: what are the other status this could return?
		if (health == 'Good') return BATTERY_HEALTH_GOOD;
		else return BATTERY_HEALTH_UNKOWN;
	}

	public static function powerGetBatteryHealthString():String {
		return fileGetChomped('/sys/class/power_supply/battery/health');
	}

	public static function powerShutdown():Void {
		_powerDown(POWER_DOWN_NOW);
	}

	public static function powerReboot():Void {
		//_restartNow() in original ChumbyNative.as not working
		_backtick('reboot_normal.sh');
	}

	public static var SCREEN_ON:Number = 0;
	public static var SCREEN_DIM:Number = 1;
	public static var SCREEN_OFF:Number = 2;
	
	public static function screenGetStatus():Number {
		var mute:Number = _getLCDMute();
		var bright:Number = screenGetBacklight();
		
		if (mute == SCREEN_OFF || bright == 0) return SCREEN_OFF;
		else if (mute == SCREEN_DIM || bright <= 50) return SCREEN_DIM;
		else return SCREEN_ON;
	}

	public static function screenSetStatus(stat:Number):Void {
		//_setLCDMute() from original ChumbyNative.as not working...
		//if (stat == SCREEN_ON || stat == SCREEN_DIM || stat == SCREEN_OFF) _setLCDMute(stat);
		//else _setLCDMute(SCREEN_ON);

		if (stat == SCREEN_DIM) screenSetBacklight(50);
		else if (stat == SCREEN_OFF) screenSetBacklight(0);
		else screenSetBacklight(100);
		
	}

	//return current lcd brightness normalized to range 0-100
	public static function screenGetBacklight():Number {
		var percent:Number = _getLCDBrightness();
		return (percent != undefined) ? Math.round(percent / BRIGHTNESS_MAX * 100) : undefined;
	}
	
	//sets lcd brightness within a normalized range of 0-100
	public static function screenSetBacklight(percent:Number):Void {
		if (percent == undefined || percent == null || percent < 0) percent = 0;
		if (percent > 100) percent = 100;
		percent = Math.round(percent / 100 * BRIGHTNESS_MAX);
		_setLCDBrightness(percent);
	}

	//return current accelerometer coords normalized so that X/Y/Z ranges -100 to 100 (with near 0 being still)
	//optionally pass in your chumby's known realistic max X/Y/Z values for greater resolution/precision
	//optionally pass in allowSimulation = true to have random values sent back if not running on chumby
	public static function getXYZ(maxXYZ:Array, allowSimulation:Boolean):Array {
		var max:Number;		
		var xyz:Array = new Array();
		
		if (!isChumby() && allowSimulation) {
			xyz[0] = Math.random() * 4095;
			xyz[1] = Math.random() * 4095;
			xyz[2] = Math.random() * 4095;
		} else {
			xyz[0] = (_accelerometer(ACCELEROMETER_AVERAGE_X) == undefined) ? 0 : _accelerometer(ACCELEROMETER_AVERAGE_X);
			xyz[1] = (_accelerometer(ACCELEROMETER_AVERAGE_Y) == undefined) ? 0 : _accelerometer(ACCELEROMETER_AVERAGE_Y);
			xyz[2] = (_accelerometer(ACCELEROMETER_AVERAGE_Z) == undefined) ? 0 : _accelerometer(ACCELEROMETER_AVERAGE_Z);
		}

		if (xyz[0] > 0) {			
			max = (maxXYZ[0] > 0) ? maxXYZ[0] : 4095;
			xyz[0] = Math.round((xyz[0] - max) / (max / 100));
		}
		if (xyz[1] > 0) {			
			max = (maxXYZ[1] > 0) ? maxXYZ[1] : 4095;
			xyz[1] = Math.round((xyz[1] - max) / (max / 100));
		}
		if (xyz[2] > 0) {			
			max = (maxXYZ[2] > 0) ? maxXYZ[2] : 4095;
			xyz[2] = Math.round((xyz[2] - max) / (max / 100));
		}

		return xyz;
	}
	
	
	//------------- private additions to original ChumbyNative.as -------------//
	

	private static function _gpioGetSetCmdStr(bank:Number, pin:Number, val:Number):String {
		var err:String = 'Unknown error';
		var msk:String;
		var addr:String;
		
		//todo: finish lookup table or create calculation to determine mask & address (see the processor manual)
		if (bank == 0 && pin == 1) {
			msk = '0x0000000c';
			addr = '0x00000002';
		} else if (bank == 0 && pin == 2) {
			msk = '0x00000003';
			addr = '0x00000001';			
		} else {
			err = 'Unsupported bank/pin';
			return err; 
		}
		
		//todo: is it possible to output other values besides 1/0?
		if (val == 0) {
			var cmd:String = 'regutil -w HW_PINCTRL_MUXSEL0_SET=' + msk + ' && regutil -w HW_PINCTRL_DOE0_SET=' + addr + ' && regutil -w HW_PINCTRL_DOUT0_CLR=' + addr;
		} else if (val == 1) {
			var cmd:String = 'regutil -w HW_PINCTRL_MUXSEL0_SET=' + msk + ' && regutil -w HW_PINCTRL_DOE0_SET=' + addr + ' && regutil -w HW_PINCTRL_DOUT0_SET=' + addr;
		} else {
			err = 'Unsupported val';
			return err;
		}
		
		return cmd;
	}
	
	
	//------------- from original ChumbyNative.as -------------//
	
	
	//
	// file operations
	//
	static var _getFile:Function = _global.ASnative(5,50); // (path:String):String
	static var _putFile:Function = _global.ASnative(5,51); // (path:String,data:String)
	static var _backtick:Function = _global.ASnative(5,52); // (path:String):String
	static var _fileExists:Function = _global.ASnative(5,53); // ():Number
	static var FILE_NOT_FOUND:Number = 0;
	static var FILE_FOUND:Number = 1;
	static var _fileSize:Function = _global.ASnative(5,54); // (path:String):Number
	static var _unlink:Function = _global.ASnative(5,55); // (path:String):Void
	//
	// directories
	//
	static var _getDirectoryEntry = _global.ASnative(5,320); // (o:Object,path:String,index:Number):Number
	static var DIRECTORY_ENTRY_INVALID_PATH:Number = -1;
	static var DIRECTORY_ENTRY_INVALID_INDEX:Number = 0;
	static var DIRECTORY_ENTRY_SUCCESS:Number = 1;
	// returns properties in o:
	// _path:String; // full path
	// _isDirLink:Boolean; // true if . or ..
	// _name:String; // file or dir name
	// _type:Number; // entry type
	// _inode:Number; // inode number
	// _mode:Number; // file access mode
	// _isDir:Boolean; // true if directory
	// _isFile:Boolean; // true if file
	// _isSymLink:Boolean; // true if symbolic link
	// _isChar:Boolean; // true if a character device
	// _isBlock:Boolean; // true if block device
	// _size:Number; // dir or file size in bytes
	// _blockSize:Number; // size of blocks if block device
	// _lastModified:Number; // timestamp for last modification
	// _deviceId:Number; // id of device on which the file resides
	//
	// touchscreen
	//
	static var _rawX:Function = _global.ASnative(5,10); // ():Number
	static var _rawY:Function = _global.ASnative(5,11); // ():Number
	static var _setCalibration:Function = _global.ASnative(5,12); // (xoffset:Number,xscale:Number,yoffset:Number,yscale:Number)
	static var _writeCalibration:Function = _global.ASnative(5,13); // ():Void
	static var _getTouchClick:Function = _global.ASnative(5,43); // ():Number
	static var _setTouchClick:Function = _global.ASnative(5,44); // (doClick:Number):Void
	static var TOUCHCLICK_OFF:Number = 0;
	static var TOUCHCLICK_ON:Number = 1;
	//
	// keyboard
	//
	static var _getKeyboardEventMask:Function = _global.ASnative(5,90); // ():Number
	static var _setKeyboardEventMask:Function = _global.ASnative(5,92); // (mask:Number):Void
	static var _hasKeyboard:Function = _global.ASnative(5,91); // ():Number
	static var KEYBOARD_EVENT_MASK_KEYBOARD:Number = 1;
	static var KEYBOARD_EVENT_MASK_MEDIA:Number = 2;
	static var KEYBOARD_EVENT_MASK_ALL:Number = 3;
	static var _keyboardGetScanCode:Function = _global.ASnative(5,93); // ():Number
	static var KEYBOARD_SCAN_MASK_SHIFT:Number = 0x0100;
	static var KEYBOARD_SCAN_MASK_CTRL:Number = 0x0200;
	static var KEYBOARD_SCAN_MASK_ALT:Number = 0x0400;
	static var KEYBOARD_SCAN_MASK_CAPS_LOCK:Number = 0x0800;
	static var KEYBOARD_SCAN_MASK_NUM_LOCK:Number = 0x1000;
	static var KEYBOARD_SCAN_MASK_LEFT:Number = 0x2000;
	static var KEYBOARD_SCAN_MASK_RIGHT:Number = 0x4000;
	static var _keyboardGetString:Function = _global.ASnative(5,93); // (cooked:Number,maxChars:Number):String
	static var _getKeyEventOfferMask:Function = _global.ASnative(5,98); // ():Number
	static var _setKeyEventOfferMask:Function = _global.ASnative(5,99); // (n:Number):Void
	static var KEYBOARD_OFFER_MASK_ENABLED:Number = 1;
	static var KEYBOARD_OFFER_MASK_DISABLED:Number = 0;
	//
	// mouse
	//
	static var _getMouseButtonState:Function = _global.ASnative(5,94); // ():Number
	static var MOUSE_LEFT_BUTTON_MASK:Number = 1;
	static var MOUSE_MIDDLE_BUTTON_MASK:Number = 2;
	static var MOUSE_RIGHT_BUTTON_MASK:Number = 4;
	static var MOUSE_LEFT_SIDE_BUTTON_MASK:Number = 8;
	static var MOUSE_RIGHT_SIDE_BUTTON_MASK:Number = 16;
	static var _getNextMouseEvent:Function = _global.ASnative(5,95); // ():Number
	static function _mouseEventType(event:Number):Number {
		return (event>>24) & 0xff;
	}
	static function _mouseEventValue(event:Number):Number {
		return (event>>16) & 0xff;
	}
	static var MOUSE_EVENT_TYPE_WHEEL:Number = 8;
	static var MOUSE_EVENT_TYPE_MOVE:Number = 2;
	static var MOUSE_EVENT_TYPE_BUTTON:Number = 1;
	static function _mouseEventCode(event:Number):Number {
		return event & 0xffff;
	}
	//
	// gamepad
	//
	static var _getGamepadState:Function = _global.ASnative(5,96); // ():Number
	static var _getNextGamepadEvent:Function = _global.ASnative(5,97); // ():Number
	//
	// speaker
	//
	static var _getSpeakerMute:Function = _global.ASnative(5,17); // ():Number
	static var _setSpeakerMute:Function = _global.ASnative(5,18); // (mute:Number):Void
	static var SPEAKER_UNMUTED:Number = 0;
	static var SPEAKER_MUTED:Number = 1;
	//
	// headphone jack
	//
	static var _headphonesIn:Function = _global.ASnative(5,38); // ():Number
	static var HEADPHONE_OUT:Number = 0;
	static var HEADPHONE_IN:Number = 1;
	//
	// LCD mute (HW 3.5, 3.6, 3.7)
	//
	static var _getLCDMute:Function = _global.ASnative(5,19); // ():Number
	static var _setLCDMute:Function = _global.ASnative(5,20); // (mute:Number):Void
	static var LCD_ON:Number = 0;
	static var LCD_DIM:Number = 1;
	static var LCD_OFF:Number = 2;
	//
	// LCD brightness (Ironforge HW 3.8 and later, Stormwind)
	//
	static var _getLCDBrightness:Function = _global.ASnative(5,21); // ():Number
	static var _setLCDBrightness:Function = _global.ASnative(5,22); // (brightness:Number):Void
	static var BRIGHTNESS_MIN:Number = 0;
	//incorrect, actually turns off screen: static var BRIGHTNESS_MAX:Number = 65536;
	static var BRIGHTNESS_MAX:Number = 65535;
	//
	// bend sensor
	//
	static var _bent:Function = _global.ASnative(5,25); // ():Number
	static var UNBENT:Number = 0;
	static var BENT:Number = 1;
	//
	// accelerometer
	//
	static var _accelerometer:Function = _global.ASnative(5,60); // (index:Number):Number
	static var ACCELEROMETER_VERSION:Number = 0;
	static var ACCELEROMETER_TIMESTAMP:Number = 1;
	static var ACCELEROMETER_CURRENT:Number = 2;
	static var ACCELEROMETER_CURRENT_X:Number = 2;
	static var ACCELEROMETER_CURRENT_Y:Number = 3;
	static var ACCELEROMETER_CURRENT_Z:Number = 4;
	static var ACCELEROMETER_AVERAGE:Number = 5;
	static var ACCELEROMETER_AVERAGE_X:Number = 5;
	static var ACCELEROMETER_AVERAGE_Y:Number = 6;
	static var ACCELEROMETER_AVERAGE_Z:Number = 7;
	static var ACCELEROMETER_IMPACT:Number = 8;
	static var ACCELEROMETER_IMPACT_X:Number = 8;
	static var ACCELEROMETER_IMPACT_Y:Number = 9;
	static var ACCELEROMETER_IMPACT_Z:Number = 10;
	static var ACCELEROMETER_IMPACT_TIME:Number = 11;
	static var ACCELEROMETER_IMPACT_HINTS:Number = 12;
	//
	// DC Power
	//
	static var _dcVolts:Function = _global.ASnative(5,16); // ():Number
	static var _batteryVolts:Function = _global.ASnative(5,39); // ():Number
	static var _powerSource:Function = _global.ASnative(5,41); // ():Number
	static var POWER_SOURCE_EXTERNAL:Number = 0;
	static var POWER_SOURCE_BATTERY:Number = 1;	
	//
	// power management
	//
	static var _powerDown:Function = _global.ASnative(5,40); // (when:Number[,secondsToPowerUp:Number]):Void
	static var POWER_DOWN_ON_EXIT:Number = 1;
	static var POWER_DOWN_NOW:Number = 2;
	//
	// graphic overlay
	//
	static var _setOverlayVisibility:Function = _global.ASnative(5,110); // (opacity0_255:Number):Void
	static var _getOverlayVisibility:Function = _global.ASnative(5,111); // ():Number
	//
	static var _setOverlayBlendingEnabled:Function = _global.ASnative(5,112); // (enabled:Number):Void
	static var _getOverlayBlendingEnabled:Function = _global.ASnative(5,113); // ():Number
	static var OVERLAY_BLENDING_DISABLED:Number = 0;
	static var OVERLAY_BLENDING_ENABLED:Number = 1;
	//
	static var _setOverlayChromaBlendingEnabled:Function = _global.ASnative(5,114); // (enabled:Number):Void
	static var _getOverlayChromaBlendingEnabled:Function = _global.ASnative(5,115); // ():Number
	static var OVERLAY_CHROMA_BLENDING_DISABLED:Number = 0;
	static var OVERLAY_CHROMA_BLENDING_ENABLED:Number = 1;
	//
	static var _setOverlayChromaBlendColor:Function = _global.ASnative(5,116); // (rrggbb:Number):Void
	static var _getOverlayChromaBlendColor:Function = _global.ASnative(5,117); // ():Number
	//
	// display buffers
	//
	static var _setDisplay:Function = _global.ASnative(5,83); // (index:Number):Void
	static var _getDisplay:Function = _global.ASnative(5,88); // ():Number
	static var DISPLAY_MAIN:Number = 0;
	static var DISPLAY_OVERLAY:Number = 1;
	//
	// display updates (FW 1.7 or later)
	//
	static var _enableMasterUpdates:Function = _global.ASnative(5,118); // (enable:Boolean):Void
	static var _enableSlaveUpdates:Function = _global.ASnative(5,119); // (enable:Boolean):Void
	//
	// screen dimensions (FW 1.7 or later)
	//
	static var _getScreenWidth:Function = _global.ASnative(5,200); // ():Number
	static var _getScreenHeight:Function = _global.ASnative(5,201); // ():Number
	//
	// events
	//
	static var _routeUIEvents:Function = _global.ASnative(5,82); // (mask:Number):Void
	static var ROUTE_UI_EVENTS_NONE:Number = 0;
	static var ROUTE_UI_EVENTS_MASTER:Number = 1;
	static var ROUTE_UI_EVENTS_SLAVE:Number = 2;
	static var ROUTE_UI_EVENTS_BOTH:Number = 3;
	//
	// master/slave
	//
	static var _setSlaveVar:Function = _global.ASnative(5,80); // (varName:String, value:String):Void
	static var _getSlaveVar:Function = _global.ASnative(5,81); // (varName:String):String
	//
	static var _startSlave:Function = _global.ASnative(5,84); // (path:String,params:Object):Number
	static var _stopSlave:Function = _global.ASnative(5,85); // (id:Number):Void
	static var _pauseResumeSlave:Function = _global.ASnative(5,86);
	static var SLAVE_RESUME:Number = 0;
	static var SLAVE_PAUSE:Number = 1;
	static var _getDefaultSlaveInstance:Function = _global.ASnative(5,87); // () => id
	static var _getSlaveLoadStatus:Function = _global.ASnative(5,89); // ():Number
	static var SLAVE_LOAD_STATUS_INITIAL:Number = 0;
	static var SLAVE_LOAD_STATUS_DOWNLOADING:Number = 1;
	static var SLAVE_LOAD_STATUS_VALIDATING:Number = 2;
	static var SLAVE_LOAD_STATUS_SETTING_BUFFER:Number = 3;
	static var SLAVE_LOAD_STATUS_PLAYING:Number = 4;
	static var SLAVE_LOAD_STATUS_DOWNLOAD_FAILED:Number = -1;
	static var SLAVE_LOAD_STATUS_DOWNLOAD_TIMED_OUT:Number = -2;
	static var SLAVE_LOAD_STATUS_VALIDATION_FAILED:Number = -3;
	static var SLAVE_LOAD_STATUS_SET_BUFFER_FAILED:Number = -4;
	static var SLAVE_LOAD_STATUS_ACTIONSCRIPT_TIMEOUT:Number = -5;
	//
	// slave mouse events (FW 1.7 or later)
	//
	static var _slaveMouseDown:Function = _global.ASnative(5,330); // (x:Number,y:Number):Void
	static var _slaveMouseMove:Function = _global.ASnative(5,331); // (x:Number,y:Number):Void
	static var _slaveMouseUp:Function = _global.ASnative(5,332); // (x:Number,y:Number):Void
	//
	// slave privileges (FW 1.7 or later)
	//
	static var _grantTempSlavePrivileges:Function = _global.ASnative(5,360); // (x:Number):Void
	static var _revokeTempSlavePrivileges:Function = _global.ASnative(5,361); // (x:Number):Void
	static var _grantSlavePrivileges:Function = _global.ASnative(5,362); // (x:Number):Void
	static var _revokeSlavePrivileges:Function = _global.ASnative(5,363); // (x:Number):Void
	static var PRIVILEGES_VOLUME:Number = 0x0001;
	static var PRIVILEGES_AUDIO_PLAYER:Number = 0x0002;
	static var PRIVILEGES_BRIGHTNESS:Number = 0x0004;
	static var PRIVILEGES_POWER:Number = 0x0008;
	static var PRIVILEGES_GET_FILE:Number = 0x0010;
	static var PRIVILEGES_PUT_FILE:Number = 0x0020;
	static var PRIVILEGES_BACKTICK:Number = 0x0040;
	static var PRIVILEGES_FILEINFO:Number = 0x0080;
	static var PRIVILEGES_UNLINK:Number = 0x0100;
	static var PRIVILEGES_CACHE_CONTROL:Number = 0x0200;
	static var PRIVILEGES_OVERLAY_BLENDING:Number = 0x0400;
	static var PRIVILEGES_OVERLAY_CHROMA:Number = 0x0800;
	static var PRIVILEGES_MEDIA_PLAYER:Number = 0x1000;
	static var PRIVILEGES_FORCE_RESTART:Number = 0x2000;
	static var PRIVILEGES_TIME:Number = 0x4000;
	static var PRIVILEGES_PIPE:Number = 0x8000;
	static var PRIVILEGES_ALL:Number = 0xFFFF;
	//
	// restarting
	//
	static var _exitOpportunity:Function = _global.ASnative(5,120);  // ():Void
	static var _secondsBeforeRestart:Function = _global.ASnative(5,121); // ():Number
	static var _restartNow:Function = _global.ASnative(5,122); // ():Void
	//
	// cache
	//
	static var _expireCache:Function = _global.ASnative(5,100); // ()
	static var _expireCacheFiltered:Function = _global.ASnative(5,101); // (filter:String):Void
	//
	// time
	//
	static var _setTimeZone:Function = _global.ASnative(103,321); // (timezone:String):Void
	static var _getTimeZone:Function = _global.ASnative(103,320); // ():String
	//
	static var _setSystemTime:Function = _global.ASnative(103,322); // (time:Number):Void
	//
	// audio settings (requires firmware >= 1.6)
	//
	static var _getSystemVolume:Function = _global.ASnative(5,180); // ():Number
	static var _setSystemVolume:Function = _global.ASnative(5,181); // (volume:Number):Void
	static var _getSystemBalance:Function = _global.ASnative(5,182); // ():Number
	static var _setSystemBalance:Function = _global.ASnative(5,183); // (balance:Number):Void
	static var _getSystemMute:Function = _global.ASnative(5,184); // ():Number
	static var _setSystemMute:Function = _global.ASnative(5,185); // (mute:Number):Void
	static var AUDIO_VOLUME_MIN:Number = 0;
	static var AUDIO_VOLUME_MAX:Number = 100;
	static var AUDIO_BALANCE_LEFT:Number = -100;
	static var AUDIO_BALANCE_RIGHT:Number = 100;
	static var AUDIO_BALANCE_MIDDLE:Number = 0;
	static var AUDIO_MUTE_OFF:Number = 0;
	static var AUDIO_MUTE_ON:Number = 1;
	//
	// external audio player
	//
	static var _getAudioPlayerPID:Function = _global.ASnative(5,130); // ():Number
	static var _getAudioPlayerState:Function = _global.ASnative(5,131); // ():Number
	static var AUDIO_PLAYER_IDLE:Number = -1;
	static var AUDIO_PLAYER_PAUSED:Number = 0;
	static var AUDIO_PLAYER_PLAYING:Number = 1;
	static var _pauseAudioPlayer:Function = _global.ASnative(5,132);
	static var _resumeAudioPlayer:Function = _global.ASnative(5,133);
	static var _stopAudioPlayer:Function = _global.ASnative(5,134);
	static var _getAudioPlayerTrackAttributes:Function = _global.ASnative(5,135); // ():String 	
	//
	// pipe functions
	//
	static var _pipeDaemon:Function = _global.ASnative(5,190); // (command:String):Object
	static var _pipeOpen:Function = _global.ASnative(5,191); // (command:String[,mode:String]):Object
	static var _pipeSetInput:Function = _global.ASnative(5,192); // (handle:Object,listener:String):Void
	static var _pipeRead:Function = _global.ASnative(5,193); // (handle:Object):String
	static var _pipeWrite:Function = _global.ASnative(5,194); // (handle:Object,s:String):Void
	static var _pipeClose:Function = _global.ASnative(5,195); // (handle:Object):Void
	//
	// crypto functions
	//
	static var _base64Encode:Function = _global.ASnative(5,160); // (raw:String):String
	static var _base64Decode:Function = _global.ASnative(5,161); // (encoded:String):String
	static var _md5Sum:Function = _global.ASnative(5,162); // (s:String):String
	static var _blowfishEncrypt:Function = _global.ASnative(5,163); // (plain:String,key:String[,mode:String]):String
	static var _blowfishDecrypt:Function = _global.ASnative(5,164); // (crypto:String,key:String[,mode:String]):String
	//
	// image quality (FW 1.7 or later)
	//
	static var _getBitmapSmoothing:Function = _global.ASnative(5,300); // ():Number
	static var _setBitmapSmoothing:Function = _global.ASnative(5,301); // (smoothing:Number):Void
	static var BITMAP_SMOOTHING_OFF:Number = 0;
	static var BITMAP_SMOOTHING_ON:Number = 1;
	//
	// network timeouts (FW 1.7 or later)
	//
	static var _getNetworkConnectTimeout:Function = _global.ASnative(5,172); // ():Number
	static var _setNetworkConnectTimeout:Function = _global.ASnative(5,173); // (seconds:Number):Void
	static var _getNetworkTimeout:Function = _global.ASnative(5,174); // ():Number
	static var _setNetworkTimeout:Function = _global.ASnative(5,175); // (seconds:Number)
	//
	// environment variables
	//
	static var _getEnvironment:Function = _global.ASnative(5,205); // (name:String):String
	//
	// gestalt (see https://internal.chumby.com/wiki/index.php/Flash_Enhancements#Gestalt_names)
	//
	static var _getstalt:Function = _global.ASnative(5,170); // (key:String):Number
	//
	// fscommand2
	//
	static var _fscommand2:Function = _global.ASnative(5,42);  // simulate fscommand2()

	private static function _chomp(s:String):String {
		while (s.length && (s.slice(-1) == '\n' || s.slice(-1) == ' ')) {
			s = s.slice(0,-1);
		}
		return s;
	}
}