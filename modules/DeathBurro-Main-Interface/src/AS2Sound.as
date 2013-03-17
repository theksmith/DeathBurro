/*
AS2Sound.as (for Adobe Flash Actionscript 2.0)

Authored by Kristoffer Smith
Copyright (c) Kristoffer Smith 2011
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

class AS2Sound
{
	private var _RESOLUTION:Number = 50;
	
	private var _fadeOutTimerID:Number;
	private var _fadeOutSound:Sound;
	private var _fadeOutTo:Number;
	private var _fadeOutDuration:Number;
	private var _fadeOutStep:Number;
	private var _fadeOutCurrent:Number;
	
	//plays the passed "objSound", fading out the ending "duration"
	//only param "objSound" (default is from 100 to 0 over entire length)
	//usage example:
	//	//create sound with attached resource
	//	var mysound:Sound = new Sound()
	//	mysound.attachSound('mysound.wav');
	//	//play the sound fading out the last 1 second
	//	var fade:AS2Sound = new AS2Sound();
	//	fade.fadeOut(mysound, 1000);
	public function fadeOut(objSound:Sound, duration:Number, volFrom:Number, volTo:Number, startPosition:Number) {
		if (_fadeOutTimerID != undefined) throw new Error('AS2Sound.fadeOut() Error! Method in use!');		
		if (objSound == undefined || objSound == null) throw new Error('AS2Sound.fadeOut() Error! Must pass a sound object as first param.');
		
		//if no from-volume from provided, start wherever sound is set (unless 0 already, then start at 100)
		if (volFrom == undefined || volFrom == null || volFrom <= 0) volFrom = objSound.getVolume();
		if (volFrom <= 0) volFrom = 100;
		
		//if no to-volume provided, default to 0
		if (volTo == undefined || volTo == null || volTo < 0 || volTo >= volFrom) volTo = 0;
		
		//if no duration provided, use entire length of sound
		if (duration == undefined || duration == null || duration <= 0 || duration > objSound.duration) duration = objSound.duration;
		if (duration < _RESOLUTION) duration = _RESOLUTION;
		
		//if no start position provided, start wherever sound is set (unless is at the end already, then start over)
		if (startPosition == undefined || startPosition == null || startPosition < 0) startPosition = objSound.position;
		if (startPosition >= objSound.duration) startPosition = 0;

		var volDiff = volFrom - volTo;
		_fadeOutStep = Math.round(volDiff / (duration / _RESOLUTION));
		_fadeOutDuration = duration;
		_fadeOutCurrent = volFrom;
		_fadeOutTo = volTo;
		
		_fadeOutSound = objSound;
		_fadeOutSound.setVolume(_fadeOutCurrent);
		_fadeOutSound.start(startPosition/1000);
		_fadeOutTimerID = setInterval(_fadeOutTimer, _RESOLUTION, this);
	}
	
	private function _fadeOutTimer(objCaller:AS2Sound):Void {
		this = objCaller;
		if (_fadeOutCurrent > _fadeOutTo) {
			if (_fadeOutSound.position > (_fadeOutSound.duration - _fadeOutDuration)) {
				_fadeOutCurrent = _fadeOutCurrent - _fadeOutStep;			
				if (_fadeOutCurrent < 0) _fadeOutCurrent = 0;
				_fadeOutSound.setVolume(_fadeOutCurrent);
			}
		} else {
			clearInterval(_fadeOutTimerID);
			this._fadeOutTimerID = undefined;
		}	
	}
}