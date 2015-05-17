--==================================================================================================
-- Copyright (C) 2014 - 2015 by Robert Machmer                                                     =
--                                                                                                 =
-- Permission is hereby granted, free of charge, to any person obtaining a copy                    =
-- of this software and associated documentation files (the "Software"), to deal                   =
-- in the Software without restriction, including without limitation the rights                    =
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell                       =
-- copies of the Software, and to permit persons to whom the Software is                           =
-- furnished to do so, subject to the following conditions:                                        =
--                                                                                                 =
-- The above copyright notice and this permission notice shall be included in                      =
-- all copies or substantial portions of the Software.                                             =
--                                                                                                 =
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR                      =
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,                        =
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE                     =
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER                          =
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,                   =
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN                       =
-- THE SOFTWARE.                                                                                   =
--==================================================================================================

local ScreenManager = require('lib.screenmanager.ScreenManager');
local Screen = require('lib.screenmanager.Screen');
local LogCreator = require('src.logfactory.LogCreator');
local LogLoader = require('src.logfactory.LogLoader');
local ButtonList = require('src.ui.ButtonList');
local Button = require('src.ui.components.Button');
local Header = require('src.ui.components.Header');
local StaticPanel = require('src.ui.components.StaticPanel');
local ConfigReader = require('src.conf.ConfigReader');
local InputHandler = require('src.InputHandler');
local OpenFolderCommand = require('src.ui.commands.OpenFolderCommand');
local RefreshLogCommand = require('src.ui.commands.RefreshLogCommand');
local WatchCommand = require('src.ui.commands.WatchCommand');
local Resources = require('src.Resources');

-- ------------------------------------------------
-- Module
-- ------------------------------------------------

local SelectionScreen = {};

-- ------------------------------------------------
-- Constants
-- ------------------------------------------------

local TEXT_FONT    = Resources.loadFont('SourceCodePro-Medium.otf', 15);
local DEFAULT_FONT = Resources.loadFont('default', 12);

-- ------------------------------------------------
-- Constructor
-- ------------------------------------------------

