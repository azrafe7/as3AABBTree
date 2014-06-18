/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 * 
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 * 
 * The code is heavily inspired by the implementations of a dynamic AABB tree by 
 * 
 *  - Nathanael Presson 	(Bullet Physics - http://bulletphysics.org)
 *	- Erin Catto 			(Box2D - http://www.box2d.org)
 */

package ds.aabbtree
{
	import ds.AABB;

	/**
	 * Node pool used by AABBTree.
	 * 
	 * @author azrafe7
	 */
	public class NodePool
	{
		/** The pool will grow by this factor when it's empty. */
		public var growthFactor:Number;
		
		/** Initial capacity of the pool. */
		public var capacity:int;
		
		protected var freeNodes:Vector.<Node>;
		
		
		public function NodePool(capacity:int, growthFactor:Number = 2)
		{
			this.capacity = capacity;
			this.growthFactor = growthFactor;
			freeNodes = new Vector.<Node>();
			for (var i:int = 0; i < capacity; i++) freeNodes.push(new Node(new AABB(), null));
		}
		
		/** Fetches a node from the pool (if available) or creates a new one. */
		public function get(x:Number, y:Number, width:Number = 0, height:Number = 0, data:* = null, parent:Node = null, id:int = -1):Node
		{
			var newNode:Node;
			
			if (freeNodes.length > 0) {
				newNode = freeNodes.pop();
				newNode.aabb.setTo(x, y, width, height);
				newNode.data = data;
				newNode.parent = parent;
				newNode.id = id;
			} else {
				newNode = new Node(new AABB(x, y, width, height), data, parent, id);
				capacity = int(capacity * growthFactor);
				grow(capacity);
			}
			
			return newNode;
		}
		
		/** Reinserts an unused node into the pool (for future use). */
		public function put(node:Node):void 
		{
			freeNodes.push(node);
			node.parent = node.left = node.right = null;
			node.id = -1;
			node.invHeight = -1;
			node.data = null;
		}
		
		/** Resets the pool to its capacity (removing all the other nodes). */
		public function reset():void 
		{
			if (freeNodes.length > capacity) freeNodes.splice(capacity, freeNodes.length - capacity);
		}
		
		/** Grows the pool to contain `n` nodes. Nothing will be done if `n` is less than the current number of nodes. */
		public function grow(n:int):void
		{
			var len:int = freeNodes.length;
			if (n <= len) return;
			
			for (var i:int = len; i < n; i++) {
				freeNodes.push(new Node(new AABB(), null));
			}
		}
	}
}