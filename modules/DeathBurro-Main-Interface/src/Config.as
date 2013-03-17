/*
Config.as (for Adobe Flash Actionscript 2.0)

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

import mx.utils.Delegate;

import AS2Helper;
import AS2Event;
import Chumby;

class Config
{	
	private var _path:String;
	private var _xdoc:XML;
	private var _isSaving:Boolean;	
		
	public var onLoaded:AS2Event;
	public var settings:Object;
	
	//pass in the config xml file_path
	public function Config(filepath:String) {
		onLoaded = new AS2Event();		
		if (filepath.indexOf('file://') == -1) _path = 'file://' + filepath;
		else _path = filepath;
		//trace('Config.Config() _path =' + _path);
	}

	//parse the config xml into associate "settings" array 
	//<setting category="about" name="version" val="1" />  becomes:  val = this.settings['about']['version']
	private function _parse(ok:Boolean):Void {
		try {
			if (!ok) throw new Error('Config._parse() Unknown error (ok != true).');
			
			var xnodes = _xdoc.firstChild.childNodes;
			settings = new Object();
			for (var i = 0; i < xnodes.length; i++) {
				if (settings[xnodes[i].attributes.category] == undefined) settings[xnodes[i].attributes.category] = new Object();
				settings[xnodes[i].attributes.category][xnodes[i].attributes.name] = xnodes[i].attributes.val;
			}

			//if we made it this far, indicate no error with null for second callback param
			onLoaded.notify(this, null);
		} catch (e:Error) {
			onLoaded.notify(this, e);
		}
	}
	
	function toListString(showSecureItems:Boolean):String {
		var heading:String;
		var total:Number = 0;
		var list:String = '';
		
		for (var cat:String in settings) {
			for (var item:String in settings[cat]) {				
				if (typeof(settings[cat][item]) != typeof(Function)) {
					total++;
					heading = cat + ': ' + item;
					if (!showSecureItems && (heading.indexOf('user') >= 0 || heading.indexOf('uid') >= 0 || heading.indexOf('pass') >= 0 || heading.indexOf('pwd') >= 0)) {
						list += '\n\n' + heading + ' = (hidden)';
					} else {
						list += '\n\n' + heading + ' = ' + settings[cat][item];
					}
				}
			}
		}
		
		return total + ' config items' + list;
	}
	
	function save():Boolean {
		if (!_isSaving) {
			_isSaving = true;
			
			//todo: save config object back to xml
			
			_isSaving = false;
			return true;
		}
		return false;
	}
	
	//custom xml loader that works with standard XML.load() or ChumbyNative.getFile() based on environment
	public function load():Void {
		try {
			if (!_isSaving) {
				_xdoc = new XML();
				_xdoc.ignoreWhite = true;
				_xdoc.onLoad = Delegate.create(this, _parse); //using delegate instead of standard event handler assign so that "this" stays the class instance in the handler
				_xdoc.load(_path);
			}
		} catch (e:Error) {
			onLoaded.notify(this, e);
		}
	}
}