/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 *
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 */

package ds.aabbtree
{
	import ds.AABB;
	import ds.AABBTree;


	/**
	 * Extend this class and override its methods to implement a custom AABBTree renderer.
	 * 
	 * @author azrafe7
	 */
	public class DebugRenderer implements IDebugRenderer
	{

		public function DebugRenderer() 
		{
			
		}
		
		/** Draw the `aabb`. `isLeaf` will be true if the `aabb` belongs to a leaf node. `level` will be zero if `node` is the root (> 0 otherwise).*/
		public function drawAABB(aabb:AABB, isLeaf:Boolean, level:int):void
		{
			
		}
		
		/** Draw a `node`. `isLeaf` will be true if `node` is a leaf node. `level` will be zero if `node` is the root (> 0 otherwise). */
		public function drawNode(node:Node, isLeaf:Boolean, level:int):void
		{
			drawAABB(node.aabb, node.isLeaf(), level);
		}
		
		/** Draw the whole `tree` (level-wise, starting from `root`). */
		public function drawTree(tree:AABBTree, root:Node):void
		{
			if (root == null) return;
			
			var height:int = tree.height;
			var stack:Vector.<Node> = new <Node>[root];
			while (stack.length > 0) {
				var node:Node = stack.pop();
				if (!node.isLeaf()) {
					stack.push(node.left);
					stack.push(node.right);
				}
				drawNode(node, node.isLeaf(), height - node.invHeight);
			}
		}
	}
}