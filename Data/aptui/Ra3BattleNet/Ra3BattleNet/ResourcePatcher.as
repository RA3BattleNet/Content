class Ra3BattleNet.ResourcePatcher {
    public static function tryPatchGameSetupBase() {
        var TRACE_PREFIX: String = "Ra3BattleNet.ResourcePatcher::tryPatchGameSetupBase - ";
        trace(TRACE_PREFIX + "Started");
        if (_global.GameSetupBase == null) {
            trace(TRACE_PREFIX + "GameSetupBase not loaded yet");
            return;
        }
        var gameSetupBasePrototype = _global.GameSetupBase.prototype;

        // refreshResourcesControl
        if (gameSetupBasePrototype.originalRefreshResourcesControl != undefined) {
            trace(TRACE_PREFIX + "GameSetupBase already patched");
            return;
        }
        gameSetupBasePrototype.originalRefreshResourcesControl = gameSetupBasePrototype.refreshResourcesControl;

        gameSetupBasePrototype.refreshResourcesControl = function() {
            newRefreshResourcesControl(this);
        };
        trace(TRACE_PREFIX + "GameSetupBase patched");
    }

    private static function newRefreshResourcesControl(self) {
        var TRACE_PREFIX: String = "Ra3BattleNet.ResourcePatcher::newRefreshResourcesControl - ";
        trace(TRACE_PREFIX + "Started");
        var resourcesDropdownComponent = _global.Cafe2_BaseUIScreen.m_screen.gameSettings.rulesPanel.resourcesDropdown;

        var ret: Object = new Object();
        loadVariables("QueryGameEngine?IsPcGameHost", ret);
        var isHost: Boolean = ret.IsPcGameHost == "1";

        if (isHost) {
            trace(TRACE_PREFIX + "REWRITE ON CHANGED FUNCTION");
            // TODO: do not setOnChange every time. Set it only once when needed.
            resourcesDropdownComponent.setOnChange(_global.bind1DynamicParams(self, function(resourcesMC) {
                trace("Ra3BattleNet.ResourcePatcher - NEW onResourcesChanged");
                this.cachedResourcesIndex = resourcesMC.getCurrentIndex()
                var value = String(resourcesMC.getValueAtIndex(this.cachedResourcesIndex));
                fscommand("CallGameFunction", "%SetInitialResources?Resources=" + value);
            }));
        }

        ret = new Object();
        loadVariables("QueryGameEngine?RESOURCES_OPTIONS",ret);
        var originalOptionValues: Array = new Array();
        // trace("ret.RESOURCES_OPTIONS_VALUES: " + ret.RESOURCES_OPTIONS_VALUES)
        originalOptionValues = ret.RESOURCES_OPTIONS_VALUES.split(",");
        var currentChoice = Number(originalOptionValues.shift());
        // Not host, simply show first value.
        if (!isHost) {
            trace(TRACE_PREFIX + "NOT HOST");
            self.cachedResourcesIndex = null;
            resourcesDropdownComponent.setData(originalOptionValues, originalOptionValues);
            resourcesDropdownComponent.setSelectedIndex(0);
            return;
        }
        // If there is a catched index use it else use 0 (the first one).
        if (self.cachedResourcesIndex != null) {
            currentChoice = self.cachedResourcesIndex;
        }

        var additionalOptionValues: Array = new Array();
        additionalOptionValues.push("100000");
        additionalOptionValues.push("200000");
        additionalOptionValues.push("300000");
        additionalOptionValues.push("500000");
        additionalOptionValues.push("800000");
        additionalOptionValues.push("1000000");
        additionalOptionValues.push("10000000");

        // Merge two list ane generate values.
        var optionValues: Array = new Array();
        var resourceOptionValues: Array = new Array();
        var i: Number = 0;
        var j: Number = 0;
        while (i < originalOptionValues.length && j < additionalOptionValues.length) {
            var x: Number = Number(originalOptionValues[i]);
            var y: Number = Number(additionalOptionValues[j]);
            if (x <= y) {
                optionValues.push(originalOptionValues[i]);
                resourceOptionValues.push(originalOptionValues[i]);
                i++;
                // Remove duplicate values.
                if (x == y) {
                    j++;
                }
            }
            else {
                optionValues.push(additionalOptionValues[j]);
                resourceOptionValues.push(additionalOptionValues[j]);
                j++;
            }
        }
        while (i < originalOptionValues.length) {
            optionValues.push(originalOptionValues[i]);
            resourceOptionValues.push(originalOptionValues[i]);
            i++;
        }
        while (j < additionalOptionValues.length) {
            optionValues.push(additionalOptionValues[j]);
            resourceOptionValues.push(additionalOptionValues[j]);
            j++;
        }

        resourcesDropdownComponent.setData(resourceOptionValues, optionValues);
        resourcesDropdownComponent.setSelectedIndex(currentChoice);
    };
}
