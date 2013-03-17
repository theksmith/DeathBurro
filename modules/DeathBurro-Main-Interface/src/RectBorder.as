/*
for custom skin to override default RectBorder
does nothing (i.e. prevents borders)
*/

import mx.core.ext.UIObjectExtensions;

class RectBorder extends mx.skins.RectBorder
{
    static var symbolName:String = "RectBorder";
    static var symbolOwner:Object = RectBorder;
    var className:String = "RectBorder";
    var offset:Number = 0;
    
    function init(Void):Void {
        super.init();
    }

    function drawBorder(Void):Void {
    }

    // Register the class as the RectBorder for all components to use.
    static function classConstruct():Boolean {
        UIObjectExtensions.Extensions();
        _global.styles.rectBorderClass = RectBorder;
        _global.skinRegistry["RectBorder"] = true;
        return true;
    }
	
    static var classConstructed:Boolean = classConstruct();
    static var UIObjectExtensionsDependency = UIObjectExtensions;
}