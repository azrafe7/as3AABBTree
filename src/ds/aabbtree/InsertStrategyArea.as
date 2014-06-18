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
	 * Choose best node based on area.
	 * 
	 * @author azrafe7
	 */
	public class InsertStrategyArea implements IInsertStrategy
	{
		protected var combinedAABB:AABB = new AABB();
		
		public function choose(leafAABB:AABB, parent:Node, extraData:* = null):InsertChoice
		{
			var left:Node = parent.left;
			var right:Node = parent.right;
			var area:Number = parent.aabb.getArea();

			combinedAABB.asUnionOf(parent.aabb, leafAABB);
			var combinedArea:Number = combinedAABB.getArea();

			// cost of creating a new parent for this node and the new leaf
			var costParent:Number = 2 * combinedArea;

			// minimum cost of pushing the leaf further down the tree
			var costDescend:Number = 2 * (combinedArea - area);

			// cost of descending into left node
			combinedAABB.asUnionOf(leafAABB, left.aabb);
			var costLeft:Number = combinedAABB.getArea() + costDescend;
			if (!left.isLeaf()) {
				costLeft -= left.aabb.getArea();
			}

			// cost of descending into right node
			combinedAABB.asUnionOf(leafAABB, right.aabb);
			var costRight:Number = combinedAABB.getArea() + costDescend;
			if (!right.isLeaf()) {
				costRight -= right.aabb.getArea();
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