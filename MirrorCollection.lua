local LrTasks = import 'LrTasks'
local LrDate = import 'LrDate'
local LrLogger = import 'LrLogger'
local LrFileUtils = import 'LrFileUtils'
local LrApplication = import 'LrApplication'
local LrApplicationView = import 'LrApplicationView'
local LrProgressScope = import 'LrProgressScope'
local LrDialogs = import 'LrDialogs'
local logger = LrLogger( 'CopyCollection' )

local prefs = import 'LrPrefs'.prefsForPlugin()
local catalog = LrApplication.activeCatalog()


logger:enable( "logfile" ) -- Pass either a string or a table of actions.

local function log( message )
   -- logger:trace( message )
end

log('Starting')

prtotal = 0
prdone  = 0

log( 'progresstodo:'..prtotal )

function scanCollections(parent, pnames, allcollections)
   
   for i,v in ipairs( parent:getChildCollections() ) do
      local cname = v:getName()
      allcollections[pnames..cname] = v.localIdentifier
   end

   for i,v in ipairs( parent:getChildCollectionSets() ) do
      local cname = v:getName()..'/'
      --allcollections[pnames..cname] = v.localIdentifier
      allcollections = scanCollections( v, pnames..cname, allcollections )
   end

   return allcollections
   
end


function syncCollectionsFromTo( fromCollections, toCollections )

   for i,v in pairs( toCollections ) do

      if fromCollections[i] then
	 log( 'Syncing collection: '..i )
	 syncPhotosFromTo( fromCollections[i], toCollections[i] )
      else
	 log( 'Skipping non existent collection in source: '..i )
      end

      prdone = prdone + 1
      progress:setPortionComplete( prdone, prtotal )

   end
      
end


function syncPhotosFromTo( fromCollectionId, toCollectionId )

   local realCollection = catalog:getCollectionByLocalIdentifier( fromCollectionId )
   local pubCollection  = catalog:getPublishedCollectionByLocalIdentifier( toCollectionId )
   local pColPhotos = {}
   local differs = false
   local rColPhotosCount = 0
   local pColPhotosCount = 0
   
   for i,v in ipairs( pubCollection:getPhotos() ) do
      --log( i..':'..v.localIdentifier )
      pColPhotos[v.localIdentifier] = true
      pColPhotosCount = pColPhotosCount + 1
   end
      
   for i,v in ipairs( realCollection:getPhotos() ) do
      --log( i..':'..v.localIdentifier )
      if pColPhotos[v.localIdentifier] == nil then
	 differs = true
	 break
      end
      rColPhotosCount = rColPhotosCount + 1
   end

   if pColPhotosCount ~= rColPhotosCount or differs then

      log( 'Collection to refresh!' )
      catalog:withWriteAccessDo("Refreshing Photos", function()
				   log( 'Removing photos...' )
				   pubCollection:removeAllPhotos()
				   log( 'Adding photos...' )
				   pubCollection:addPhotos( realCollection:getPhotos() )
      end)

      log( askRepublish )
      
      if askRepublish == 'ok' then
	 log( "Publishing..." )
	 pubCollection:publishNow()
      end

   end

end



function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end


function runCommand ()

   askRepublish = LrDialogs.confirm( "Do you want also to republish refreshed collections?", nil, "Yes Republish", "Cancel", "Catalog Only" )

   if askRepublish == 'cancel' then return end

   LrTasks.startAsyncTask(function()

	 progress = LrProgressScope({
	       title = "Mirroring Collections",
	 })

	 progress:setCancelable(false)
	 
	 for i,ps in ipairs(catalog:getPublishServices()) do
	    if string.starts( ps:getName(), "MIRROR") then
	       psserv = ps
	       break
	    end
	 end
	 if psserv ~= nil then

	    log('publish service: '..psserv:getName())

	    local stdcollections = scanCollections( catalog, '/', {} )
	    local pubcollections = scanCollections( psserv, '/', {} )

	    for i,v in pairs( stdcollections ) do
	       prtotal = prtotal + 1
	    end
	    
	    syncCollectionsFromTo( stdcollections, pubcollections )  


	 end

	 prefs.p2cmap = p2cmap
	 progress:done()
	 	 
   end )
end

runCommand()
