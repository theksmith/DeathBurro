class ScrollPane_thumb extends fl.controls.UIScrollBar
{
import fl.controls.ScrollBar;
import fl.controls.UIScrollBar;

public function ScrollPane_thumb()

override protected function updateThumb():void {
var per:Number = maxScrollPosition - minScrollPosition + pageSize;
if (track.height <= 12 || maxScrollPosition <= minScrollPosition || (per == 0 || isNaN(per))) {

thumb.height = 12;
thumb.visible = false;
} else {
thumb.height = 12;
//thumb.height = Math.max(13,pageSize / per * track.height);
thumb.y = track.y+(track.height-thumb.height)*((scrollPosition-minScrollPosition)/(maxScrollPosition-minScrollPosition));
thumb.visible = enabled;
}
}
}
