import Ra3BattleNet.VirtualListElement;

class Ra3BattleNet.VirtualList {
    private static var CLASS_NAME = "Ra3BattleNet.VirtualList";

    public function patch() {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::patch] ";
        trace(TRACE_PREFIX + "Start")
        var listBoxPrototype = _global.std_mouseScrollingListBox.prototype;
        trace(listBoxPrototype.refreshDisplay)
        if (listBoxPrototype.original_refreshDisplay != undefined) {
            trace(TRACE_PREFIX + "Already patched")
            return;
        }
        if (listBoxPrototype.newRefreshDisplay != undefined) {
            trace(TRACE_PREFIX + "Already patched")
            return;
        }
        listBoxPrototype.original_refreshDisplay = listBoxPrototype.refreshDisplay;
        listBoxPrototype.refreshDisplay = refreshDisplay;
        listBoxPrototype.newRefreshDisplay = newRefreshDisplay;
        trace(TRACE_PREFIX + "Finish")
    }

    public function refreshDisplay() {
        var self = this;
        if (!self.proper_refreshDisplay) {
            var TRACE_PREFIX: String = "[" + CLASS_NAME + "::refreshDisplay@" + self + "] ";
            trace(TRACE_PREFIX + "Found a new list: " + self)
            var name = String(self._name.split(".").pop());
            if (name != "mapList" && name != "playerListTextBox") {
                trace(TRACE_PREFIX + "new list does not need to be patched")
                self.proper_refreshDisplay = self.original_refreshDisplay;
            }
            else {
                trace(TRACE_PREFIX + "new list needs to be patched")
                var virtualListPrototype = Ra3BattleNet.VirtualList.prototype;
                self.materializeVisibleItems = virtualListPrototype.materializeVisibleItems;
                trace(TRACE_PREFIX + "Patching refreshScrollbar")
                self.original_refreshScrollbar = self.refreshScrollbar;
                self.refreshScrollbar = virtualListPrototype.refreshScrollbar;
                trace(TRACE_PREFIX + "Patching OnScrollbarThumbUpdate")
                self.original_OnScrollbarThumbUpdate = self.OnScrollbarThumbUpdate;
                self.OnScrollbarThumbUpdate = virtualListPrototype.OnScrollbarThumbUpdate;

                self.proper_refreshDisplay = self.newRefreshDisplay;
            }
        }
        return self.proper_refreshDisplay();
    }

    public function newRefreshDisplay() {
        var self = this;
        // var TRACE_PREFIX: String = "[" + CLASS_NAME + "::newRefreshDisplay@" + self + "] ";
        // trace(TRACE_PREFIX + "Start");
        var maxColumnCount = self.getGreatestColumnDataCount();
        var entryClipsSize = self.m_entryClips.length != undefined ? self.m_entryClips.length : 0;
        self.m_numTotalEntries = Math.max(maxColumnCount, self.m_numVisibleEntries);
        var _loc8_ = 100 * self.m_scrollHeight / (self.m_contentHeight - self.m_renderHeight);
        self.m_contentHeight = 0;
        for (var i = 0; i < self.m_numTotalEntries; ++i) {
            if (i >= entryClipsSize) {
                // 创建虚拟化的列表项
                new VirtualListElement(self, i, 0, self.m_contentHeight, self.m_entryElementInfo, self.m_entryHeight);
            }
            self.m_entryClips[i].clear();
            var j = 0;
            while (i < maxColumnCount && j < self.m_dataColumnCount) {
                var _loc5_ = self.m_dataArrays[j];
                var _loc4_ = new Object();
                _loc4_.data = _loc5_[i];
                // trace(TRACE_PREFIX + "Setting data " + _loc4_.data + " for entry " + i + " and column " + j)
                self.m_entryClips[i].setElementData(j, _loc4_);
                j = j + 1;
            }
            self.m_entryClips[i].setSelected(i == self.getSelectedEntryIndex());
            self.m_entryClips[i]._y = self.m_contentHeight;
            self.m_contentHeight += self.m_entryClips[i].getHeight() + self.m_vPadding;
            // trace(TRACE_PREFIX + "_y = " + self.m_entryClips[i]._y + " for entry " + i + ", next contentHeight = " + self.m_contentHeight)
        }
        i = entryClipsSize - 1;
        while(i >= self.m_numTotalEntries) {
            // trace(TRACE_PREFIX + "Removing entry clip " + i)
            self.m_entryClips[i].removeMovieClip();
            self.m_entryClips.pop();
            i = i - 1;
        }
        // 实例化所有可见的虚拟列表项
        self.materializeVisibleItems();
        if (self.m_numTotalEntries > 0) {
            // 实例化最后一个虚拟列表项，以便可以获取外面容器的高度
            self.m_entryClips[self.m_numTotalEntries - 1].materialize();
        }
        self.OnScrollbarThumbUpdate(_loc8_);
        self.m_clipAnchor._x = 0;
        self.m_clipAnchor._y = - self.m_scrollHeight;
        // trace(TRACE_PREFIX + "Finish");
    }

    // 调用此函数以实例化所有可见的虚拟列表项，并虚拟化所有不可见的实体列表项
    public function materializeVisibleItems() {
        var self = this;
        // var TRACE_PREFIX: String = "[" + CLASS_NAME + "::materializeVisibleItems@" + self + "] ";
        // trace(TRACE_PREFIX + "Start Materialize, m_clipAnchor._y = " + self.m_clipAnchor._y + ", m_renderHeight = " + self.m_renderHeight)
        for (var i = 0; i < self.m_numTotalEntries; ++i) {
            var currentTop = self.m_clipAnchor._y + self.m_entryClips[i]._y;
            var currentBottom = currentTop + self.m_entryClips[i].getHeight();
            if (currentBottom < 0) {
                if (!self.m_entryClips[i].isVirtual) {
                    // check if it can be virtualized
                    if (self.m_entryClips[i].virtualize) {
                        self.m_entryClips[i].virtualize();
                    }
                }
                // trace(TRACE_PREFIX + "Skipping entry because y: " + currentBottom + " < 0")
                continue;
            }
            if (currentTop > self.m_renderHeight) {
                if (!self.m_entryClips[i].isVirtual) {
                    // check if it can be virtualized
                    if (self.m_entryClips[i].virtualize) {
                        self.m_entryClips[i].virtualize();
                    }
                }
                continue;
            }
            if (self.m_entryClips[i].isVirtual) {
                self.m_entryClips[i].materialize();
            }
        }
        // trace(TRACE_PREFIX + "Finish Materialize")
    }

    public function refreshScrollbar() {
        var self = this;
        self.materializeVisibleItems();
        self.original_refreshScrollbar();
    }

    public function OnScrollbarThumbUpdate(percentage) {
        var self = this;
        self.original_OnScrollbarThumbUpdate(percentage);
        self.materializeVisibleItems();
    }
}