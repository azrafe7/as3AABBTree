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
	 * ...
	 * @author azrafe7
	 */
	public interface IDebugRenderer
	{
		function drawAABB(aabb:AABB, isLeaf:Boolean, level:int):void;
		
		function drawNode(node:Node, isLeaf:Boolean, level:int):void;
		
		function drawTree(tree:AABBTree, root:Node):void;
	}
}