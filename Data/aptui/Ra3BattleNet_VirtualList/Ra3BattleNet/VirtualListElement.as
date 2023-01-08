class Ra3BattleNet.VirtualListElement {
    public var isVirtual = true;
    private var _listbox;
    private var _index: Number;
    public var _x: Number;
    public var _y: Number;
    private var _getWidth: Number;
    private var _getHeight: Number;
    private var _entryElementInfo;
    private var _entryHeight;
    private var _delayedCalls;
    private var _data;
    private var _elementData;
    private var _eventListeners;

    public function VirtualListElement(listbox, index, x, y, entryElementInfo, entryHeight) {
        _listbox = listbox;
        _index = index;
        _listbox.m_entryClips[_index] = this;
        _x = x;
        _y = y;
        _entryElementInfo = entryElementInfo;
        _entryHeight = entryHeight;
        _delayedCalls = new Array();
        _data = null;
        _elementData = new Array();
        _eventListeners = new Array();

        if (_listbox.templateGetWidth == undefined || _listbox.templateGetHeight == undefined) {
            trace("VirtualListElement: templateGetWidth or templateGetHeight not defined, materializing to get size");
            var real = materialize();
            _listbox.templateGetWidth = real.getWidth();
            _listbox.templateGetHeight = real.getHeight();
            real.virtualize();
        }
        
        _getWidth = _listbox.templateGetWidth;
        _getHeight = _listbox.templateGetHeight;
    }

    public function materialize() {
        trace("Materializing " + _index);
        var virtual = this;
        var materialized: MovieClip = _listbox.createEntryClip(
            _index,
            _x,
            _y,
            _entryElementInfo,
            _entryHeight
        );
        trace("Materializing " + _listbox + "." + _index + ", entry clip created as " + materialized);
        materialized._x = _x;
        materialized._y = _y;
        _listbox.m_entryClips[_index] = materialized;
        trace("Materializing " + _index + ", calling " + _delayedCalls.length + " delayed calls");
        for (var i = 0; i < _delayedCalls.length; ++i) {
            var call = _delayedCalls[i];
            trace("Materializing " + _index + ", calling " + call.f)
            var f = materialized[call.f];
            var arg = call.arg;
            var arg1 = call.arg1;
            var arg2 = call.arg2;
            if (arg != undefined) {
                f.call(materialized, arg);
            } else if (arg1 != undefined || arg2 != undefined) {
                f.call(materialized, arg1, arg2);
            } else {
                f.call(materialized);
            }
        }
        trace("Materialized");
        if (!materialized.virtualize) {
            materialized.virtualize = function() {
                trace("Virtualizing " + virtual._index + " which is " + materialized);
                virtual._listbox.m_entryClips[virtual._index] = virtual;
                materialized.removeMovieClip();
                trace("Virtualized");
            }
        }
        return materialized;
    }

    public function removeMovieClip() {
        _delayedCalls.push({ f: "removeMovieClip" });
    }
    public function shutdown() {
        _delayedCalls.push({ f: "shutdown" });
    }
    public function clear() {
        _delayedCalls = new Array();
        _delayedCalls.push({ f: "clear" });
    }
    public function getWidth() {
        return _getWidth;
    }
    public function getHeight() {
        return _getHeight;
    }
    public function setElementData(column, data) {
        _delayedCalls.push({ f: "setElementData", arg1: column, arg2: data });
        _elementData = [column, data.data];
    }
    public function setData(data) {
        _delayedCalls.push({ f: "setData", arg: data });
        _data = data;
    }
    public function getData() {
        return _data;
    }
    public function setVisualProperties(visualProperties) {
        _delayedCalls.push({ f: "setVisualProperties", arg: visualProperties });
    }
    public function setHighlighted(highlighted) {
        if (highlighted) {
            materialize().setHighlighted(highlighted)
        }
    }
    public function setSelected(selected) {
        if (selected) {
            materialize().setSelected(selected)
        }
    }
    public function realizeHighlightState() {}
    public function setBackgroundColor(color) {
        _delayedCalls.push({ f: "setBackgroundColor", arg: color });
    }
    public function addListener(listener) {
        _delayedCalls.push({ f: "addListener", arg: listener });
    }
    public function removeListener(listener) {
        _delayedCalls.push({ f: "removeListener", arg: listener });
    }
    public function OnListboxEntryElementMouseEnter(element) {
        this.OnMouseEnter();
    }
    public function OnListboxEntryElementMouseExit(element) {
        this.OnMouseExit();
    }
    public function OnListboxEntryElementMouseClick(element){
        return materialize().OnListboxEntryElementMouseClick(element);
    }
    public function OnMouseEnter() { return materialize().OnMouseEnter(); }
    public function OnMouseExit() { return materialize().OnMouseExit(); }
    public function OnMouseClick() { return materialize().OnMouseClick(); }
    public function bind0(o, f) { return function() { f.call(o); }; }
    public function broadcastOnListboxEntryMouseEnter(entry) {
        return materialize().broadcastOnListboxEntryMouseEnter(entry);
    }
    public function broadcastOnListboxEntryMouseExit(entry) {
        return materialize().broadcastOnListboxEntryMouseExit(entry);
    }
    public function broadcastOnListboxEntryMouseClick(entry) {
        return materialize().broadcastOnListboxEntryMouseClick(entry);
    }
    public function broadcastOnListboxEntryElementMouseEnter(id) {
        return materialize().broadcastOnListboxEntryElementMouseClick(id);
    }
    public function broadcastOnListboxEntryElementMouseExit(id) {
        return materialize().broadcastOnListboxEntryElementMouseExit(id);
    }
    public function broadcastOnListboxEntryElementMouseClick(id) {
        return materialize().broadcastOnListboxEntryElementMouseClick(id);
    }
}