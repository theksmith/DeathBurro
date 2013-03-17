/*
 * See http://flashgamecode.net/free/event-class for info and examples
 * 
 * Author: Richard Lord
 * Copyright (c) Big Room ventures Ltd. 2007
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

class AS2Event 
{
	private var _listeners:Array;
	
	public function AS2Event()
	{
		_listeners = new Array();
	}
	
	public function addListener( listener:Object, method:Function ):Void
	{
		removeListener( listener, method );
		_listeners.unshift( { listener:listener, method:method } );
	}
	
	public function removeListener( listener:Object, method:Function ):Void
	{
		for( var i:Number = _listeners.length; i--; )
		{
			var l:Object = _listeners[i];
			if( l.listener == listener && l.method == method )
			{
				_listeners.splice( i, 1 );
				return;
			}
		}
	}
	
	public function notify():Void
	{
		var args:Array = arguments;
		for( var i:Number = _listeners.length; i--; )
		{
			var l:Object = _listeners[i];
			l.method.apply( l.listener, args );
		}
	}
	
	public function hasListeners():Boolean
	{
		return _listeners.length > 0;
	}
}