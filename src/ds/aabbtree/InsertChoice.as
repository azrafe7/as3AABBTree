/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 *
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 */

package ds.aabbtree 
{
	/**
	 * ...
	 * @author azrafe7
	 */
	public class InsertChoice
	{
		static public const PARENT:InsertChoice = new InsertChoice();			// choose parent as sibling node
		static public const DESCEND_LEFT:InsertChoice = new InsertChoice();		// descend left branch of the tree
		static public const DESCEND_RIGHT:InsertChoice = new InsertChoice();	// descent right branch of the tree
		
		{ EnumTools.initEnumConstants(InsertChoice); }
		
		internal var value:String;
		
		public function toString():String
		{
			return value;
		}
	}
}