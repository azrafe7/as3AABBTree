/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 *
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 */

package ds.aabbtree
{
	import ds.AABB;
	import ds.aabbtree.Node;


	/**
	 * Interface for strategies to apply when inserting a new leaf.
	 * 
	 * @author azrafe7
	 */
	public interface IInsertStrategy
	{
		/** Choose which behaviour to apply in insert context. */
		function choose(leafAABB:AABB, parent:Node, extraData:* = null):InsertChoice;
	}
}