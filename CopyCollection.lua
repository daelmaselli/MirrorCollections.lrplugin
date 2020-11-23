local LrTasks = import 'LrTasks'
local LrLogger = import 'LrLogger'
local LrFileUtils = import 'LrFileUtils'
local LrApplicationView = import 'LrApplicationView'
local logger = LrLogger( 'CopyCollection' )

logger:enable( "logfile" ) -- Pass either a string or a table of actions.

local function log( message )
   logger:trace( message )
end

log('Starting')

local LrApplication = import 'LrApplication'
local catalog = LrApplication.activeCatalog()
local dumpPath = '/tmp/CopyCollection/'

function getCollectionSon(parent,l,collPath)

   log( 'doing collection in path: '..collPath )
   for i,v in ipairs(parent:getChildCollections()) do
      log( '  '..v:getName() )
      if 0 == 0 then

         for l,w in ipairs(v:getPhotos()) do
	    log( w )

	    currentDir = collPath..v:getName()
	    currentFilename = currentDir..'/'..w:getFormattedMetadata("fileName")..'.jpg'

	    fileTime = 0
	    if LrFileUtils.exists( currentFilename ) then
	       fileattrs = LrFileUtils.fileAttributes( currentFilename )
	       fileTime = fileattrs["fileModificationDate"]
	    end

	    lrEditTime = w:getRawMetadata("lastEditTime")

	    log( ' last file time '..fileTime..', last lr edit '..lrEditTime )

	    if fileTime == 0 or lrEditTime > fileTime then
	       
	       thumbDone = 0
	       local thumb = w:requestJpegThumbnail(2500, 2500, function(data, errorMsg)
						       if data == nil then
							  
							  log( 'error requesting thumb '..errorMsg )
						       else
							  
							  log( "Writing "..currentFilename.."..." )
							  LrFileUtils.createAllDirectories( currentDir )
							  file = io.open(currentFilename, "w")
							  file:write(data)
							  file:close()
							  
						       end
						       thumbDone = 1

	       end)
	       
	       while thumbDone == 0 do
		  LrTasks.sleep(0.1)
	       end

	    end

	 end

      end
      
   end
   
   for i,v in ipairs(parent:getChildCollectionSets()) do
      log( l..' '..v:getName() )
      getCollectionSon( v, (l+1), collPath..v:getName()..'/' )
   end

end

local function getCollections()
   getCollectionSon(catalog,0,dumpPath)
end

local LrTasks = import 'LrTasks'
local function runCommand ()
   LrTasks.startAsyncTask(function()
	 LrApplicationView.switchToModule('library')
         LrTasks.sleep(1)
         catalog:withWriteAccessDo("Exporting previews...", getCollections)
   end )
end

runCommand()
