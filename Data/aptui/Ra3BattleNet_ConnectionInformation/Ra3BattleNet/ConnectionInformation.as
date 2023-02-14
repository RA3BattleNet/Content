class Ra3BattleNet.ConnectionInformation {
    private static var CLASS_NAME: String = "Ra3BattleNet.ConnectionInformation";
    private static var NETWORK_ID: String = "Ra3BattleNetConnectionInformationNetwork";
    private static var CPU_ID: String = "Ra3BattleNetConnectionInformationCpu";
    private static var GPU_ID: String = "Ra3BattleNetConnectionInformationGpu";
    private static var OBSERVER_PANEL_ID: String = "Ra3BattleNetConnectionInformationObserverPanel";

    private var _apt: MovieClip;
    private var _widgets: Array;
    private var _isInGame: Boolean;

    public function ConnectionInformation(apt: MovieClip) {
        _apt = apt;
        _apt.onEnterFrame = _global.bind0(this, update);
    }

    private function update() {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::update]";
        var query: Object = new Object();
        loadVariables("Ra3BattleNet_ConnectionInformation", query);
        if (!query.names) {
            trace(TRACE_PREFIX + "no names");
            return;
        }
        requestWidgets();
        if (!_widgets) {
            trace(TRACE_PREFIX + "no widgets");
            return;
        }
        trace(TRACE_PREFIX + "name and widgets availaible");
        var latencies: Array = query.latencies.split(",");
        var packetLosses: Array = query.packetLosses.split(",");
        var logicLoads: Array = query.logicLoads.split(",");
        var renderLoads: Array = query.renderLoads.split(",");
        if (_isInGame) {
            var names: Array = query.names.split(",");
            var isPlaying: Array = query.isPlaying.split(",");
            trace(TRACE_PREFIX + "inside game - isPlaying: " + isPlaying);
            // playing players are always on top
            var i: Number = 0;
            var j: Number = 0;
            while (i < _widgets.length && j < isPlaying.length) {
                if (isPlaying[j] === "0") {
                    ++j;
                }
                // observer name are temporarily shown for debugging
                // otherwise it should be null
                var observerName: String = String(String.fromCharCode.apply(String, names[i].split("_")));
                trace(TRACE_PREFIX + "inside game - player " + i + " is playing, debug name: " + observerName);
                showWidgets(
                    i,
                    Number(latencies[j]), Number(packetLosses[j]),
                    Number(logicLoads[j]), Number(renderLoads[j]),
                    observerName
                );
                ++i;
                ++j;
            }
            // if there are some non-playing players (observers), show them at the bottom
            j = 0;
            while (i < _widgets.length) {
                if (isPlaying[j] === "1") {
                    ++j;
                }
                var observerName: String = String(String.fromCharCode.apply(String, names[i].split("_")));
                trace(TRACE_PREFIX + "inside game - player " + i + " is not playing, observerName name: " + observerName);
                showWidgets(
                    i,
                    Number(latencies[j]), Number(packetLosses[j]),
                    Number(logicLoads[j]), Number(renderLoads[j]),
                    observerName
                );
                ++i;
                ++j;
            }
        }
        else {
            for (var i: Number = 0; i < _widgets.length; ++i) {
                if (isPlaying[i] === "0") {
                    trace(TRACE_PREFIX + "outside game - player " + i + " is not playing");
                    resetWidgets(i);
                }
                else {
                    trace(TRACE_PREFIX + "outside game - player " + i + " is playing");
                    showWidgets(i, Number(latencies[i]), Number(packetLosses[i]), 1, 1, null);
                }
            }
        }
    }

    private function requestWidgets(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::requestWidgets] ";
        if (_widgets) {
            trace(TRACE_PREFIX + "widgets already exist");
            return;
        }
        if (!_global.Cafe2_BaseUIScreen) {
            trace(TRACE_PREFIX + "Cafe2_BaseUIScreen not found");
            return;
        }
        var screenInstance = _global.Cafe2_BaseUIScreen.m_thisClass;
        if (!screenInstance) {
            trace(TRACE_PREFIX + "screen not found");
            return;
        }
        _isInGame = false;
        var playerApts: Array = screenInstance.m_playerSlots;
        if (!playerApts || !(playerApts[0] instanceof MovieClip)) {
            playerApts = screenInstance.m_playerLineMCs;
            if (!playerApts || !(playerApts[0] instanceof MovieClip)) {
                trace(TRACE_PREFIX + "player slots not found");
                return;
            }
            // campaign pause menu has no player count
            // or skirmish pause menu has not been loaded yet
            if (!screenInstance.m_playerCount) {
                trace(TRACE_PREFIX + "player count not found");
                return;
            }
            _isInGame = true;
        }
        var result: Array = new Array();
        for (var i: Number = 0; i < playerApts.length; ++i) {
            var playerApt: MovieClip = playerApts[i];
            if (!(playerApt instanceof MovieClip)) {
                // something is wrong
                trace(TRACE_PREFIX + "player slot is not a movie clip");
                return;
            }
            var widgets: Object = _isInGame
                ? createInGameWidgets(playerApt, i)
                : createOutGameWidgets(playerApt, i);
            if (widgets) {
                result.push(widgets);
                trace(TRACE_PREFIX + "constructed widgets");
            }
            else {
                trace(TRACE_PREFIX + "failed to construct widgets");
                return;
            }
        }
        if (result.length == 0) {
            trace(TRACE_PREFIX + "no widgets constructed");
            return;
        }
        _widgets = result;
        trace(TRACE_PREFIX + "widgets constructed");
    }

    private function createInGameWidgets(playerApt: MovieClip, index: Number): Object {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createInGameWidgets] ";

        var x: Number = 0;
        var horizontalMiddle: Number = 0;
        var padding: Number = 8;
        var result = new Object();
        // the player apt is the movieclip which contains player's information
        // our connection information is also "player's information"
        if (!playerApt._visible) {
            // if the player apt is not visible,
            // we create a panel to show our information
            trace(TRACE_PREFIX + "player apt " + index + " is not visible");
            if (!(_apt[OBSERVER_PANEL_ID] instanceof MovieClip)) {
                // create observer panel at playerApt's position
                var playerAptRect: Object = convertCoordinates(playerApt);
                // now consider the panel as the player apt
                playerApt = tryAttachMovie("InGameObserverPanel", OBSERVER_PANEL_ID);
                playerApt._x = playerAptRect.x;
                playerApt._y = playerAptRect.y;
                for (var i: Number = 0; i < 6; ++i) {
                    var observerName: MovieClip = playerApt["observer" + i];
                    observerName._visible = false;
                }
                trace(TRACE_PREFIX + "observer panel created");
            }
            var observerName: MovieClip = playerApt["observer" + index];
            observerName._visible = true;
            var observerRect: Object = convertCoordinates(observerName);
            x = observerRect.x + observerRect.width + padding;
            horizontalMiddle = observerRect.y + observerRect.height * 0.5;
            result.observerName = observerName.name;
        }
        else {
            // create widgets at the right of the player's color
            var color: MovieClip = playerApt.colorMC;
            if (!color || !(color instanceof MovieClip)) {
                // something is wrong
                trace(TRACE_PREFIX + "color movie clip not found in " + playerApt);
                return null;
            }
            var colorRect: Object = convertCoordinates(color);
            x = colorRect.x + colorRect.width + padding;
            horizontalMiddle = colorRect.y + colorRect.height * 0.5;
        }
        
        function appendWidget(symbol: String, id: String) {
            var widget: MovieClip = tryAttachMovie(symbol, id);
            widget._x = x;
            widget._y = horizontalMiddle - widget._height * 0.5;
            x += widget._width;
            x += padding;
            trace(TRACE_PREFIX + symbol + " created as " + widget);
            return widget;
        }

        result.network = appendWidget("NetworkSymbol", NETWORK_ID + index);
        result.cpu = appendWidget("CpuSymbol", CPU_ID + index);
        result.gpu = appendWidget("GpuSymbol", GPU_ID + index);
        // only for debugging!
        if (!result.observerName) {
            _apt.createTextField("debug" + index, _global.Ra3BattleNet.Utils.getNextHighestDepth(_apt), x, horizontalMiddle - 10, 100, 20);
            var debug: TextField = _apt["debug" + index];
            debug.setTextFormat(_global.std_config.textBox_textFormat_highlight);
            debug.text = "debug";
            result.observerName = debug;
        }
        return result;
    }

    private function createOutGameWidgets(playerApt: MovieClip, index: Number): Object {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createOutGameWidgets] ";

        var voip: MovieClip = playerApt.voipCheckBox;
        if (!(voip instanceof MovieClip)) {
            trace(TRACE_PREFIX + "voip check box not found in " + playerApt);
            return null;
        }
        var mute: MovieClip = playerApt.muteCheckBox;
        if (!(mute instanceof MovieClip)) {
            trace(TRACE_PREFIX + "mute check box not found in " + playerApt);
            return null;
        }

        trace(TRACE_PREFIX + _apt + " x/y: " + _apt._x + "/" + _apt._y);
        var voipRect: Object = convertCoordinates(voip);
        var muteRect: Object = convertCoordinates(mute);

        var network: MovieClip = tryAttachMovie("NetworkSymbol", NETWORK_ID + index);
        network._width = voipRect.width * 1.1;
        network._height = voipRect.height * 1.1;
        network._x = voipRect.x - network._width * 0.5;
        network._y = voipRect.y - network._height * 0.5;
        trace(TRACE_PREFIX + network + " x/y/width/height: " + network._x + "/" + network._y + "/" + network._width + "/" + network._height);
        var networkCheck: Object = new Object();
        networkCheck.x = 0;
        networkCheck.y = 0;
        var voipCheck: Object = new Object();
        voipCheck.x = 0;
        voipCheck.y = 0;
        network.localToGlobal(networkCheck);
        voip.localToGlobal(voipCheck);
        trace(TRACE_PREFIX + "network check x/y: " + networkCheck.x + "/" + networkCheck.y);
        trace(TRACE_PREFIX + "voip check x/y: " + voipCheck.x + "/" + voipCheck.y + ", width/height: " + voip._width + "/" + voip._height);


        var cpu: MovieClip = tryAttachMovie("CpuSymbol", CPU_ID + index);
        cpu._width = muteRect.width * 1.1;
        cpu._height = muteRect.height * 1.1;
        cpu._x = muteRect.x - cpu._width * 0.5;
        cpu._y = muteRect.y - cpu._height * 0.5;
        trace(TRACE_PREFIX + cpu + " x/y/width/height: " + cpu._x + "/" + cpu._y + "/" + cpu._width + "/" + cpu._height);

        var result = new Object();
        result.network = network;
        result.cpu = cpu;
        return result;
    }

    private function resetWidgets(index: Number): Void {
        if (!_widgets || !_widgets[index]) {
            return;
        }
        var widgets: Object = _widgets[index];
        var isInGameObserver: Boolean = widgets.observerName instanceof TextField;
        if (isInGameObserver) {
            widgets.observerName._visible = false;
        }
        for (var k: String in widgets) {
            if (widgets[k] instanceof MovieClip) {
                widgets[k].gotoAndStop(1);
                if (isInGameObserver) {
                    widgets[k]._visible = false;
                }
            }
        }
    }

    private function showWidgets(
        index: Number,
        latency: Number, packetLoss: Number, cpu: Number, gpu: Number,
        observerName: String
    ): Void {
        if (!_widgets || !_widgets[index]) {
            trace("ConnectionInformation::showWidgets - no widgets for " + index);
            return;
        }
        var widgets: Object = _widgets[index];
        trace("ConnectionInformation::showWidgets - " + index + " " + latency + " " + packetLoss + " " + cpu + " " + gpu + " " + observerName);
        trace("ConnectionInformation::showWidgets - network: " + widgets.network + " cpu: " + widgets.cpu + " gpu: " + widgets.gpu + " observerName: " + widgets.observerName);
        // NETWORK
        // latency > 990ms, the connection may lost already
        // packetLoss > 0.1, too bad
        if (latency > 0.99 || packetLoss > 0.1) {
            widgets.network.gotoAndStop(2);
        }
        // latency > 300ms
        // there is a loss!
        else if (latency > 0.3 || packetLoss > 0) {
            widgets.network.gotoAndStop(3);
        }
        else {
            widgets.network.gotoAndStop(4);
        }
        // GAME LOGIC LOAD
        if (cpu < 0.25) {
            widgets.cpu.gotoAndStop(2);
        }
        else if (cpu < 0.75) {
            widgets.cpu.gotoAndStop(3);
        }
        else {
            widgets.cpu.gotoAndStop(4);
        }
        // GAME RENDER LOAD
        if (widgets.gpu instanceof MovieClip) {
            if (gpu < 0.25) {
                widgets.gpu.gotoAndStop(2);
            }
            else if (gpu < 0.75) {
                widgets.gpu.gotoAndStop(3);
            }
            else {
                widgets.gpu.gotoAndStop(4);
            }
        }
        // OBSERVER NAME
        if (widgets.observerName instanceof TextField) {
            widgets.observerName.text = observerName;
            widgets.observerName._visible = true;
        }
    }

    private function tryAttachMovie(symbol: String, name: String): MovieClip {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryAttachMovie] ";
        if (!_apt[name] || !(_apt[name] instanceof MovieClip)) {
            // TODO: import instead of referencing global
            // need to rework the defaultscript.cs and reorganize the code,
            // putting all .fla files into a single folder
            var nextDepth: Number = _global.Ra3BattleNet.Utils.getNextHighestDepth(_apt);
            var attached: MovieClip = _apt.attachMovie(symbol, name, nextDepth);
            trace(TRACE_PREFIX + "Symbol " + symbol + " attached as " + name + " at depth " + nextDepth + " -> " + attached);
        }
        trace(TRACE_PREFIX + name + " is now " + _apt[name]);
        return _apt[name];
    }

    // 从 from 的坐标系转换到 _apt 的坐标系
    // 该函数假定 from 没有被旋转或者扭曲
    // 也假定我们的 _apt 没有被旋转或者扭曲
    private function convertCoordinates(from: MovieClip): Object {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::convertCoordinates] ";
        trace(TRACE_PREFIX + "Converting coordinates from " + from + " to " + _apt);
        trace(TRACE_PREFIX + "from._x: " + from._x + " from._y: " + from._y);
        trace(TRACE_PREFIX + "from._width: " + from._width + " from._height: " + from._height);
        var zero: Object = new Object();
        zero.x = 0;
        zero.y = 0;
        var size: Object = new Object();
        size.x = from._width;
        size.y = from._height;
        from.localToGlobal(zero);
        from.localToGlobal(size);
        trace(TRACE_PREFIX + "global zero: " + zero.x + ", " + zero.y);
        trace(TRACE_PREFIX + "global size: " + size.x + ", " + size.y);
        _apt.globalToLocal(zero);
        _apt.globalToLocal(size);
        trace(TRACE_PREFIX + "local zero: " + zero.x + ", " + zero.y);
        trace(TRACE_PREFIX + "local size: " + size.x + ", " + size.y);
        zero.width = size.x - zero.x;
        zero.height = size.y - zero.y;
        trace(TRACE_PREFIX + "local zero: " + zero.x + ", " + zero.y + ", " + zero.width + ", " + zero.height);
        return zero;
    }
}