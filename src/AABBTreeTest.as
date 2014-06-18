package
{
	import ds.AABB;
	import ds.AABBTree;
	import ds.aabbtree.HitBehaviour;
	import ds.aabbtree.InsertStrategyArea;
	import ds.aabbtree.DebugRenderer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.utils.getTimer;


	public class AABBTreeTest extends Sprite {

		// key codes
		public static var LEFT:int = 37;
		public static var UP:int = 38;
		public static var RIGHT:int = 39;
		public static var DOWN:int = 40;

		public var TEXT_COLOR:int = 0xFFFFFFFF;
		public var TEXT_FONT:String = "_typewriter";
		public var TEXT_SIZE:Number = 12;
		public var TEXT_OUTLINE:GlowFilter = new GlowFilter(0xFF000000, 1, 2, 2, 6);

		public var QUERY_COLOR:int = 0xFFCC00;
		public var RESULTS_COLOR:int = 0xFF0000;
		public var RESULTS_ALPHA:Number = .5;
		public var SPEED:Number = 6;
		
		public var stageWidth:int;
		public var stageHeight:int;
		
		public var text:TextField;
		public var g:Graphics;
		public var tree:AABBTree;
		public var renderer:CustomRenderer;
		public var results:Vector.<*> = new Vector.<*>();
		public var lastQueryInfo:* = null;
		
		public var startPoint:Point = new Point();
		public var endPoint:Point = new Point();
		public var queryRect:AABB = new AABB();
		public var strictMode:Boolean = true;
		public var rayMode:Boolean = false;
		public var filterMode:Boolean = false;
		public var animMode:Boolean = false;
		public var dragging:Boolean = false;

		public var redraw:Boolean = true;
		public var overlay:Graphics;

		
		public function AABBTreeTest() {
			super ();

			stageWidth = stage.stageWidth;
			stageHeight = stage.stageHeight;
			
			g = graphics;
			var overlaySprite:Sprite;
			stage.addChild(overlaySprite = new Sprite());
			overlay = overlaySprite.graphics;
			
			// instantiate the tree with a fattenDelta of 10 pixels and using area evaluation as insert strategy
			tree = new AABBTree(10, new InsertStrategyArea());
			renderer = new CustomRenderer(g);
			
			// insert entities with random aabbs (or points)
			for (var i:int = 0; i < 6; i++) {
				var e:Entry = getRandomEntry();
				var aabb:AABB = e.aabb;
				e.id = tree.insertLeaf(e, aabb.x, aabb.y, aabb.width, aabb.height);
			}
			
			overlaySprite.addChild(text = getTextField("", stageWidth - 230, 5));
			
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			stage.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			//quit();
		}
		
		public function drawEntries(g:Graphics, list:Vector.<*>, color:int, alpha:Number):void 
		{
			for (var i:int = 0; i < list.length; i++) {
				var e:Entry = list[i] as Entry;
				g.lineStyle(1, color, alpha);
				var aabb:AABB = e.aabb;
				if (aabb.width < .5 && aabb.height < .5) {
					g.drawCircle(aabb.x, aabb.y, 2);
				} else {
					g.beginFill(color, alpha);
					g.drawRect(aabb.x, aabb.y, aabb.width, aabb.height);
					g.endFill();
				}
			}
		}
		
		public function queryCallback(data:Entry, id:int):HitBehaviour
		{
			if (data.aabb.width > 0 && data.aabb.height > 0) return HitBehaviour.SKIP;
			return HitBehaviour.INCLUDE;
		}

		public function clamp(value:int, min:int, max:int):int 
		{
			if (value < min) return min;
			else if (value > max) return max;
			return value;
		}
		
		public function getRandomEntry():Entry
		{
			var aabb:AABB = new AABB(Math.random() * stageWidth * .5 + 25, Math.random() * stageHeight * .6 + 25, Math.random() * 100 + 10, Math.random() * 100 + 10);
			
			// 50% chance of inserting a point (rect with size 0)
			if (Math.random() < .5) {
				aabb.width = 0;
				aabb.height = 0;
			}
			var dir:Point = new Point(Math.random() * 2 - 1, Math.random() * 2 - 1);
			dir.normalize(4);
			var e:Entry = new Entry(dir, aabb);
			return e;
		}

		
		public function onKeyDown(e:KeyboardEvent):void 
		{
			var i:int, count:int;
			var syncMaxLevel:Boolean = renderer.maxLevel == tree.height;

			switch (e.keyCode) 
			{
				case 27:							// ESC: quit
					quit();
					break;
				case UP:							// inc/dec max drawn level
				case DOWN:
					renderer.maxLevel += e.keyCode == UP ? 1 : -1;
					renderer.maxLevel = clamp(renderer.maxLevel, 0, tree.height);
					syncMaxLevel = false;
					redraw = true;
					break;
				case "C".charCodeAt(0):				// clear tree
					tree.clear();
					redraw = true;
					break;
				case "B".charCodeAt(0):				// rebuild tree bottom-up (beware: sloow!)
					tree.rebuild();
					redraw = true;
					break;
				case RIGHT:							// add random leaf/leaves
					count = e.shiftKey ? 10 : 1;
					for (i = 0; i < count; i++) {
						var entry:Entry = getRandomEntry();
						var aabb:AABB = entry.aabb;
						entry.id = tree.insertLeaf(entry, aabb.x, aabb.y, aabb.width, aabb.height);
					}
					redraw = true;
					break;
				case LEFT:							// remove random leaf/leaves
					count = e.shiftKey ? 10 : 1;
					for (i = 0; i < count; i++) {
						var leafIds:Vector.<int> = tree.getLeavesIds();
						var leaves:int = tree.numLeaves;
						if (leaves > 0) {
							tree.removeLeaf(leafIds[int(Math.random() * leaves)]);
						}
					}
					redraw = true;
					break;
				case "S".charCodeAt(0):				// toggle strictMode
					strictMode = !strictMode;
					redraw = true;
					break;
				case "R".charCodeAt(0):				// toggle rayMode
					rayMode	= !rayMode;
					redraw = true;
					break;
				case "L".charCodeAt(0):				// toggle leafOnly rendering
					renderer.leafOnly = !renderer.leafOnly;
					redraw = true;
					break;
				case "A".charCodeAt(0):				// toggle animMode
					animMode = !animMode;
					redraw = true;
					break;
				case "F".charCodeAt(0):				// toggle filterMode
					filterMode = !filterMode;
					redraw = true;
					break;
				default:
			}		
			
			if (syncMaxLevel) renderer.maxLevel = tree.height;
		}
		
		public function onEnterFrame(e:Event):void 
		{
			if (animMode) {
				redraw = true;
				animate();
			}
			
			if (redraw) {
				query();
				g.clear();
				tree.render(renderer);
			}
			redraw = false;
			
			overlay.clear();
			overlay.lineStyle(2, QUERY_COLOR, .7);
			if (rayMode) {
				overlay.moveTo(startPoint.x, startPoint.y);
				overlay.lineTo(endPoint.x, endPoint.y);
			} else {
				if (queryRect.width < .5 && queryRect.height < .5) {
					overlay.drawCircle(queryRect.x, queryRect.y, 2);
				} else {
					overlay.drawRect(queryRect.x, queryRect.y, queryRect.width, queryRect.height);
				}
			} 
			
			if (results.length > 0) drawEntries(overlay, results, RESULTS_COLOR, RESULTS_ALPHA);
			
			updateText();
		}
		
		public function animate():void 
		{
			var ids:Vector.<int> = tree.getLeavesIds();
			for (var i:int = 0; i < ids.length; i++) {
				var id:int = ids[i];
				var e:Entry = tree.getData(id);
				var aabb:AABB = e.aabb;
				
				// bounce
				aabb.x += e.dir.x;
				aabb.y += e.dir.y;
				var center:Point = new Point(aabb.getCenterX(), aabb.getCenterY());
				if (center.x < 0) {
					aabb.x = -center.x;
					e.dir.x *= -1;
				} else if (center.x > stageWidth) {
					aabb.x = stageWidth - aabb.width * .5;
					e.dir.x *= -1;
				}
				if (center.y < 0) {
					aabb.y = -center.y;
					e.dir.y *= -1;
				} else if (center.y > stageHeight) {
					aabb.y = stageHeight - aabb.height * .5;
					e.dir.y *= -1;
				}
				
				tree.updateLeaf(e.id, aabb.x, aabb.y, aabb.width, aabb.height/*, e.dir.x, e.dir.y*/);
			}
		}
		
		public function updateText():void 
		{
			var mem:Number = System.totalMemory / 1024 / 1024;
			if (CONFIG::debug) {
				text.text = "MEM: " + mem.toFixed(2) + " MB     " + "\n";
			} else {
				text.text = "";
			}
			text.appendText( 
				"\n  mouse-drag to perform\n   queries on the tree\n\n\n" +
				"nodes            : " + tree.numNodes + "\n" +
				"leaves           : " + tree.numLeaves + "\n" +
				"height           : " + tree.height + "\n\n" +
				"[R] rayMode      : " + (rayMode ? "ON" : "OFF") + "\n" +
				"[S] strictMode   : " + (strictMode ? "ON" : "OFF") + "\n" +
				"[L] leafOnly     : " + (renderer.leafOnly ? "ON" : "OFF") + "\n" +
				"[A] animMode     : " + (animMode ? "ON" : "OFF") + "\n" +
				"[F] filterMode   : " + (filterMode ? "ON" : "OFF") + "\n\n" +
				"[RIGHT/LEFT] add/remove leaf\n" + 
				"[UP/DOWN]    inc/dec maxLevel\n" +
				"[B]          rebuild tree\n" +
				"[C]          clear tree\n\n");
				
			if (lastQueryInfo != null) {
				text.appendText(
					"query time       : " + lastQueryInfo.time.toFixed(4) + "s\n" +
					"leaves found     : " + lastQueryInfo.found);
			}
			text.appendText("\n\n\nvalidation       : " + (tree.isValidationEnabled ? "ON" : "OFF"));
		}
		
		public function onMouseMove(e:MouseEvent):void 
		{
			if (dragging) {
				endPoint.x = e.stageX;
				endPoint.y = e.stageY;
				
				queryRect.setTo(startPoint.x, startPoint.y, endPoint.x - startPoint.x, endPoint.y - startPoint.y);
				if (endPoint.x < startPoint.x) {
					queryRect.width = startPoint.x - endPoint.x;
					queryRect.x = endPoint.x;
				}
				if (endPoint.y < startPoint.y) {
					queryRect.height = startPoint.y - endPoint.y;
					queryRect.y = endPoint.y;
				}
				redraw = true;
			}
		}
		
		public function onMouseDown(e:MouseEvent):void 
		{
			startPoint.x = e.stageX;
			startPoint.y = e.stageY;
			endPoint.x = e.stageX;
			endPoint.y = e.stageY;
			
			queryRect.x = startPoint.x;
			queryRect.y = startPoint.y;
			queryRect.width = 0;
			queryRect.height = 0;
			
			dragging = true;
		}
		
		public function onMouseUp(e:MouseEvent):void 
		{
			dragging = false;
			redraw = true;
		}
		
		public function query():void 
		{
			var startTime:int = getTimer();
			if (rayMode) results = tree.rayCast(startPoint.x, startPoint.y, endPoint.x, endPoint.y, null, filterMode ? queryCallback : null);
			else results = tree.query(queryRect.x, queryRect.y, queryRect.width, queryRect.height, strictMode, null, filterMode ? queryCallback : null);
			
			lastQueryInfo = { time:(getTimer() - startTime) / 1000.0, found:results.length };
		}
		
		public function getTextField(text:String, x:Number, y:Number):TextField
		{
			var tf:TextField = new TextField();
			var fmt:TextFormat = new TextFormat(TEXT_FONT, null, TEXT_COLOR);
			tf.autoSize = TextFieldAutoSize.LEFT;
			fmt.align = TextFormatAlign.LEFT;
			fmt.size = TEXT_SIZE;
			tf.defaultTextFormat = fmt;
			tf.selectable = false;
			tf.x = x;
			tf.y = y;
			tf.filters = [TEXT_OUTLINE];
			tf.text = text;
			return tf;
		}
		
		public function quit():void 
		{
			System.exit(1);
		}
	}
}