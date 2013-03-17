/*
AS2Helper.as (for Adobe Flash Actionscript 2.0)

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

class AS2Helper 
{
	//as2 lacks basic string trim (and have to make function, can't prototype inside class directly)
	public static function strTrim(str:String):String {
    	for(var i = 0; str.charCodeAt(i) < 33; i++);
    		for(var j = str.length-1; str.charCodeAt(j) < 33; j--);
    			return str.substring(i, j+1);
	}

	//as2 lacks basic string replace as well!
	public static function strReplace(searchIn:String, searchFor:String, replaceWith:String):String {
		var arr:Array = searchIn.split(searchFor);
		return arr.join(replaceWith);
	}
	
	public static function dateDiff(date1:Date, date2:Date):Array {
		var ms:Number = Math.floor(date1.getTime() - date2.getTime());
		var secs:Number = Math.floor(ms/1000);
		var mins:Number = Math.floor(ms/1000/60);
		var hrs:Number = Math.floor(ms/1000/60/60);
		var days:Number = Math.floor(ms/1000/60/60/24);

		if (secs > 0) ms = ms - (secs * 1000);
		if (mins > 0) secs = secs - (mins * 60);
		if (hrs > 0) mins = mins - (hrs * 60 * 60);
		if (days > 0) hrs = hrs - (days * 60 * 60 * 24);
		
		return new Array(Math.round(days), Math.round(hrs), mins, secs, ms);
	}
	
	//determine if root movie can access local files
	public static function rootCanLocal():Boolean {	
		return _root.loaderInfo.url.indexOf("file:") != -1 ? true : false;
		
		return (System.security.sandboxType == 'localTrusted' || System.security.sandboxType == 'localWithFile') ? true : false;
	}

	//determine if root movie can access network
	public static function rootCanNetwork():Boolean {	
		return (System.security.sandboxType == 'localTrusted' || System.security.sandboxType == 'localWithNetwork') ? true : false;
	}
	
	//get directory that root movie was launched from
	public static function getRoot():String {
		var i:Number = 0;
		var dir:String = _root._url;
		
		if (dir == undefined || dir == null)  {
			dir = '';
		} else {
			i = dir.lastIndexOf('/');
			if (i > 0) dir = strTrim(dir.substring(0, i+1));
		}

		return dir;
	}

	//clone an object or array (normally in AS2, setting obj1 = obj2 does a reference)
	public static function clone(objOrArray) {
		if (typeof(objOrArray) == 'object') {
			var copy = (objOrArray instanceof Array) ? [] : {};
			
			for (var i in objOrArray) {
				copy[i] = (typeof(objOrArray[i]) == 'object') ? clone(objOrArray[i]) : objOrArray[i];
			}
			
			return copy;
		} else {
			trace('Warning! AS2Helper.clone() can not be used on MovieClip or XML objects');
			return undefined;
		}
	}
}