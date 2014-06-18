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
	 * Choose best node based on perimeter.
	 * 
	 * @author azrafe7
	 */
	public class InsertStrategyPerimeter implements IInsertStrategy
	{
		protected var combinedAABB:AABB = new AABB();
		
		public function choose(leafAABB:AABB, parent:Node, extraData:* = null):InsertChoice
		{
			var left:Node = parent.left;
			var right:Node = parent.right;
			var perimeter:Number = parent.aabb.getPerimeter();

			combinedAABB.asUnionOf(parent.aabb, leafAABB);
			var combinedPerimeter:Number = combinedAABB.getPerimeter();

			// cost of creating a new parent for this node and the new leaf
			var costParent:Number = 2 * combinedPerimeter;

			// minimum cost of pushing the leaf further down the tree
			var costDescend:Number = 2 * (combinedPerimeter - perimeter);

			// cost of descending into left node
			combinedAABB.asUnionOf(leafAABB, left.aabb);
			var costLeft:Number = combinedAABB.getPerimeter() + costDescend;
			if (!left.isLeaf()) {
				costLeft -= left.aabb.getPerimeter();
			}

			// cost of descending into right node
			combinedAABB.asUnionOf(leafAABB, right.aabb);
			var costRight:Number = combinedAABB.getPerimeter() + costDescend;
			if (!right.isLeaf()) {
				costRight -= right.aabb.getPerimeter();
			}

			// break/descend according to the minimum cost
			if (costParent < costLeft && costParent < costRight) {
				return InsertChoice.PARENT;
			}

			// descend
			return costLeft < costRight ? InsertChoice.DESCEND_LEFT : InsertChoice.DESCEND_RIGHT;
		}
	}
}