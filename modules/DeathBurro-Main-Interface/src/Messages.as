/*
Messages.as (for Adobe Flash Actionscript 2.0)

Authored by Kristoffer Smith
Copyright (c) Kristoffer Smith 2011
http://theksmith.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the 'Software'), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import mx.utils.Delegate;
import mx.xpath.XPathAPI;

import AS2Helper;
import AS2Event;
import Chumby;

class Messages
{	
	private var _msgs:Array;	
	private var _scriptXML:XML;
		
	public var onLoaded:AS2Event;
	public var lastCheckDate:Date;
	public var lastNewDate:Date;
	public var scriptCommand:String;
	public var maxCount:Number;
	public var alertSubjectList:String;
	public var alertFromList:String;	
	
	public function Messages() {
		onLoaded = new AS2Event();
		_msgs = new Array();
	}

	private function _parse(ok:Boolean):Void {
		//currently, no attempt to sort msgs is made here, therefore:
		//	- script should return msgs in chrono order with oldest first
		//	- each run of script should return newer msgs than the previous run
		
		//currently, no checking for dupes is made here, therefore script should only get unread msgs and mark msgs read as it downloads them 

		trace('Messages._parse() _scriptXML = ' + _scriptXML);
		
		var errMsg:String = '';
		var foundComplete:Boolean = false;
		var _msgsNew = new Array();		
		var msg:Object;
		
		try {
			if (!ok) throw new Error('Messages._parse() Unknown error (ok != true). xml start: ' + _scriptXML.toString().substring(0, 100));
			
			var xoutput:XMLNode = _scriptXML.firstChild;
		
			if (xoutput.nodeName != 'MailScriptOutput') throw new Error('Messages._parse() Unexpected root node name: ' +  xoutput.nodeName + '. xml starts: ' + _scriptXML.toString().substring(0, 100));
			if (!xoutput.hasChildNodes) throw new Error('Messages._parse() Emtpy root node! xml starts: ' + _scriptXML.toString().substring(0, 100));
			
			var xoutputchilds:Array = xoutput.childNodes;
			for (var i = 0; i < xoutputchilds.length; i++) {
				//trace('-'+xoutputchilds[i].nodeName);				
				if (xoutputchilds[i].nodeName == 'ScriptError') {
					errMsg += 'Script error found: ' + xoutputchilds[i].firstChild.nodeValue + '\n';
				} else if (xoutputchilds[i].nodeName == 'ScriptStatus') {
					if (xoutputchilds[i].firstChild.nodeValue.indexOf('COMPLETE!') != -1) foundComplete = true;
				} else if (xoutputchilds[i].hasChildNodes) {
					var xmailitems:Array = xoutputchilds[i].childNodes;					
					for (var j = 0; j < xmailitems.length; j++) {
						xmailitems[j] = xmailitems[j].firstChild;
						//trace('--'+xmailitems[j].nodeName);						
						if (xmailitems[j].nodeName == 'ScriptError') {
							errMsg += 'Script error found: ' + xmailitems[j].firstChild.nodeValue + '\n';
						} else if (xmailitems[j].nodeName == 'ScriptMailItem') {
							//create msg
							msg = {isnew:true, read:false, type:'msg', datetime:'', from:'', subject:'', body:''};

							msg.body = XPathAPI.selectSingleNode(xmailitems[j], '/ScriptMailItem/MailItemBody/*').nodeValue;
							msg.body = AS2Helper.strReplace(msg.body, '\r\n', '\n');
							
							msg.datetime = XPathAPI.selectSingleNode(xmailitems[j], '/ScriptMailItem/MailItemDate/*').nodeValue;
							
							//shorten "datetime" if possible to save UI space
							var now:Date = new Date();
							msg.datetime = AS2Helper.strReplace(msg.datetime, now.getFullYear().toString(), '');
							msg.datetime = AS2Helper.strReplace(msg.datetime, ',', '');
							msg.datetime = AS2Helper.strReplace(msg.datetime, 'day', '');
							
							msg.from = XPathAPI.selectSingleNode(xmailitems[j], '/ScriptMailItem/MailItemSender/*').nodeValue;
														
							//shorten "from" if possible to save UI space (if in common format: My Name <name@name.com>)
							if (msg.from.indexOf('<') != -1) msg.from = msg.from.substring(msg.from.indexOf('<') + 1); 
							if (msg.from.lastIndexOf('>') != -1) msg.from = msg.from.substring(0, msg.from.lastIndexOf('>'));
							
							msg.subject = XPathAPI.selectSingleNode(xmailitems[j], '/ScriptMailItem/MailItemSubject/*').nodeValue;
							msg.subject = AS2Helper.strReplace(msg.subject, '\r\n', '\n');

							//check if an incomplete donkeymsg1-0 spec msg and cleanup
							//donkeymsg1-0
							if (AS2Helper.strTrim(msg.subject) == 'donkeymsg1-0') msg.subject = '';
							
							//check if an valid donkeymsg1-0 spec msg and parse:
							//donkeymsg1-0|subject
							//donkeymsg1-0|type|subject
							if (msg.subject.indexOf('|') != -1) {
								var specparts:Array = msg.subject.split('|');								
								if (AS2Helper.strTrim(specparts[0]) == 'donkeymsg1-0') {									
									if (specparts[1] == 'msg' || specparts[1] == 'alert' || specparts[1] == 'cmd') {
										msg.type = specparts[1];
										msg.subject = specparts[2];
									} else {
										msg.subject = specparts[1];
									}
								}
							}
							
							//check if is considered alert based on config settings (beyond the spec way of creating an alert)
							if (alertSubjectList != undefined && alertSubjectList != null && alertSubjectList.length > 0) {
								var subjs:Array = alertSubjectList.split('|');
								for (var s = 0; s < subjs.length; s++) {
									if (msg.subject.indexOf(AS2Helper.strTrim(subjs[s])) != -1) msg.type = 'alert';
								}
							}
							if (alertFromList != undefined && alertFromList != null && alertFromList.length > 0) {
								var froms:Array = alertFromList.split('|');
								for (var f = 0; f < froms.length; f++) {
									if (msg.from.indexOf(AS2Helper.strTrim(froms[f])) != -1) msg.type = 'alert';
								}
							}

							//add msg to tmp new msgs list
							_msgsNew.push(AS2Helper.clone(msg));
						} else {
							errMsg += 'Unexpected node: ' + xmailitems[j] + ' found inside: ' + xoutputchilds[i].nodeName + '.\n';
						}					
					}
				} else {
					errMsg += 'Unexpected node: ' + xoutputchilds[i] + ' found inside: ' + xoutput.nodeName + '.\n';
				}
			}
			
			if (!foundComplete) errMsg += '\nNo {{COMPLETE!}} node found.';
			
			//got some msgs, keep track of when event occured
			if (_msgsNew.length > 0) lastNewDate = new Date();
			
			//copy new msgs to top of primary msgs list
			for (var i = 0; i < _msgsNew.length; i++) {
				_msgs.unshift(_msgsNew[i]);
			}
			
			//keep only the most recent X number of msgs (if specified)
			if (maxCount > 0 && _msgs.length > maxCount) _msgs = _msgs.slice(0, maxCount - 1);
			
			//some errors, but we finished parsing			
			if (errMsg != '') throw new Error('Messages._parse() Some errors occured while parsing: ' + errMsg);
			
			//if made it this far, no errors at all
			onLoaded.notify(this, null);
		} catch (e:Error) {
			onLoaded.notify(this, e);
		} finally {
			msg = null;
			_scriptXML = null;
			_msgsNew = null;
		}
	}

	public function load(protocol:String, server:String, port:Number, user:String, pwd:String, ssl:Boolean, folders:String, subjects:String, froms:String, bodylen:Number, subjlen:Number, maxdownload:Number):Void {
		try {
			//checking for msgs, keep track of when event occured
			lastCheckDate = new Date();
			
			if (scriptCommand == undefined || scriptCommand == null || AS2Helper.strTrim(scriptCommand).length <= 0) throw new Error('Messages.load() Error! scriptCommand is required.');

			var cmdStr:String = 'exec://' + AS2Helper.strTrim(scriptCommand);

			if (protocol.length > 0) cmdStr += ' -protocol:' + protocol;
			if (server.length > 0) cmdStr += ' -server:' + server;
			if (port > 0) cmdStr += ' -port:' + port;
			if (user.length > 0) cmdStr += ' -user:' + user;
			if (pwd.length > 0) cmdStr += ' -pwd:' + pwd;
			if (ssl) cmdStr += ' -ssl:1';
			if (folders.length > 0) cmdStr += ' -folders:' + folders;
			if (subjects.length > 0) cmdStr += ' -subjects:' + subjects;
			if (froms.length > 0) cmdStr += ' -froms:' + froms;
			if (bodylen > 0) cmdStr += ' -bodylen:' + bodylen;
			if (subjlen > 0) cmdStr += ' -subjlen:' + subjlen;
			if (maxdownload > 0) cmdStr += ' -max:' + maxdownload;

			trace('Messages.load() cmdStr = ' + cmdStr);

			_scriptXML = new XML();
			_scriptXML.ignoreWhite = true;
			_scriptXML.onLoad = Delegate.create(this, _parse); //using delegate instead of standard event handler assign so that 'this' stays the class instance in the handler			
			_scriptXML.load(cmdStr);
			//_scriptXML.load('testmaildata.xml');			
		} catch (e:Error) {
			onLoaded.notify(this, e);
		}
	}

	//get a single msg object by index
	public function getMsg(index:Number):Array {
		return  AS2Helper.clone(_msgs[index]);
	}

	//mark a single msg read (by index)
	public function markRead(index:Number):Void {
		_msgs[index].read = true;
	}	
	
	//check entire msgs stack for at least one unread
	public function hasUnread():Boolean {
		for (var i = 0; i < _msgs.length; i++) {
			if (!_msgs[i].read) return true;
		}
		return false;
	}

	//check entire msgs stack for at least one with type = alert
	public function hasUnreadAlerts():Boolean {
		for (var i = 0; i < _msgs.length; i++) {
			if (!_msgs[i].read && _msgs[i].type == 'alert') return true;
		}
		return false;
	}

	//check entire msgs stack for at least one with type = cmd
	public function hasUnreadCmds():Boolean {
		for (var i = 0; i < _msgs.length; i++) {
			if (!_msgs[i].read && _msgs[i].type == 'cmd') return true;
		}
		return false;
	}

	//total msg count
	public function count():Number {
		return _msgs.length;
	}

	//total unread count
	public function countUnread():Number {
		var cnt:Number = 0;
		
		for (var i = 0; i < _msgs.length; i++) {
			if (!_msgs[i].read) cnt++;
		}
		
		return cnt;
	}

	//check entire msgs stack for at least one NEW msg
	public function hasNew():Boolean {
		for (var i = 0; i < _msgs.length; i++) {
			if (_msgs[i].isnew) return true;
		}
		return false;
	}
	
	//check entire msgs stack for at least one NEW unread
	public function hasNewUnread():Boolean {
		for (var i = 0; i < _msgs.length; i++) {
			if (_msgs[i].isnew && !_msgs[i].read) return true;
		}
		return false;
	}

	//check entire msgs stack for at least one NEW with type = alert
	public function hasNewUnreadAlerts():Boolean {
		for (var i = 0; i < _msgs.length; i++) {
			if (_msgs[i].isnew && !_msgs[i].read && _msgs[i].type == 'alert') return true;
		}
		return false;
	}

	//check entire msgs stack for at least one NEW with type = cmd
	public function hasNewUnreadCmds():Boolean {
		for (var i = 0; i < _msgs.length; i++) {
			if (_msgs[i].isnew && !_msgs[i].read && _msgs[i].type == 'cmd') return true;
		}
		return false;
	}
	
	//count entire NEW msgs
	public function countNew():Number {
		var cnt:Number = 0;
		
		for (var i = 0; i < _msgs.length; i++) {
			if (_msgs[i].isnew) cnt++;
		}
		
		return cnt;
	}

	//count entire NEW unread msgs
	public function countNewUnread():Number {
		var cnt:Number = 0;
		
		for (var i = 0; i < _msgs.length; i++) {
			if (_msgs[i].isnew && !_msgs[i].read) cnt++;
		}
		
		return cnt;
	}
	
	//mark everything not-NEW
	public function markAllOld():Void {
		for (var i = 0; i < _msgs.length; i++) {
			_msgs[i].isnew = false;
		}
	}

	//mark everything .read = true
	public function markAllRead():Void {
		for (var i = 0; i < _msgs.length; i++) {
			_msgs[i].read = true;
		}
	}

	//clear the entire msg store!
	public function empty():Void {
		_msgs = new Array();
	}
}