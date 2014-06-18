/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 *
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 */

package ds
{

	/**
	 * Axis-Aligned Bounding Box.
	 * 
	 * @author azrafe7
	 */
	public class AABB
	{	
		public var minX:Number;
		public var maxX:Number;
		public var minY:Number;
		public var maxY:Number;

		public function get x():Number
		{
			return minX;
		}
		public function set x(value:Number):void
		{
			maxX += value - minX;
			minX = value;
		}
		
		public function get y():Number
		{
			return minY;
		}
		public function set y(value:Number):void
		{
			maxY += value - minY;
			minY = value;
		}
		
		public function get width():Number
		{
			return maxX - minX;
		}
		public function set width(value:Number):void
		{
			maxX = minX + value;
		}
		
		public function get height():Number
		{
			return maxY - minY;
		}
		public function set height(value:Number):void
		{
			maxY = minY + value;
		}
		
		/** 
		 * Creates an AABB from the specified parameters.
		 * 
		 * Note: `width` and `height` must be non-negative.
		 */
		public function AABB(x:Number = 0, y:Number = 0, width:Number = 0, height:Number = 0):void
		{
			minX = x;
			minY = y;
			maxX = x + width;
			maxY = y + height;
		}

		public function setTo(x:Number, y:Number, width:Number = 0, height:Number = 0):void 
		{
			minX = x;
			minY = y;
			maxX = x + width;
			maxY = y + height;
		}

		public function inflate(deltaX:Number, deltaY:Number):AABB
		{
			minX -= deltaX;
			minY -= deltaY;
			maxX += deltaX;
			maxY += deltaY;
			return this;
		}
		
		public function getPerimeter():Number
		{
			return 2 * ((maxX - minX) + (maxY - minY));
		}
		
		public function getArea():Number
		{
			return (maxX - minX) * (maxY - minY);
		}
		
		public function getCenterX():Number
		{
			return minX + .5 * (maxX - minX);
		}
		
		public function getCenterY():Number
		{
			return minY + .5 * (maxY - minY);
		}
		
		/** Resizes this instance so that it tightly encloses `aabb`. */
		public function union(aabb:AABB):AABB
		{
			minX = Math.min(minX, aabb.minX);
			minY = Math.min(minY, aabb.minY);
			maxX = Math.max(maxX, aabb.maxX);
			maxY = Math.max(maxY, aabb.maxY);
			return this;
		}
		
		/** Resizes this instance to the union of `aabb1` and `aabb2`. */
		public function asUnionOf(aabb1:AABB, aabb2:AABB):AABB
		{
			minX = Math.min(aabb1.minX, aabb2.minX);
			minY = Math.min(aabb1.minY, aabb2.minY);
			maxX = Math.max(aabb1.maxX, aabb2.maxX);
			maxY = Math.max(aabb1.maxY, aabb2.maxY);
			return this;
		}
		
		/** Returns true if this instance intersects `aabb`. */
		public function overlaps(aabb:AABB):Boolean
		{
			return !(minX > aabb.maxX || maxX < aabb.minX || minY > aabb.maxY || maxY < aabb.minY);
		}
		
		/** Returns true if this instance fully contains `aabb`. */
		public function contains(aabb:AABB):Boolean
		{
			return (aabb.minX >= minX && aabb.maxX <= maxX && aabb.minY >= minY && aabb.maxY <= maxY);
		}
		
		/** Returns a new instance that is the intersection with `aabb`, or null if there's no interesection. */
		public function getIntersection(aabb:AABB):AABB 
		{
			var intersection:AABB = this.clone();
			intersection.minX = Math.max(minX, aabb.minX);
			intersection.maxX = Math.min(maxX, aabb.maxX);
			intersection.minY = Math.max(minY, aabb.minY);
			intersection.maxY = Math.min(maxY, aabb.maxY);
			return (intersection.minX > intersection.maxX || intersection.minY > intersection.maxY) ? null : intersection;
		}
		
		public function clone():AABB
		{
			return new AABB(minX, minY, maxX - minX, maxY - minY);
		}

		/** Copies values from the specified `aabb`. */
		public function fromAABB(aabb:AABB):AABB
		{
			minX = aabb.minX;
			minY = aabb.minY;
			maxX = aabb.maxX;
			maxY = aabb.maxY;
			return this;
		}
		
		public function toString():String 
		{
			return '[x:${minX} y:${minY} w:${width} h:${height}]';
		}
	}
}