--[[
   Info.lua
--]]

return {
   LrSdkVersion = 6.0,
   LrSdkMinimumVersion = 6.0, -- minimum SDK version required by this plug-in
   LrToolkitIdentifier = 'com.pongo.MirrorCollections',
   LrPluginName = "MirrorCollections",
   
   -- Add the menu item to the File menu.
   LrExportMenuItems = 
      {
	 {
	    title = "Create Published Collection Structure",
	    file = "CreatePubCollections.lua",
	 }, 
	 {
	    title = "Mirror Standard to Published Collections",
	    file = "MirrorCollection.lua",
	 },
      },
   
   VERSION = { major=0, minor=6, revision=0, build=1, },

}



