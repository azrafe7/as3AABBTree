package 
{
	import ds.aabbtree.FlashRenderer;
	import ds.aabbtree.Node;
	import flash.display.Graphics;


	/**
	 * Custom debug renderer for AABBTree.
	 * 
	 * @author azrafe7
	 */
	public class CustomRenderer extends FlashRenderer
	{

		// draw tree up to this level.
		public var maxLevel:int = 1000000;
		
		// draw only leaf nodes.
		public var leafOnly:Boolean = true;

		
		public function CustomRenderer(g:Graphics)
		{
			super(g);
		}
		
		override public function drawNode(node:Node, isLeaf:Boolean, level:int):void 
		{
			if (leafOnly && isLeaf) {
				var tmp:Boolean = connectToParent;
				connectToParent = false;
				super.drawNode(node, isLeaf, level);
				connectToParent = tmp;
			} else if (!leafOnly && level <= maxLevel) {
				super.drawNode(node, isLeaf, level);
			}
		}
	}
}