class Ra3BattleNet.ConnectionInformation {
    private static var CLASS_NAME: String = "Ra3BattleNet.ConnectionInformation";
    private static var INGAME_NETWORK_SYMBOL: String = "InGameNetworkSymbol";
    private static var OUTGAME_NETWORK_SYMBOL: String = "OutGameNetworkSymbol";
    private static var CPU_SYMBOL: String = "CpuSymbol";
    private static var GPU_SYMBOL: String = "GpuSymbol";
    private static var OBSERVER_PANEL_SYMBOL: String = "InGameObserverPanel";

    private static var _instance: ConnectionInformation;
    private static var _apt: MovieClip;
    private var _updateCounter: Number;
    private var _widgets: Array;
    private var _isInGame: Boolean;
    private var _observerIndex: Number;

    public function ConnectionInformation(apt: MovieClip) {
        if (_instance) {
            trace("[" + CLASS_NAME + "::ConnectionInformation] instance already exists: " + _instance);
            return;
        }
        _instance = this;
        _apt = apt;
        _updateCounter = 0;
        _apt.onEnterFrame = _global.bind0(this, update);
        // 下面这代码实在是太诡异了，但也只能这样了
        _global.gSM.setOnExitScreen(_global.bind1(this, function(previousOnExitScreen: Function) {
            unload();
            if(String(previousOnExitScreen) == "[function]" || previousOnExitScreen != null) {
                trace("[" + CLASS_NAME + "::onExitScreen] calling previous onExitScreen");
                previousOnExitScreen.call(_global.gSM);
            }
        }, _global.gSM.m_onExitScreenFunc));
    }

    private function unload(): Void {
        trace("[" + CLASS_NAME + "::unload] apt unloading");
        delete _widgets;
        delete _apt.onEnterFrame;
        delete _apt.onUnload;
        delete _apt;
        delete _instance;
        delete _global.Ra3BattleNet.ConnectionInformation;
        trace("[" + CLASS_NAME + "::unload] apt unloaded");
    }

