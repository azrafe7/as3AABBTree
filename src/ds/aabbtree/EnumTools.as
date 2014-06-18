package ds.aabbtree 
{
	import flash.utils.describeType;
	
	/**
	 * 
	 * @see http://scottbilas.com/blog/faking-enums-in-as3/
	 * 
	 * @author azrafe7
	 */
	public class EnumTools 
	{
		public static function initEnumConstants(inType:*) :void
		{
			var type:XML = flash.utils.describeType(inType);
			for each (var constant:XML in type.constant)
				inType[constant.@name].value = constant.@name;
		}
	}

}