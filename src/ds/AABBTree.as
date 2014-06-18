/*
 * This file is part of the AABBTree library for haxe (https://github.com/azrafe7/as3AABBTree).
 * 
 * Developed by Giuseppe Di Mauro (aka azrafe7) and realeased under the MIT license (see LICENSE file).
 * 
 * The code is heavily inspired by the implementations of a dynamic AABB tree by 
 * 
 *  - Nathanael Presson 	(Bullet Physics - http://bulletphysics.org)
 *	- Erin Catto 			(Box2D - http://www.box2d.org)
 */

package ds
{
	import ds.AABB;
	import ds.aabbtree.DebugRenderer;
	import ds.aabbtree.HitBehaviour;
	import ds.aabbtree.IDebugRenderer;
	import ds.aabbtree.InsertChoice;
	import ds.aabbtree.Node;
	import ds.aabbtree.NodePool;
	import ds.aabbtree.IInsertStrategy;
	import ds.aabbtree.InsertStrategyPerimeter;
	import flash.utils.Dictionary;


	/**
	 * AABBTree implementation. A spatial partitioning data structure.
	 * 
	 * Note: by default compiling in DEBUG mode will enable a series of tests
	 * to ensure the structure's validity (will affect performance), while
	 * in RELEASE mode they won't be executed.
	 * 
	 * The `isValidationEnabled` property will be set consequently.
	 * 
	 * @author azrafe7
	 */
	public class AABBTree
	{
		
		CONFIG::debug
		public const isValidationEnabled:Boolean = true;

		CONFIG::release
		public const isValidationEnabled:Boolean = false;

		/** How much to fatten the aabbs. */
		public var fattenDelta:Number;
		
		/** Algorithm to use for choosing where to insert a new leaf. */
		public var insertStrategy:IInsertStrategy;
		
		/** Total number of nodes (includes unused ones). */
		public function get numNodes():int {
			return nodes.length;
		}
		
		/** Total number of leaves. */
		protected var _numLeaves:int = 0;
		public function get numLeaves():int {
			return _numLeaves;
		}
		
		/** Height of the tree. */
		public function get height():int {
			return root != null ? root.invHeight : -1;
		}
		
		
		/* Pooled nodes stuff. */
		protected var pool:NodePool;
		protected var maxId:int = 0;
		protected var unusedIds:Vector.<int>;
		
		protected var root:Node = null;
		
		/* Cache-friendly array of nodes. Entries are set to null when removed (to be reused later). */
		protected var nodes:Vector.<Node>;
		
		/* Set of leaf nodes indices (implemented as IntMap - values are the same as keys). */
		protected var leaves:Dictionary;

		
		/**
		 * Creates a new AABBTree.
		 * 
		 * @param	fattenDelta				How much to fatten the aabbs (to avoid updating the nodes too frequently when the underlying data moves/resizes).
		 * @param	insertStrategy			Strategy to use for choosing where to insert a new leaf. Defaults to `InsertStrategyPerimeter`.
		 * @param	initialPoolCapacity		How much free nodes to have in the pool initially.
		 * @param	poolGrowthCapacity		The pool will grow by this factor when it's empty.
		 */
		public function AABBTree(fattenDelta:Number = 10, insertStrategy:IInsertStrategy = null, initialPoolCapacity:int = 64, poolGrowthFactor:Number = 2):void
		{
			this.fattenDelta = fattenDelta;
			this.insertStrategy = insertStrategy != null ? insertStrategy : new InsertStrategyPerimeter();
			pool = new NodePool(initialPoolCapacity, poolGrowthFactor);
			unusedIds = new Vector.<int>();
			nodes = new Vector.<Node>();
			leaves = new Dictionary();
		}

		/** 
		 * Inserts a leaf node with the specified `aabb` values and associated `data`.
		 * 
		 * The user must store the returned id and use it later to apply changes to the node (removeLeaf(), updateLeaf()).
		 * 
		 * @return The index of the inserted node.
		 */
		public function insertLeaf(data:*, x:Number, y:Number, width:Number = 0, height:Number = 0):int
		{
			// create new node and fatten its aabb
			var leafNode:Node = pool.get(x, y, width, height, data, null, getNextId());
			leafNode.aabb.inflate(fattenDelta, fattenDelta);
			leafNode.invHeight = 0;
			nodes[leafNode.id] = leafNode;
			leaves[leafNode.id] = leafNode.id;
			_numLeaves++;
			
			if (root == null) {
				root = leafNode;
				return leafNode.id;
			}
			
			// find best sibling to insert the leaf
			var leafAABB:AABB = leafNode.aabb;
			var combinedAABB:AABB = new AABB();
			var left:Node;
			var right:Node;
			var node:Node = root;
			var exit:Boolean = false;
			while (!node.isLeaf() && !exit)
			{
				switch (insertStrategy.choose(leafAABB, node))
				{
					case InsertChoice.PARENT:
						exit = true;
						break;
					case InsertChoice.DESCEND_LEFT:
						node = node.left;
						break;
					case InsertChoice.DESCEND_RIGHT:
						node = node.right;
						break;
				}
			}

			var sibling:Node = node;
			
			// create a new parent
			var oldParent:Node = sibling.parent;
			combinedAABB.asUnionOf(leafAABB, sibling.aabb);
			var newParent:Node = pool.get(combinedAABB.x, combinedAABB.y, combinedAABB.width, combinedAABB.height, null, oldParent, getNextId());
			newParent.invHeight = sibling.invHeight + 1;
			nodes[newParent.id] = newParent;

			// the sibling was not the root
			if (oldParent != null) {
				
				if (oldParent.left == sibling) {
					oldParent.left = newParent;
				} else {
					oldParent.right = newParent;
				}
			} else {
				
				// the sibling was the root
				root = newParent;
			}
			newParent.left = sibling;
			newParent.right = leafNode;
			sibling.parent = newParent;
			leafNode.parent = newParent;

			// walk back up the tree fixing heights and AABBs
			node = leafNode.parent;
			while (node != null)
			{
				node = nodes[balance(node.id)];

				left = node.left;
				right = node.right;

				assert(left != null);
				assert(right != null);

				node.invHeight = 1 + int(Math.max(left.invHeight, right.invHeight));
				node.aabb.asUnionOf(left.aabb, right.aabb);

				node = node.parent;
			}

			validate();
			return leafNode.id;
		}
		
		/** 
		 * Updates the aabb of leaf node with the specified `leafId` (must be a leaf node).
		 * 
		 * @param	dx	Movement prediction along the x axis.
		 * @param	dy	Movement prediction along the y axis.
		 * 
		 * @return false if the fat aabb didn't need to be expanded.
		 */
		public function updateLeaf(leafId:int, x:Number, y:Number, width:Number = 0, height:Number = 0, dx:Number = 0, dy:Number = 0):Boolean
		{
			var leafNode:Node = nodes[leafId];
			assert(leafNode.isLeaf());
			
			var newAABB:AABB = new AABB(x, y, width, height);
			
			if (leafNode.aabb.contains(newAABB)) {
				return false;
			}
			
			var data:* = leafNode.data;
			removeLeaf(leafId);
			
			// add movement prediction
			dx *= 2;
			dy *= 2;
			if (dx < 0) {
				x += dx;
				width -= dx;
			} else {
				width += dx;
			}
			if (dy < 0) {
				y += dy;
				height -= dy;
			} else {
				height += dy;
			}
			
			var newId:int = insertLeaf(data, x, y, width, height);
			
			assert(newId == leafId);
			
			return true;
		}
		
		/** 
		 * Removes the leaf node with the specified `leafId` from the tree (must be a leaf node).
		 */
		public function removeLeaf(leafId:int):void
		{
			var leafNode:Node = nodes[leafId];
			assert(leafNode.isLeaf());
			
			delete leaves[leafId];
			
			if (leafNode == root) {
				disposeNode(leafId);
				root = null;
				return;
			}

			var parent:Node = leafNode.parent;
			var grandParent:Node = parent.parent;
			var sibling:Node = parent.left == leafNode ? parent.right : parent.left;

			if (grandParent != null) {
				// connect sibling to grandParent
				if (grandParent.left == parent) {
					grandParent.left = sibling;
				} else {
					grandParent.right = sibling;
				}
				sibling.parent = grandParent;

				// adjust ancestor bounds
				var node:Node = grandParent;
				while (node != null)
				{
					node = nodes[balance(node.id)];

					var left:Node = node.left;
					var right:Node = node.right;

					node.aabb.asUnionOf(left.aabb, right.aabb);
					node.invHeight = 1 + int(Math.max(left.invHeight, right.invHeight));

					node = node.parent;
				}
			} else {
				root = sibling;
				root.parent = null;
			}
			
			// destroy parent
			assert(parent.id != -1);
			disposeNode(parent.id);
			disposeNode(leafId);
			
			CONFIG::debug { assert(_numLeaves == getLeavesIds().length); }
			
			validate();
		}
		
		/** 
		 * Removes all nodes from the tree. 
		 * 
		 * @param	resetPool	If true the internal pool will be reset to its initial capacity.
		 */
		public function clear(resetPool:Boolean = false):void
		{
			var count:int = numNodes;
			while (count > 0) {
				var node:Node = nodes[count - 1];
				if (node != null) disposeNode(node.id);
				count--;
			}
			root = null;
			nodes.length = 0;
			leaves = new Dictionary();
			unusedIds.length = 0;
			maxId = 0;
			if (resetPool) pool.reset();
			
			assert(numNodes == 0);
		}
		
		/** Rebuilds the tree using a bottom-up strategy (should result in a better tree, but is very expensive). */
		public function rebuild():void 
		{
			if (root == null) return;

			// free non-leaf nodes
			var len:int = numNodes;
			while(--len > 0) {
				var node:Node = nodes[i];
				if (node == null) continue;
				if (!node.isLeaf()) {
					disposeNode(node.id);
				} else {
					node.parent = null;
				}
			}
			
			// copy leaves ids
			var leafIds:Vector.<int> = getLeavesIds();
			
			var aabb:AABB = new AABB();
			var count:int = leafIds.length;
			while (count > 1) {
				var minCost:Number = Number.POSITIVE_INFINITY;
				var iMin:int = -1;
				var jMin:int = -1;
				
				// find pair with least perimeter enlargement
				for (var i:int = 0; i < count; i++) {
					var iAABB:AABB = nodes[leafIds[i]].aabb;

					for (var j:int = i + 1; j < count; j++) {
						var jAABB:AABB = nodes[leafIds[j]].aabb;
						
						aabb.asUnionOf(iAABB, jAABB);
						var cost:Number = aabb.getPerimeter();
						if (cost < minCost) {
							iMin = i;
							jMin = j;
							minCost = cost;
						}
					}
				}

				var left:Node = nodes[leafIds[iMin]];
				var right:Node = nodes[leafIds[jMin]];
				aabb.asUnionOf(left.aabb, right.aabb);
				var parent:Node = pool.get(aabb.x, aabb.y, aabb.width, aabb.height, null, null, getNextId());
				parent.left = left;
				parent.right = right;
				parent.invHeight = int(1 + Math.max(left.invHeight, right.invHeight));
				nodes[parent.id] = parent;
				
				left.parent = parent;
				right.parent = parent;
				
				leafIds[iMin] = parent.id;
				leafIds[jMin] = leafIds[count - 1];
				
				count--;
			}

			root = nodes[leafIds[0]];

			validate();
		}
		
		/** Draws the tree using the specified `renderer`. */
		public function render(renderer:IDebugRenderer):void 
		{
			renderer.drawTree(this, root);
		}
		
		/** Returns a list of all the data objects attached to leaves (optionally appending them to `into`). */
		public function getLeavesData(into:Vector.<*> = null):Vector.<*>
		{
			var res:Vector.<*> = into != null ? into : new Vector.<*>();
			for each (var id:int in getKeysFromDict(leaves)) res.push(nodes[id].data);
			return res;
		}
		
		/** Returns a list of all the leaves' ids (optionally appending them to `into`). */
		public function getLeavesIds(into:Vector.<int> = null):Vector.<int>
		{
			var res:Vector.<int> = into != null ? into : new Vector.<int>();
			for each (var id:int in getKeysFromDict(leaves)) res.push(id);
			return res;
		}
		
		/** Returns data associated to the node with the specified `leafId` (must be a leaf node). */
		public function getData(leafId:int):*
		{
			var leafNode:Node = nodes[leafId];
			assert(leafNode.isLeaf());
			
			return leafNode.data;
		}
		
		/** Returns a clone of the aabb associated to the node with the specified `leafId` (must be a leaf node). */
		public function getFatAABB(leafId:int):AABB
		{
			var leafNode:Node = nodes[leafId];
			assert(leafNode.isLeaf());
			
			return leafNode.aabb.clone();
		}
		
		/**
		 * Queries the tree for objects in the specified AABB.
		 * 
		 * @param	into			Hit objects will be appended to this (based on callback return value).
		 * @param	strictMode		If set to true only objects fully contained in the AABB will be processed. Otherwise they will be checked for intersection (default).
		 * @param	callback		A function called for every object hit (function callback(data:*, id:int):HitBehaviour).
		 * 
		 * @return A list of all the objects found (or `into` if it was specified).
		 */
		public function query(x:Number, y:Number, width:Number = 0, height:Number = 0, strictMode:Boolean = false, into:Vector.<*> = null, callback:Function = null):Vector.<*>
		{
			var res:Vector.<*> = into != null ? into : new Vector.<*>();
			if (root == null) return res;
			
			var stack:Vector.<Node> = new <Node>[root];
			var queryAABB:AABB = new AABB(x, y, width, height);
			var cnt:int = 0;
			while (stack.length > 0) {
				var node:Node = stack.pop();
				cnt++;
				
				if (queryAABB.overlaps(node.aabb)) {
					if (node.isLeaf() && (!strictMode || (strictMode && queryAABB.contains(node.aabb)))) {
						if (callback != null) {
							var hitBehaviour:HitBehaviour = callback(node.data, node.id);
							if (hitBehaviour == HitBehaviour.INCLUDE || hitBehaviour == HitBehaviour.INCLUDE_AND_STOP) {
								res.push(node.data);
							}
							if (hitBehaviour == HitBehaviour.STOP || hitBehaviour == HitBehaviour.INCLUDE_AND_STOP) {
								break;
							}
						} else {
							res.push(node.data);
						}
					} else {
						if (node.left != null) stack.push(node.left);
						if (node.right != null) stack.push(node.right);
					}
				}
			}
			//trace("examined: " + cnt);
			return res;
		}
		
		/**
		 * Queries the tree for objects overlapping the specified point.
		 * 
		 * @param	into			Hit objects will be appended to this (based on callback return value).
		 * @param	callback		A function called for every object hit (function callback(data:*, id:int):HitBehaviour).
		 * 
		 * @return A list of all the objects found (or `into` if it was specified).
		 */
		public function queryPoint(x:Number, y:Number, into:Vector.<*> = null, callback:Function = null):Vector.<*>
		{
			return query(x, y, 0, 0, false, into, callback);
		}
		
		/**
		 * Queries the tree for objects crossing the specified ray.
		 * 
		 * Notes: 
		 * 	- the intersecting objects will be returned in no particular order (closest ones to the start point may appear later in the list!).
		 *  - the callback will also be called if an object fully contains the ray's start and end point.
		 * 
		 * TODO: see how this can be optimized and return results in order
		 * 
		 * @param	into		Hit objects will be appended to this (based on callback return value).
		 * @param	callback	A function called for every object hit (function callback(data:*, id:int):HitBehaviour).
		 * 
		 * @return A list of all the objects found (or `into` if it was specified).
		 */
		public function rayCast(fromX:Number, fromY:Number, toX:Number, toY:Number, into:Vector.<*> = null, callback:Function = null):Vector.<*>
		{
			var res:Vector.<*> = into != null ? into : new Vector.<*>();
			if (root == null) return res;
			
			var queryAABBResultsIds:Vector.<int> = new Vector.<int>();

			
			function rayAABBCallback(data:*, id:int):HitBehaviour
			{
				var node:Node = nodes[id];
				var aabb:AABB = node.aabb;
				var fromPointAABB:AABB = new AABB(fromX, fromY);
				var toPointAABB:AABB = new AABB(toX, toY);
				
				var hit:Boolean = false;
				for (var i:int = 0; i < 4; i++) {	// test for intersection with node's aabb edges
					switch (i) {
						case 0:	// top edge
							hit = segmentIntersect(fromX, fromY, toX, toY, aabb.minX, aabb.minY, aabb.maxX, aabb.minY);
							break;
						case 1:	// left edge
							hit = segmentIntersect(fromX, fromY, toX, toY, aabb.minX, aabb.minY, aabb.minX, aabb.maxY);
							break;
						case 2:	// bottom edge
							hit = segmentIntersect(fromX, fromY, toX, toY, aabb.minX, aabb.maxY, aabb.maxX, aabb.maxY);
							break;
						case 3:	// right edge
							hit = segmentIntersect(fromX, fromY, toX, toY, aabb.maxX, aabb.minY, aabb.maxX, aabb.maxY);
							break;
						default:	
					}
					if (hit) break;
				}
				
				// add intersected node id to array
				if (hit || (!hit && aabb.contains(fromPointAABB))) {
					queryAABBResultsIds.push(id);
				}
				
				return HitBehaviour.SKIP;	// don't bother adding to results
			}
			
			var tmp:Number;
			var rayAABB:AABB = new AABB(fromX, fromY, toX - fromX, toY - fromY);
			if (rayAABB.minX > rayAABB.maxX) {
				tmp = rayAABB.maxX;
				rayAABB.maxX = rayAABB.minX;
				rayAABB.minX = tmp;
			}
			if (rayAABB.minY > rayAABB.maxY) {
				tmp = rayAABB.maxY;
				rayAABB.maxY = rayAABB.minY;
				rayAABB.minY = tmp;
			}
			
			query(rayAABB.x, rayAABB.y, rayAABB.width , rayAABB.height, false, null, rayAABBCallback);
			
			for (var i:int = 0; i < queryAABBResultsIds.length; i++) {
				var id:int = queryAABBResultsIds[i]
				var node:Node = nodes[id];
				if (callback != null) {
					var hitBehaviour:HitBehaviour = callback(node.data, node.id);
					if (hitBehaviour == HitBehaviour.INCLUDE || hitBehaviour == HitBehaviour.INCLUDE_AND_STOP) {
						res.push(node.data);
					}
					if (hitBehaviour == HitBehaviour.STOP || hitBehaviour == HitBehaviour.INCLUDE_AND_STOP) {
						break;
					}
				} else {
					res.push(node.data);
				}
			}
			
			return res;
		}
		
		/** Gets the next available id for a node, fecthing it from the list of unused ones if available. */
		protected function getNextId():int 
		{
			var newId:int = unusedIds.length > 0 && unusedIds[unusedIds.length - 1] < maxId ? unusedIds.pop() : maxId++;
			return newId;
		}
		
		/** Returns the node with the specified `id` to the pool. */
		protected function disposeNode(id:int):void {
			assert(nodes[id] != null);

			var node:Node = nodes[id];
			if (node.isLeaf()) _numLeaves--;
			nodes[node.id] = null;
			unusedIds.push(node.id);
			pool.put(node);
		}
		
		/**
		 * Performs a left or right rotation if `nodeId` is unbalanced.
		 * 
		 * @return The new parent index.
		 */
		protected function balance(nodeId:int):int
		{
			var A:Node = nodes[nodeId];
			assert(A != null);

			if (A.isLeaf() || A.invHeight < 2) {
				return A.id;
			}

			var B:Node = A.left;
			var C:Node = A.right;

			var balanceValue:int = C.invHeight - B.invHeight;

			// rotate C up
			if (balanceValue > 1) return rotateLeft(A, B, C);
			
			// rotate B up
			if (balanceValue < -1) return rotateRight(A, B, C);

			return A.id;
		}

		/** Returns max height distance between two children (of the same parent) in the tree. */
		public function getMaxBalance():int
		{
			var maxBalance:int = 0;
			for (var i:int = 0; i < nodes.length; i++) {
				var node:Node = nodes[i];
				if (node.invHeight <= 1 || node == null) continue;

				assert(!node.isLeaf());

				var left:Node = node.left;
				var right:Node = node.right;
				var balance:int = Math.abs(right.invHeight - left.invHeight);
				maxBalance = int(Math.max(maxBalance, balance));
			}

			return maxBalance;
		}
		
		/*
		 *           A			parent
		 *         /   \
		 *        B     C		left and right nodes
		 *             / \
		 *            F   G
		 */
		protected function rotateLeft(parentNode:Node, leftNode:Node, rightNode:Node):int
		{
			var F:Node = rightNode.left;
			var G:Node = rightNode.right;

			// swap A and C
			rightNode.left = parentNode;
			rightNode.parent = parentNode.parent;
			parentNode.parent = rightNode;

			// A's old parent should point to C
			if (rightNode.parent != null) {
				if (rightNode.parent.left == parentNode) {
					rightNode.parent.left = rightNode;
				} else {
					assert(rightNode.parent.right == parentNode);
					rightNode.parent.right = rightNode;
				}
			} else {
				root = rightNode;
			}

			// rotate
			if (F.invHeight > G.invHeight) {
				rightNode.right = F;
				parentNode.right = G;
				G.parent = parentNode;
				parentNode.aabb.asUnionOf(leftNode.aabb, G.aabb);
				rightNode.aabb.asUnionOf(parentNode.aabb, F.aabb);

				parentNode.invHeight = 1 + int(Math.max(leftNode.invHeight, G.invHeight));
				rightNode.invHeight = 1 + int(Math.max(parentNode.invHeight, F.invHeight));
			} else {
				rightNode.right = G;
				parentNode.right = F;
				F.parent = parentNode;
				parentNode.aabb.asUnionOf(leftNode.aabb, F.aabb);
				rightNode.aabb.asUnionOf(parentNode.aabb, G.aabb);

				parentNode.invHeight = 1 + int(Math.max(leftNode.invHeight, F.invHeight));
				rightNode.invHeight = 1 + int(Math.max(parentNode.invHeight, G.invHeight));
			}
			
			return rightNode.id;
		}
		
		/*
		 *           A			parent
		 *         /   \
		 *        B     C		left and right nodes
		 *       / \
		 *      D   E
		 */
		protected function rotateRight(parentNode:Node, leftNode:Node, rightNode:Node):int
		{
			var D:Node = leftNode.left;
			var E:Node = leftNode.right;

			// swap A and B
			leftNode.left = parentNode;
			leftNode.parent = parentNode.parent;
			parentNode.parent = leftNode;

			// A's old parent should point to B
			if (leftNode.parent != null)
			{
				if (leftNode.parent.left == parentNode) {
					leftNode.parent.left = leftNode;
				} else {
					assert(leftNode.parent.right == parentNode);
					leftNode.parent.right = leftNode;
				}
			} else {
				root = leftNode;
			}

			// rotate
			if (D.invHeight > E.invHeight) {
				leftNode.right = D;
				parentNode.left = E;
				E.parent = parentNode;
				parentNode.aabb.asUnionOf(rightNode.aabb, E.aabb);
				leftNode.aabb.asUnionOf(parentNode.aabb, D.aabb);

				parentNode.invHeight = 1 + int(Math.max(rightNode.invHeight, E.invHeight));
				leftNode.invHeight = 1 + int(Math.max(parentNode.invHeight, D.invHeight));
			} else {
				leftNode.right = E;
				parentNode.left = D;
				D.parent = parentNode;
				parentNode.aabb.asUnionOf(rightNode.aabb, D.aabb);
				leftNode.aabb.asUnionOf(parentNode.aabb, E.aabb);

				parentNode.invHeight = 1 + int(Math.max(rightNode.invHeight, D.invHeight));
				leftNode.invHeight = 1 + int(Math.max(parentNode.invHeight, E.invHeight));
			}

			return leftNode.id;
		}
		
		protected function getNode(id:int):Node 
		{
			assert(id >= 0 && nodes[id] != null);
			return nodes[id];
		}
		
		/** Tests validity of node with the specified `id` (and its children). */
		protected function validateNode(id:int):void 
		{
			var aabb:AABB = new AABB();
			var root:Node = nodes[id];
			var stack:Vector.<Node> = new <Node>[root];
			while (stack.length > 0) {
				var node:Node = stack.pop();
				assert(node != null);
				
				var left:Node = node.left;
				var right:Node = node.right;
				
				if (node.isLeaf()) {
					assert(left == null);
					assert(right == null);
					node.invHeight = 0;
					assert(leaves[node.id] >= 0);
					continue;
				}
				
				assert(left.id >= 0);
				assert(right.id >= 0);
				
				assert(node.invHeight == 1 + Math.max(left.invHeight, right.invHeight));
				aabb.asUnionOf(left.aabb, right.aabb);
				assert(Math.abs(node.aabb.minX - aabb.minX) < 0.000001);
				assert(Math.abs(node.aabb.minY - aabb.minY) < 0.000001);
				assert(Math.abs(node.aabb.maxX - aabb.maxX) < 0.000001);
				assert(Math.abs(node.aabb.maxY - aabb.maxY) < 0.000001);
			}
		}
		
		static protected function getKeysFromDict(dict:Dictionary):Vector.<*>
		{
			var res:Vector.<*> = new Vector.<*>();
			for (var k:* in dict) res.push(k);
			return res;
		}
		
		static protected function segmentIntersect(p0x:Number, p0y:Number, p1x:Number, p1y:Number, q0x:Number, q0y:Number, q1x:Number, q1y:Number):Boolean
		{
			var intX:Number, intY:Number;
			var a1:Number, a2:Number;
			var b1:Number, b2:Number;
			var c1:Number, c2:Number;
		 
			a1 = p1y - p0y;
			b1 = p0x - p1x;
			c1 = p1x * p0y - p0x * p1y;
			a2 = q1y - q0y;
			b2 = q0x - q1x;
			c2 = q1x * q0y - q0x * q1y;
		 
			var denom:Number = a1 * b2 - a2 * b1;
			if (denom == 0) {
				return false;
			}
			
			intX = (b1 * c2 - b2 * c1) / denom;
			intY = (a2 * c1 - a1 * c2) / denom;
		 
			// check to see if distance between intersection and endpoints
			// is longer than actual segments.
			// return false otherwise.
			if (distanceSquared(intX, intY, p1x, p1y) > distanceSquared(p0x, p0y, p1x, p1y)) return false;
			if (distanceSquared(intX, intY, p0x, p0y) > distanceSquared(p0x, p0y, p1x, p1y)) return false;
			if (distanceSquared(intX, intY, q1x, q1y) > distanceSquared(q0x, q0y, q1x, q1y)) return false;
			if (distanceSquared(intX, intY, q0x, q0y) > distanceSquared(q0x, q0y, q1x, q1y)) return false;
			
			return true;
		}
		
		static protected function distanceSquared(px:Number, py:Number, qx:Number, qy:Number):Number { return sqr(px - qx) + sqr(py - qy); }
		
		static protected function sqr(x:Number):Number { return x * x; }

		
		CONFIG::debug
		protected function validate():void {
			if (root != null) validateNode(root.id);
			assert(_numLeaves >= 0 && _numLeaves <= numNodes);
		}
		
		CONFIG::debug
		protected static function assert(cond:Boolean):void {
			if (!cond) throw "ASSERT FAILED!";
		}
		
		CONFIG::release
		protected function validate():void {
			return;
		}
		
		CONFIG::release
		protected static function assert(cond:Boolean):void {
			return;
		}
	}
}