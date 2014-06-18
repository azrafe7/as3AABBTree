/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 *
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 */

package ds.aabbtree
{
	import ds.AABB;
	import flash.display.Graphics;
	import flash.utils.Dictionary;


	/**
	 * AABBTree debug renderer using OpenFL.
	 * 
	 * @author azrafe7
	 */
	public class FlashRenderer extends DebugRenderer
	{
		protected var g:Graphics;
		
		protected var colorByLevel:Function;	// int->int
		protected var leafColor:int;
		protected var leafAlpha:Number;
		protected var internalAlpha:Number;
		protected var connectToParent:Boolean;
		
		protected var colorMap:Dictionary;
		protected var HSV:Vector.<Number>;

		
		/**
		 * Creates a new debug renderer using Flash Graphics.
		 * 
		 * @param	g					The graphics to be uses to render the tree.
		 * @param	colorByLevel		A function mapping a level of the tree to the color to be used to draw the related aabbs.
		 * @param	leafColor			Color to use to draw the leaf aabbs.
		 * @param	leafAlpha			Alpha value to use when drawing leaf aabbs.
		 * @param	internalAlpha		Alpha value to use when drawing non-leaf aabbs.
		 * @param	connectToParent		Wether a line should be drawn that connects children to their parent aabbs.
		 */
		public function FlashRenderer(g:Graphics, colorByLevel:Function = null, leafColor:int = 0xFFFFFF, leafAlpha:Number = .1, internalAlpha:Number = .7, connectToParent:Boolean = true) 
		{
			super();
			this.g = g;
			this.colorByLevel = colorByLevel != null ? colorByLevel : _colorByLevel;
			this.leafColor = leafColor;
			this.leafAlpha = leafAlpha;
			this.internalAlpha = internalAlpha;
			this.connectToParent = connectToParent;
			this.colorMap = new Dictionary(true);
			this.colorMap[0] = 0xFF0000;
			this.HSV = new <Number>[.1, .9, 1];
		}
		
		override public function drawAABB(aabb:AABB, isLeaf:Boolean, level:int):void 
		{
			var color:int = isLeaf ? leafColor : colorByLevel(level);
			
			g.lineStyle(isLeaf ? 1 : 2, color, isLeaf ? leafAlpha : internalAlpha);
			if (isLeaf) g.beginFill(color, leafAlpha);
			g.drawRect(aabb.x, aabb.y, aabb.width, aabb.height);
			if (isLeaf) g.endFill();
		}
		
		override public function drawNode(node:Node, isLeaf:Boolean, level:int):void 
		{
			super.drawNode(node, isLeaf, level);
			if (connectToParent) {
				var color:int = isLeaf ? leafColor : colorByLevel(level);
				if (node.parent != null) {
					g.lineStyle(1, color, internalAlpha);
					g.moveTo(node.aabb.x, node.aabb.y);
					g.lineTo(node.parent.aabb.x, node.parent.aabb.y);
					g.drawCircle(node.parent.aabb.x, node.parent.aabb.y, 2);
				}
			}
		}
		
		private function _colorByLevel(level:int):int 
		{
			if (colorMap[level] == null) {
				HSV[0] = (HSV[0] + .12) % 1.0;
				colorMap[level] = getColorFromHSV(HSV[0], HSV[1], HSV[2]);
			}
			
			return colorMap[level];
		}
		
		private function getColorFromHSV(h:Number, s:Number, v:Number):int
		{
			h = int(h * 360);
			var hi:int = Math.floor(h / 60) % 6,
				f:Number = h / 60 - Math.floor(h / 60),
				p:Number = (v * (1 - s)),
				q:Number = (v * (1 - f * s)),
				t:Number = (v * (1 - (1 - f) * s));
			switch (hi)
			{
				case 0: return int(v * 255) << 16 | int(t * 255) << 8 | int(p * 255);
				case 1: return int(q * 255) << 16 | int(v * 255) << 8 | int(p * 255);
				case 2: return int(p * 255) << 16 | int(v * 255) << 8 | int(t * 255);
				case 3: return int(p * 255) << 16 | int(q * 255) << 8 | int(v * 255);
				case 4: return int(t * 255) << 16 | int(p * 255) << 8 | int(v * 255);
				case 5: return int(v * 255) << 16 | int(p * 255) << 8 | int(q * 255);
				default: return 0;
			}
			return 0;
		}
	}
}