class Ra3BattleNet.ConnectionInformationOg {
    private var obj: MovieClip;
    // public var names: Array;
    public var networks: Array;
    public var cpus: Array;
    // public var gpus: Array;

	public function ConnectionInformationOg(apt: MovieClip) {
		this.obj = apt.attachMovie("ConnectionInformationOg", "ID", 1);
		this.obj._x = 0;
		this.obj._y = 0;

		var self = this;
		this.obj.onEnterFrame = function() {
			self.onEnterFrame()
		}
		
		// this.names = new Array(6);
		// this.names[0] = this.obj.playerName1;
		// this.names[1] = this.obj.playerName2;
		// this.names[2] = this.obj.playerName3;
		// this.names[3] = this.obj.playerName4;
		// this.names[4] = this.obj.playerName5;
		// this.names[5] = this.obj.playerName6;
		this.networks = new Array(6);
		this.networks[0] = this.obj.network1;
		this.networks[1] = this.obj.network2;
		this.networks[2] = this.obj.network3;
		this.networks[3] = this.obj.network4;
		this.networks[4] = this.obj.network5;
		this.networks[5] = this.obj.network6;
		this.cpus = new Array(6);
		this.cpus[0] = this.obj.cpu1;
		this.cpus[1] = this.obj.cpu2;
		this.cpus[2] = this.obj.cpu3;
		this.cpus[3] = this.obj.cpu4;
		this.cpus[4] = this.obj.cpu5;
		this.cpus[5] = this.obj.cpu6;
		// this.gpus = new Array(6);
		// this.gpus[0] = this.obj.gpu1;
		// this.gpus[1] = this.obj.gpu2;
		// this.gpus[2] = this.obj.gpu3;
		// this.gpus[3] = this.obj.gpu4;
		// this.gpus[4] = this.obj.gpu5;
		// this.gpus[5] = this.obj.gpu6;
	}

	public function isInMultiplayerLobby() {
		if (!_global.Cafe2_BaseUIScreen) {
			return false;
		}
		if (!_global.Cafe2_BaseUIScreen.m_thisClass == null) {
			return false;
		}
		if (!_global.Cafe2_BaseUIScreen.m_thisClass.m_playerSlots == null) {
			return false;
		}
		if (!_global.Cafe2_BaseUIScreen.m_thisClass.m_playerSlots[0] == null) {
			return false;
		}
		if (!_global.Cafe2_BaseUIScreen.m_thisClass.m_playerSlots[0].voipCheckBox == null) {
			return false;
		}
		if (!_global.Cafe2_BaseUIScreen.m_thisClass.m_playerSlots[0].muteCheckBox == null) {
			return false;
		}
		return true;
	}

	public function setPosition(index) {
		var voip = _global.Cafe2_BaseUIScreen.m_thisClass.m_playerSlots[index].voipCheckBox;
		var xy = new Object();
		xy.x = 0;
		xy.y = 0;
		voip.localToGlobal(xy);
		var wh = new Object();
		wh.x = voip._width;
		wh.y = voip._height;
		voip.localToGlobal(wh);

		this.networks[index]._width = 1.1 * (wh.x - xy.x);
		this.networks[index]._height = wh.y - xy.y;
		this.networks[index]._x = xy.x - 0.5 * this.networks[index]._width;
		this.networks[index]._y = xy.y - 0.5 * this.networks[index]._height;
		
		var mute = _global.Cafe2_BaseUIScreen.m_thisClass.m_playerSlots[index].muteCheckBox;
		xy.x = 0;
		xy.y = 0;
		mute.localToGlobal(xy);
		wh.x = mute._width;
		wh.y = mute._height;
		mute.localToGlobal(wh);
		
		this.cpus[index]._width = 1.1 * (wh.x - xy.x);
		this.cpus[index]._height = wh.y - xy.y;
		this.cpus[index]._x = xy.x - 0.5 * this.cpus[index]._width;
		this.cpus[index]._y = xy.y - 0.5 * this.cpus[index]._height;
	}

	public function clearInfo(index) {
		// this.names[index].text = "----";
		this.networks[index].gotoAndStop(1);
		this.cpus[index].gotoAndStop(1);
		// this.gpus[index].gotoAndStop(1);
	}

	public function updateInfo(index, name, latency, loss, cpu, gpu) {
		// this.names[index].text = name + "|" + Math.round(latency * 1000) + "|" + Math.round(loss * 100);
		// latency > 990ms, the connection may lost already
		// loss > 0.1, too bad
		if (latency > 0.99 || loss > 0.1) {
			this.networks[index].gotoAndStop(2);
		}
		// latency > 300ms
		// there is a loss!
		else if (latency > 0.3 || loss > 0) {
			this.networks[index].gotoAndStop(3);
		}
		else {
			this.networks[index].gotoAndStop(4);
		}
		if (cpu < 0.25) {
			this.cpus[index].gotoAndStop(2);
		}
		else if (cpu < 0.75) {
			this.cpus[index].gotoAndStop(3);
		}
		else {
			this.cpus[index].gotoAndStop(4);
		}
		// if (gpu < 0.25)
		// {
		// 	this.gpus[index].gotoAndStop(2);
		// }
		// else if (gpu < 0.75)
		// {
		// 	this.gpus[index].gotoAndStop(3);
		// }
		// else
		// {
		// 	this.gpus[index].gotoAndStop(4);
		// }
	}

	public function onEnterFrame() {
		if (!this.isInMultiplayerLobby()) {
			this.obj._visible = false;
			return;
		}
		var ret = new Object();
		loadVariables("Ra3BattleNet_ConnectionInformation", ret);
		if (ret.names == null) {
			this.obj._visible = false;
			return;
		}
		else {
			this.obj._visible = true;
		}
		var names = ret.names.split(",");
		var latencies = ret.latencies.split(",");
		var packetLosses = ret.packetLosses.split(",");
		var logicLoads = ret.logicLoads.split(",");
		var renderLoads = ret.renderLoads.split(",");
		for (var i = 0; i < 6; i++) {
			this.setPosition(i);
			if (names[i] == "") {
				this.clearInfo(i);
			}
			else {
				this.updateInfo(i, String.fromCharCode.apply(String, names[i].split("_")), Number(latencies[i]), Number(packetLosses[i]), 1, 1);
			}
		}
	}
}