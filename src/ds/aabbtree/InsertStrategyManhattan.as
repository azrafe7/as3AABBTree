/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 *
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 */

package ds.aabbtree
{
	import ds.AABB;
	import ds.aabbtree.InsertChoice;


	/**
	 * Choose best node based on manhattan distance of centroid.
	 * 
	 * @author azrafe7
	 */
	class InsertStrategyManhattan implements IInsertStrategy
	{
		protected var combinedAABB:AABB = new AABB();
		
		public function choose(leafAABB:AABB, parent:Node, extraData:* = null):InsertChoice
		{
			var left:Node = parent.left;
			var right:Node = parent.right;

			// cost of creating a new parent for this node and the new leaf
			combinedAABB.asUnionOf(parent.aabb, leafAABB);
			var costParent:Number = Math.abs((combinedAABB.getCenterX() - parent.aabb.getCenterX()) + (combinedAABB.getCenterY() - parent.aabb.getCenterY()));
			
			// cost of descending into left node
			combinedAABB.asUnionOf(leafAABB, left.aabb);
			var costLeft:Number = Math.abs((combinedAABB.getCenterX() - left.aabb.getCenterX()) + (combinedAABB.getCenterY() - left.aabb.getCenterY()));
			
			// cost of descending into right node
			combinedAABB.asUnionOf(leafAABB, right.aabb);
			var costRight:Number = Math.abs((combinedAABB.getCenterX() - right.aabb.getCenterX()) + (combinedAABB.getCenterY() - right.aabb.getCenterY()));

			
			// break/descend according to the minimum cost
			if (costParent < costLeft && costParent > costRight) {
				return InsertChoice.PARENT;
			}

			// descend
			return costLeft < costRight ? InsertChoice.DESCEND_LEFT : InsertChoice.DESCEND_RIGHT;
		}
	}
}