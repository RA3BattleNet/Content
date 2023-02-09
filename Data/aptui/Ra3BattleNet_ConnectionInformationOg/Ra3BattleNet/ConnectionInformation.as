class Ra3BattleNet.ConnectionInformation {
    public function init(obj)
    {
        obj.names = new Array(5);
        obj.names[0] = obj.playerName1;
        obj.names[1] = obj.playerName1;
        obj.names[2] = obj.playerName1;
        obj.names[3] = obj.playerName1;
        obj.names[4] = obj.playerName1;
        obj.networks = new Array(5);
        obj.networks[0] = null;
        obj.networks[1] = null;
        obj.networks[2] = null;
        obj.networks[3] = null;
        obj.networks[4] = null;
        obj.cpus = new Array(5);
        obj.cpus[0] = null;
        obj.cpus[1] = null;
        obj.cpus[2] = null;
        obj.cpus[3] = null;
        obj.cpus[4] = null;
        obj.gpus = new Array(5);
        obj.gpus[0] = null;
        obj.gpus[1] = null;
        obj.gpus[2] = null;
        obj.gpus[3] = null;
        obj.gpus[4] = null;

        obj.idCounter = 1;
    }

    public function onEnterFrame(obj)
    {
        var ret = new Object();
        loadVariables("Ra3BattleNet_ConnectionInformation",ret);
        size = Number(ret.size);
        var names: Array = new Array();
        names = ret.names.split(",");
        latencies = ret.latencies.split(",");
        packetLosses = ret.packetLosses.split(",");
        
        for (i = 0; i < 5; i++)
        {
            clearInfo(i);
            if (i < index)
            {
                obj.updateInfo(i, names[i], Number(latencies[i]), Number(packetLosses[i]), null, null);
            }
        }
    }

    public function updateInfo(obj, index, name, latency, loss, cpu, gpu)
    {
        // x = 165 195 235
        // y = 5 + index * 30

        obj.names[index].text = name;
        // latency > 990ms, the connection may lost already
        // loss > 0.1, too bad
        if (latency > 0.99 || loss > 0.1)
        {
            obj.networks[index] = obj.attachMovie("NetworkSymbol1", "ID", obj.idCounter++);
            obj.networks[index]._x = 165;
            obj.networks[index]._y = 5 + index * 30;
        }
        // latency > 300ms
        // there is a loss!
        else if (loss > 0 || latency > 300)
        {
            obj.networks[index] = obj.attachMovie("NetworkSymbol2", "ID", obj.idCounter++);
            obj.networks[index]._x = 165;
            obj.networks[index]._y = 5 + index * 30;
        }
        else
        {
            obj.networks[index] = obj.attachMovie("NetworkSymbol3", "ID", obj.idCounter++);
            obj.networks[index]._x = 165;
            obj.networks[index]._y = 5 + index * 30;
        }
    }

    public function clearInfo(obj, index)
    {
        obj.names[index].text = "----";
        if (obj.networks[index] != null)
        {
            removeMovieClip(obj.networks[index]);
            obj.networks[index] = null;
        }
        if (obj.cpus[index] != null)
        {
            removeMovieClip(obj.cpus[index]);
            obj.cpus[index] = null;
        }
        if (obj.gpus[index] != null)
        {
            removeMovieClip(obj.gpus[index]);
            obj.gpus[index] = null;
        }
    }
}