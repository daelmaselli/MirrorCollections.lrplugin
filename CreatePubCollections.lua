local LrTasks = import 'LrTasks'
local LrDate = import 'LrDate'
local LrLogger = import 'LrLogger'
local LrFileUtils = import 'LrFileUtils'
local LrApplication = import 'LrApplication'
local LrApplicationView = import 'LrApplicationView'
local LrProgressScope = import 'LrProgressScope'
local logger = LrLogger( 'CopyCollection' )

local prefs = import 'LrPrefs'.prefsForPlugin()
local catalog = LrApplication.activeCatalog()


logger:enable( "logfile" ) -- Pass either a string or a table of actions.

local function log( message )
   logger:trace( message )
end

log('Starting')

prtotal = 0
prdone  = 0

log( 'progresstodo:'..prtotal )


function createPubCollections(parent, psparent)

   for i,v in ipairs(parent:getChildCollections()) do
      catalog:withWriteAccessDo("Create Mirrored Collection", function()
				   newps = psserv:createPublishedCollection( v:getName(), psparent, true )
      end)
   end

   for i,v in ipairs(parent:getChildCollectionSets()) do
      catalog:withWriteAccessDo("Create Mirrored Collection", function()
				   newps = psserv:createPublishedCollectionSet( v:getName(), psparent, true )
      end)
      createPubCollections( v, newps )
   end
   
end



function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end


function runCommand ()
   LrTasks.startAsyncTask(function()

	 progress = LrProgressScope({
	       title = "Creating Collections",
	 })

	 progress:setCancelable(false)
	 
	 for i,ps in ipairs(catalog:getPublishServices()) do
	    if string.starts( ps:getName(), "MIRROR") then
	       psserv = ps
	       break
	    end
	 end
	 
	 if psserv ~= nil then

	    createPubCollections(catalog, psserv)

	 end

	 progress:done()
	 
	 
   end )
end

runCommand()
