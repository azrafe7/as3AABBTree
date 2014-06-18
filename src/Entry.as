package  
{
	import ds.AABB;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author azrafe7
	 */
	public class Entry
	{
		public var id:int;
		public var dir:Point;
		public var aabb:AABB;
		
		public function Entry(dir:Point, aabb:AABB):void 
		{
			this.dir = dir;
			this.aabb = aabb;
			this.id = -1;
		}
	}
}