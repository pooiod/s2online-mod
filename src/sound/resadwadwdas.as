	static public var sendToBrowser:Boolean = ExternalInterface.available && ExternalInterface.call("function(){return typeof window.scratchActiveSounds !== 'undefined';}");
