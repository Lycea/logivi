require( 'love.system' );
require( 'love.timer'  );

local GitHandler      = require( 'src.git.GitHandler'  );
local RepositoryInfos = require( 'src.RepositoryInfos' );

local repositories = unpack( { ... } );
local startTime = love.timer.getTime();

-- Exit early if git isn't available.
if not GitHandler.isGitAvailable() then
    local channel = love.thread.getChannel( 'error' );
    channel:push( { msg = 'git_not_found' } );
    return;
end

for name, path in pairs( repositories ) do
    -- Check if the path points to a valid git repository before attempting
    -- to create a git log and the info file for it.
    if GitHandler.isGitRepository( path ) then
        local count;

        if RepositoryInfos.hasCommitCountFile( name ) then
            count = RepositoryInfos.loadCommitCount( name );
        end

        if not count or not GitHandler.isRepositoryUpToDate( path, count.commits ) then
            print( "  Writing log for " .. name );
            GitHandler.createGitLog( name, path );
            RepositoryInfos.createInfoFile( name );
            RepositoryInfos.createCommitCountFile( name, GitHandler.getTotalCommits( path ));
        else
            print( "  Repository " .. name .. " is up to date!" );
        end

        local channel = love.thread.getChannel( 'info' );
        channel:push( name );
    else
        local channel = love.thread.getChannel( 'error' );
        channel:push( { msg = 'no_repository', name = name, data = path } );
    end
end

local endTime = love.timer.getTime();
print( string.format( 'Loaded git logs in %.3f seconds!', endTime - startTime ));