function SelectionScreen.new()
    local self = Screen.new();

    local config;
    local logList;

    local buttonList;
    local buttons;
    local header;
    local panel;

    local uiElementPadding = 20;
    local uiElementMargin = 5;

    local info = {};

    -- ------------------------------------------------
    -- Private Functions
    -- ------------------------------------------------

    ---
    -- Updates the project's window settings based on the config file.
    -- @param options
    --
    local function setWindowMode(options)
        local _, _, flags = love.window.getMode();

        -- Only update the window when the values are different from the ones set in the config file.
        if flags.fullscreen ~= options.fullscreen or flags.fullscreentype ~= options.fullscreenType or
                flags.vsync ~= options.vsync or flags.msaa ~= options.msaa or flags.display ~= options.display then

            flags.fullscreen = options.fullscreen;
            flags.fullscreentype = options.fullscreenType;
            flags.vsync = options.vsync;
            flags.msaa = options.msaa;
            flags.display = options.display;

            love.window.setMode(options.screenWidth, options.screenHeight, flags);

            local sw, sh = love.window.getDesktopDimensions();
            love.window.setPosition(sw * 0.5 - love.graphics.getWidth() * 0.5, sh * 0.5 - love.graphics.getHeight() * 0.5);
        end
    end

    -- ------------------------------------------------
    -- Public Functions
    -- ------------------------------------------------

    function self:init(param)
        config = ConfigReader.init();

        -- Set the background color based on the option in the config file.
        love.graphics.setBackgroundColor(config.options.backgroundColor);
        setWindowMode(config.options);

        -- Create git logs for repositories specified in the config file.
        if LogCreator.isGitAvailable() then
            for name, path in pairs(config.repositories) do
                LogCreator.createGitLog(name, path);
                LogCreator.createInfoFile(name, path);
            end
        end

        -- Intitialise LogLoader.
        logList = LogLoader.init();

        -- A scrollable list of buttons which can be used to select a certain log.
        buttonList = ButtonList.new(uiElementPadding, uiElementPadding, uiElementMargin);
        buttonList:init(self, logList);

        -- Load info about currently selected log.
        info = LogLoader.loadInfo(param and param.log or logList[1].name);

        local sw, sh = love.graphics.getDimensions();
        buttons = {
            Button.new(OpenFolderCommand.new(love.filesystem.getSaveDirectory()), 'Open', uiElementPadding + (2 * uiElementMargin) + 220, sh - uiElementPadding - 10 - uiElementPadding - 40, 100, 40);
            Button.new(WatchCommand.new(self), 'Watch', sw - uiElementPadding - 10 - 100, sh - uiElementPadding - 10 - uiElementPadding - 40, 100, 40);
            Button.new(RefreshLogCommand.new(self), 'Refresh', sw - uiElementPadding - 20 - 200, sh - uiElementPadding - 10 - uiElementPadding - 40, 100, 40);
        };

        header = Header.new(info.name, uiElementPadding + (2 * uiElementMargin) + 200 + 25, uiElementPadding + 25);
        panel = StaticPanel.new(uiElementPadding + (2 * uiElementMargin) + buttonList:getButtonWidth(), uiElementPadding, sw - (uiElementPadding + (2 * uiElementMargin) + 200) - 20, sh - uiElementPadding - 40);
    end

    function self:update(dt)
        buttonList:update(dt);
        for i = 1, #buttons do
            buttons[i]:update(dt);
        end
    end

    function self:resize(nw, nh)
        panel:setDimensions(nw - (uiElementPadding + (2 * uiElementMargin) + 200) - 20, nh - uiElementPadding - 40)
        buttons[1]:setPosition(uiElementPadding + (2 * uiElementMargin) + 210, nh - uiElementPadding - 10 - uiElementPadding - 40);
        buttons[2]:setPosition(nw - uiElementPadding - 10 - 100, nh - uiElementPadding - 10 - uiElementPadding - 40);
        buttons[3]:setPosition(nw - uiElementPadding - 20 - 200, nh - uiElementPadding - 10 - uiElementPadding - 40);
    end

    function self:draw()
        buttonList:draw();

        local x = uiElementPadding + (2 * uiElementMargin) + buttonList:getButtonWidth();
        local y = uiElementPadding;

        panel:draw();
        header:draw();

        love.graphics.setFont(TEXT_FONT);
        love.graphics.print('First commit:  ' .. info.firstCommit, x + 25, y + 100);
        love.graphics.print('Latest commit: ' .. info.latestCommit, x + 25, y + 125);
        love.graphics.print('Total commits: ' .. info.totalCommits, x + 25, y + 150);

        for i = 1, #buttons do
            buttons[i]:draw();
        end

        love.graphics.setFont(DEFAULT_FONT);
        love.graphics.print('Work in Progress (v' .. getVersion() .. ')', love.graphics.getWidth() - 180, love.graphics.getHeight() - uiElementPadding);
    end

    function self:watchLog()
        ScreenManager.switch('main', { log = info.name });
    end

    function self:refreshLog()
        if info.name and LogCreator.isGitAvailable() and config.repositories[info.name] then
            local forceOverwrite = true;
            LogCreator.createGitLog(info.name, config.repositories[info.name], forceOverwrite);
            LogCreator.createInfoFile(info.name, config.repositories[info.name], forceOverwrite);
            info = LogLoader.loadInfo(info.name);
        end
    end

    function self:selectLog(name)
        info = LogLoader.loadInfo(name);
        header = Header.new(info.name, uiElementPadding + (2 * uiElementMargin) + 200 + 25, uiElementPadding + 25);
    end

    function self:mousepressed(x, y, b)
        for i = 1, #buttons do
            buttons[i]:mousepressed(x, y, b);
        end
        buttonList:mousepressed(x, y, b);
    end

    function self:mousereleased(x, y, b)
        for i = 1, #buttons do
            buttons[i]:mousereleased(x, y, b);
        end
    end

    function self:keypressed(key)
        if InputHandler.isPressed(key, config.keyBindings.exit) then
            love.event.quit();
        elseif InputHandler.isPressed(key, config.keyBindings.toggleFullscreen) then
            love.window.setFullscreen(not love.window.getFullscreen());
        end
    end

    function self:quit()
        if ConfigReader.getConfig('options').removeTmpFiles then
            ConfigReader.removeTmpFiles();
        end
    end

    return self;
end

return SelectionScreen;
