package ds.aabbtree 
{
	/**
	 * Values that can be returned from query and raycast callbacks to decide how to proceed.
	 * 
	 * @author azrafe7
	 */
	public class HitBehaviour 
	{
		static public const SKIP:HitBehaviour = new HitBehaviour();				// continue but don't include in results
		static public const INCLUDE:HitBehaviour = new HitBehaviour();			// include and continue (default)
		static public const INCLUDE_AND_STOP:HitBehaviour = new HitBehaviour();	// include and break out of the search
		static public const STOP:HitBehaviour = new HitBehaviour();				// break out of the search
		
		{ EnumTools.initEnumConstants(HitBehaviour); }
		
		internal var value:String;
		
		public function toString():String
		{
			return value;
		}
	}
}