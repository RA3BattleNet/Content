class Ra3BattleNet.ConnectionInformation {
	static var NETWORK_ID: String = "Ra3BattleNetConnectionInformationNetwork";
	static var CPU_ID: String = "Ra3BattleNetConnectionInformationCpu";
	static var GPU_ID: String = "Ra3BattleNetConnectionInformationGpu";
	static var OBSERVER_PANEL_ID: String = "Ra3BattleNetConnectionInformationObserverPanel";

	private var _widgets: Array;
	private var _isInGame: Boolean;

	public function ConnectionInformation(apt: MovieClip) {
		apt.onEnterFrame = _global.bind0(this, update);
	}

	private function update() {
		var query: Object = new Object();
		loadVariables("Ra3BattleNet_ConnectionInformation", query);
		if (!query.names) {
			return;
		}
		refreshWidgets();
		if (!_widgets) {
			return;
		}
		var latencies: Array = query.latencies.split(",");
		var packetLosses: Array = query.packetLosses.split(",");
		var logicLoads: Array = query.logicLoads.split(",");
		var renderLoads: Array = query.renderLoads.split(",");
		if (_isInGame) {
			var names: Array = query.names.split(",");
			var isPlaying: Array = query.isPlaying.split(",");
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
					resetWidgets(i);
				}
				else {
					showWidgets(i, Number(latencies[i]), Number(packetLosses[i]), 1, 1, null);
				}
			}
		}
	}

	private function refreshWidgets(): Void {
		removeOutdatedWidgets();
		if (_widgets) {
			return;
		}
		if (!_global.Cafe2_BaseUIScreen) {
			return;
		}
		var screenInstance = _global.Cafe2_BaseUIScreen.m_thisClass;
		if (!screenInstance) {
			return;
		}
		_isInGame = false;
		var playerApts: Array = screenInstance.m_playerSlots;
		if (!playerApts || !(playerApts[0] instanceof MovieClip)) {
			playerApts = screenInstance.m_playerLineMCs;
			if (!playerApts || !(playerApts[0] instanceof MovieClip)) {
				return;
			}
			// campaign pause menu has no player count
			if (!screenInstance.m_playerCount) {
				return;
			}
			_isInGame = true;
		}
		var result: Array = new Array();
		for (var i: Number = 0; i < playerApts.length; ++i) {
			var playerApt: MovieClip = playerApts[i];
			if (!(playerApt instanceof MovieClip)) {
				// something is wrong
				return;
			}
			var widgets: Object = _isInGame
				? tryConstructInsideGame(playerApt)
				: tryConstructOutsideGame(playerApt);
			if (widgets) {
				result.push(widgets);
			}
			
		}
		if (result.length == 0) {
			return;
		}
		_widgets = result;
	}

	private function removeOutdatedWidgets(): Void {
		if (!_widgets) {
			return;
		}

		var isCachedwidgetsValid: Boolean = false;
		for (var i: Number = 0; i < _widgets.length; ++i) {
			var current: Object = _widgets[i];
			if (!current) {
				isCachedwidgetsValid = false;
				break;
			}
			var network: MovieClip = current.network;
			if (!(network instanceof MovieClip)) {
				isCachedwidgetsValid = false;
				break;
			}
			isCachedwidgetsValid = true;
		}

		if (isCachedwidgetsValid) {
			return;
		}

		// clear old render targets
		for (var i: Number = 0; i < _widgets.length; ++i) {
			var current: Object = _widgets[i];
			if (!current) {
				continue;
			}
			for (var k: String in current) {
				if (current[k] instanceof MovieClip) {
					current[k].removeMovieClip();
				}
			}
		}
		delete _widgets;
	}

	private function tryConstructInsideGame(playerApt: MovieClip, index: Number): Object {
		var x: Number = 0;
		var horizontalMiddle: Number = 0;
		var padding: Number = 8;
		var result = new Object();
		// the player apt is the movieclip which contains player's information
		// our connection information is also "player's information"
		if (!playerApt._visible) {
			// if the player apt is not visible,
			// we create a panel to show our information
			if (!(playerApt._parent[OBSERVER_PANEL_ID] instanceof MovieClip)) {
				playerApt._parent.attachMovie(
					"InGameObserverPanel",
					OBSERVER_PANEL_ID,
					getNextHighestDepth(playerApt._parent)
				);
				var panel: MovieClip = playerApt._parent[OBSERVER_PANEL_ID];
				panel._x = playerApt._x;
				panel._y = playerApt._y;
				// now consider the panel as the player apt
				playerApt = panel;
				for (var i: Number = 0; i < 6; ++i) {
					var observerName: TextField = playerApt["observer" + String(i + 1)];
					observerName._visible = false;
				}
			}
			var observerName: TextField = playerApt["observer" + String(index + 1)];
			observerName._visible = true;
			x = observerName._x + observerName._width + padding;
			horizontalMiddle = observerName._y + observerName._height * 0.5;
			result.observerName = observerName;
		}
		else {
			var color: MovieClip = playerApt.colorMC;
			if (!color || !(color instanceof MovieClip)) {
				// something is wrong
				return null;
			}
			x = color._x + color._width + padding;
			horizontalMiddle = color._y + color._height * 0.5;
		}
		
		function appendMovie(symbol: String, id: String) {
			var movie: MovieClip = tryAttachMovie(playerApt, symbol, id);
			movie._x = x;
			movie._y = horizontalMiddle - movie._height * 0.5;
			x += movie._width;
			x += padding;
			return movie;
		}

		result.network = appendMovie("NetworkSymbol", NETWORK_ID);
		result.cpu = appendMovie("CpuSymbol", CPU_ID);
		result.gpu = appendMovie("GpuSymbol", GPU_ID);
		// only for debugging!
		if (!result.observerName) {
			playerApt.createTextField("debug", getNextHighestDepth(playerApt), x, horizontalMiddle - 10, 100, 20);
			var debug: TextField = playerApt.debug;
			debug.setTextFormat(_global.std_config.textBox_textFormat_highlight);
			debug.text = "debug";
			result.observerName = debug;
		}
		return result;
	}

	private function tryConstructOutsideGame(playerApt: MovieClip): Object {
		var voip: MovieClip = playerApt.voipCheckBox;
		if (!voip || !(voip instanceof MovieClip)) {
			return null;
		}
		var mute: MovieClip = playerApt.muteCheckBox;
		if (!mute || !(mute instanceof MovieClip)) {
			return null;
		}

		var network: MovieClip = tryAttachMovie(playerApt, "NetworkSymbol", NETWORK_ID);
		network._width = voip._width * 1.1;
		network._height = voip._height * 1.1;
		network._x = voip._x + voip._width * 0.5 - network._width * 0.5;
		network._y = voip._y + voip._height * 0.5 - network._height * 0.5;

		var cpu: MovieClip = tryAttachMovie(playerApt, "CpuSymbol", CPU_ID);
		cpu._width = mute._width * 1.1;
		cpu._height = mute._height * 1.1;
		cpu._x = mute._x + mute._width * 0.5 - cpu._width * 0.5;
		cpu._y = mute._y + mute._height * 0.5 - cpu._height * 0.5;

		var result = new Object();
		result.network = network;
		result.cpu = cpu;
		result.gpu = null;
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
			return;
		}
		var widgets: Object = _widgets[index];
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

	private static function tryAttachMovie(
		playerApt: MovieClip, symbol: String, name: String
	): MovieClip {
		if (!playerApt[name] || !(playerApt[name] instanceof MovieClip)) {
			playerApt.attachMovie(symbol, name, getNextHighestDepth(playerApt));
		}
		return playerApt[name];
	}

	private static function getNextHighestDepth(parent: MovieClip): Number {
        var depth: Number = 1;
        for (var k: String in parent) {
            if (parent[k] instanceof MovieClip) {
                var mc: MovieClip = parent[k];
                mc.getDepth();
                if (mc._depth >= depth) {
                    depth = mc._depth + 1;
                }
            }
        }
        return depth;
    }
}