    private function update(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::update] ";
        // 不需要每帧更新
        if (_updateCounter > 0) {
            --_updateCounter;
            return;
        }
        _updateCounter = 10;

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
        /// trace(TRACE_PREFIX + "name and widgets availaible");
        var names: Array = query.names.split(",");
        var latencies: Array = query.latencies.split(",");
        var packetLosses: Array = query.packetLosses.split(",");
        var logicScores: Array = query.logicScores.split(",");
        var renderScores: Array = query.renderScores.split(",");
        /// trace(TRACE_PREFIX + "ingame: " + _isInGame);
        if (_isInGame) {
            var isPlaying: Array = query.isPlaying.split(",");
            /// trace(TRACE_PREFIX + "isPlaying: " + isPlaying);
            // playing players are always on top
            var i: Number = 0;
            var j: Number = 0;
            while (i < _widgets.length && j < isPlaying.length) {
                if (isPlaying[j] === "0") {
                    ++j;
                    continue;
                }
                /// // observer name are temporarily shown for debugging
                /// // otherwise it should be null
                /// var observerName: String = String(String.fromCharCode.apply(String, names[j].split("_")));
                /// trace(TRACE_PREFIX + "inside game - player " + i + " is playing, debug name: " + observerName);
                updateWidgets(
                    i, null, !!names[j],
                    Number(latencies[j]), Number(packetLosses[j]),
                    Number(logicScores[j]), Number(renderScores[j])
                );
                ++i;
                ++j;
            }
            // if there are some non-playing players (observers), show them at the bottom
            // hide if there are no observers with data
            _apt[OBSERVER_PANEL_SYMBOL]._visible = false;
            j = 0;
            while (i < _widgets.length && j < isPlaying.length) {
                if (isPlaying[j] === "1") {
                    ++j;
                    continue;
                }
                if (!names[j]) {
                    /// trace(TRACE_PREFIX + "inside game - player " + i + " is not playing, no data");
                    ++j;
                    continue;
                }
                _apt[OBSERVER_PANEL_SYMBOL]._visible = true;
                var observerName: String = String(String.fromCharCode.apply(String, names[j].split("_")));
                /// trace(TRACE_PREFIX + "inside game - player " + i + " is not playing, observerName name: " + observerName);
                updateWidgets(
                    i, observerName, true,
                    Number(latencies[j]), Number(packetLosses[j]),
                    Number(logicScores[j]), Number(renderScores[j])
                );
                ++i;
                ++j;
            }
        }
        else {
            for (var i: Number = 0; i < _widgets.length; ++i) {
                updateWidgets(
                    i, null, !!names[i],
                    Number(latencies[i]), Number(packetLosses[i]),
                    Number(logicScores[i]), Number(renderScores[i])
                );
            }
        }
    }

    private function requestWidgets(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::requestWidgets] ";
        if (_widgets) {
            /// trace(TRACE_PREFIX + "widgets already exist");
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
        if (!playerApts || typeof(playerApts[0]) !== "movieclip") {
            playerApts = screenInstance.m_playerLineMCs;
            if (!playerApts || typeof(playerApts[0]) !== "movieclip") {
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
            if (typeof(playerApt) !== "movieclip") {
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
        // 函数参数 playerApt 是指暂停菜单里那个显示玩家信息的 MovieClip
        // 我们的连接状态信息将显示在这个 MovieClip 的右侧
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createInGameWidgets] ";

        var x: Number = 0;
        var horizontalMiddle: Number = 0;
        var padding: Number = 8;
        var result = new Object();
        // 在玩家的状态（“战败”）的右边显示连接状态
        // var color: MovieClip = playerApt.colorMC;
        var status: MovieClip = playerApt.statusMC;
        if (typeof(status) !== "movieclip") {
            // something is wrong
            trace(TRACE_PREFIX + "status movie clip not found in " + playerApt);
            return null;
        }
        var statusRect: Object = convertCoordinates(status);
        // 实在是没想到连接状态居然占了整行，所以我们只能从覆盖在连接状态的上方
        // 并从右向左排列，以避免遮挡连接状态的文本
        x = statusRect.x + statusRect.width;
        if (!playerApt._visible) {
            // 假如 playerApt 不可见，我们就创建一个面板来显示信息
            trace(TRACE_PREFIX + "player apt " + index + " is not visible");
            var panel: MovieClip = getInGameObserverPanel(playerApt, index);
            var observerName: MovieClip = panel["observer" + (index - _observerIndex)];
            var observerRect: Object = convertCoordinates(observerName);
            horizontalMiddle = observerRect.y + observerRect.height * 0.5;
            result.observerName = observerName.textField;
            trace(TRACE_PREFIX + "player " + index + " has " + observerName);
        }
        else {
            horizontalMiddle = statusRect.y + statusRect.height * 0.5;
        }

        function appendWidget(symbol: String) {
            var widget: MovieClip = tryAttachMovie(symbol, index);
            x -= widget._width;
            widget._x = x;
            widget._y = horizontalMiddle - widget._height * 0.5;
            x -= padding;
            // ingame widgets aren't visible by default
            widget._visible = false;
            widget.stop();
            trace(TRACE_PREFIX + symbol + " created as " + widget);
            return widget;
        }

        result.gpu = appendWidget(GPU_SYMBOL);
        result.cpu = appendWidget(CPU_SYMBOL);
        result.network = appendWidget(INGAME_NETWORK_SYMBOL);
        /// // only for debugging!
        /// if (!result.observerName) {
        ///     _apt.createTextField("debug" + index, _apt.getNextHighestDepth(), x, horizontalMiddle - 10 + result.gpu._height, 100, 20);
        ///     var debug: TextField = _apt["debug" + index];
        ///     trace(TRACE_PREFIX + "debug text field created at depth " + debug.getDepth() + " as " + debug);
        ///     debug.setTextFormat(_global.std_config.textBox_textFormat_highlight);
        ///     debug.text = "debug";
        ///     debug.textColor = 0x00FF00;
        ///     result.observerName = debug;
        /// }
        return result;
    }

    private function getInGameObserverPanel(playerApt: MovieClip, index: Number): MovieClip {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::getInGameObserverPanel] ";
        var panel: MovieClip = _apt[OBSERVER_PANEL_SYMBOL];
        if (typeof(panel) === "movieclip") {
            return panel;
        }
        // create observer panel at playerApt's position
        panel = _apt.attachMovie(
            OBSERVER_PANEL_SYMBOL,
            OBSERVER_PANEL_SYMBOL,
            _apt.getNextHighestDepth()
        );
        var playerAptRect: Object = convertCoordinates(playerApt);
        panel._x = playerAptRect.x;
        panel._y = playerAptRect.y;
        for (var i: Number = 0; i < 6; ++i) {
            var observerName: MovieClip = panel["observer" + i];
            observerName.textField._visible = false;
        }
        _observerIndex = index;
        trace(TRACE_PREFIX + "observer panel created at index " + _observerIndex);
        return panel;
    }

    private function createOutGameWidgets(playerApt: MovieClip, index: Number): Object {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createOutGameWidgets] ";

        var voip: MovieClip = playerApt.voipCheckBox;
        if (typeof(voip) !== "movieclip") {
            trace(TRACE_PREFIX + "voip check box not found in " + playerApt);
            return null;
        }
        var mute: MovieClip = playerApt.muteCheckBox;
        if (typeof(mute) !== "movieclip") {
            trace(TRACE_PREFIX + "mute check box not found in " + playerApt);
            return null;
        }

        trace(TRACE_PREFIX + _apt + " x/y: " + _apt._x + "/" + _apt._y);
        var voipRect: Object = convertCoordinates(voip);
        var muteRect: Object = convertCoordinates(mute);

        var network: MovieClip = tryAttachMovie(OUTGAME_NETWORK_SYMBOL, index);
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

        var cpu: MovieClip = tryAttachMovie(CPU_SYMBOL, index);
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

    private function updateWidgets(
        index: Number, name: String, hasData: Boolean,
        latency: Number, packetLoss: Number, cpu: Number, gpu: Number
    ): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::updateWidgets] ";
        if (!_widgets || !_widgets[index]) {
            /// trace(TRACE_PREFIX + "no widgets for " + index);
            return;
        }
        var widgets: Object = _widgets[index];
        /// trace(TRACE_PREFIX + index + " " + name + " " + hasData + " " + latency + " " + packetLoss + " " + cpu + " " + gpu);
        /// trace(TRACE_PREFIX + "network: " + widgets.network + " cpu: " + widgets.cpu + " gpu: " + widgets.gpu + " observerName: " + widgets.observerName);
        if (_isInGame) {
            widgets.network._visible = hasData;
            widgets.cpu._visible = hasData;
            widgets.gpu._visible = hasData;
            if (widgets.observerName) {
                widgets.observerName._visible = hasData;
                widgets.observerName.text = name;
            }
        }
        else if (!hasData) {
            widgets.network.gotoAndStop(1);
            widgets.cpu.gotoAndStop(1);
            return;
        }
        // NETWORK
        // is local player?
        // network information is meaningless for local player
        if (latency < 0 && packetLoss < 0) {
            widgets.network.gotoAndStop(1);
        }
        // player disconnected, disable everything
        else if (latency >= 1 || packetLoss >= 1) {
            widgets.network.gotoAndStop(1);
            widgets.cpu.gotoAndStop(1);
            if (widgets.gpu) {
                widgets.gpu.gotoAndStop(1);
            }
        }
        // latency > 990ms, the connection may lost already
        // packetLoss > 0.25, too bad
        else if (latency > 0.99 || packetLoss > 0.25) {
            widgets.network.gotoAndStop(2);
        }
        // latency > 400ms or packetLess > 0.1, lag!
        else if (latency > 0.4 || packetLoss > 0.15) {
            widgets.network.gotoAndStop(2);
        }
        // latency > 300ms
        // there is a loss!
        else if (latency > 0.3 || packetLoss > 0) {
            widgets.network.gotoAndStop(4);
        }
        else {
            widgets.network.gotoAndStop(5);
        }

        // 游戏逻辑计算与画面渲染
        // 分数计算公式：
        // score = 100 - (27.5 - frames_per_second) / 15 * 100;
        // - 满分是 100 分，代表帧率为 27.5 FPS 或更高
        //   也就是 CPU 计算 / 显卡渲染的耗时在 36 毫秒以内
        // - 最低为 0 分，代表帧率为 12.5 FPS 或更低
        //   也就是计算 / 渲染的耗时超过了 80 毫秒

        // GAME LOGIC LOAD
        if (cpu < 40) {
            widgets.cpu.gotoAndStop(2);
        }
        else if (cpu < 70) {
            widgets.cpu.gotoAndStop(3);
        }
        else if (cpu < 90) {
            widgets.cpu.gotoAndStop(4);
        }
        else {
            widgets.cpu.gotoAndStop(5);
        }
        // GAME RENDER LOAD
        if (widgets.gpu) {
            if (gpu < 40) {
                widgets.gpu.gotoAndStop(2);
            }
            else if (gpu < 70) {
                widgets.gpu.gotoAndStop(3);
            }
            else if (gpu < 90) {
                widgets.gpu.gotoAndStop(4);
            }
            else {
                widgets.gpu.gotoAndStop(5);
            }
        }
    }

    private static function tryAttachMovie(symbol: String, id: Number): MovieClip {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::tryAttachMovie] ";
        var name: String = symbol + id;
        if (typeof(_apt[name]) !== "movieclip") {
            // TODO: import instead of referencing global
            // need to rework the defaultscript.cs and reorganize the code,
            // putting all .fla files into a single folder
            var nextDepth: Number = _apt.getNextHighestDepth();
            var attached: MovieClip = _apt.attachMovie(symbol, name, nextDepth);
            trace(TRACE_PREFIX + "Symbol " + symbol + " attached as " + name + " at depth " + nextDepth + " -> " + attached);
        }
        trace(TRACE_PREFIX + name + " is now " + _apt[name]);
        return _apt[name];
    }

    // 从 from 的坐标系转换到 _apt 的坐标系
    // 该函数假定 from 没有被旋转或者扭曲
    // 也假定我们的 _apt 没有被旋转或者扭曲
    private static function convertCoordinates(from: MovieClip): Object {
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
