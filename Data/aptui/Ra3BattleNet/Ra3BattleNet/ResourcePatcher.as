class Ra3BattleNet.ResourcePatcher {
    public function tryPatchGameSetupBase(messageCode) {
        if (messageCode !== _global.MSGCODE.FE_MP_UPDATE_GAME_SETTINGS) {
            return;
        }

        trace("TRY PATCH GAME SETUP BASE");
        if (_global.GameSetupBase == null) {
            trace("_global.GameSetupBase not exist yet");
            return;
        }
        var gameSetupBasePrototype = _global.GameSetupBase.prototype;
        
        // refreshResourcesControl
        if (gameSetupBasePrototype.originalRefreshResourcesControl != undefined) {
            trace("Already patched");
            return;
        }
        gameSetupBasePrototype.originalRefreshResourcesControl = gameSetupBasePrototype.refreshResourcesControl;
        
        gameSetupBasePrototype.refreshResourcesControl = function() {
            trace("NEW refreshResourcesControl");
            var resourcesDropdownComponent = _global.Cafe2_BaseUIScreen.m_screen.gameSettings.rulesPanel.resourcesDropdown;    
            
            trace("REWRITE ON CHANGED FUNCTION");
            resourcesDropdownComponent.setOnChange(_global.bind1DynamicParams(this, function(resourcesMC) {
                trace("NEW onResourcesChanged");
                this.cachedResourcesIndex = resourcesMC.getCurrentIndex()
                var value = String(resourcesMC.getValueAtIndex(this.cachedResourcesIndex));
                fscommand("CallGameFunction", "%SetInitialResources?Resources=" + value);
            }));
            
            var ret = new Object();
            loadVariables("QueryGameEngine?IsPcGameHost",ret);
            var isHost: Boolean = ret.IsPcGameHost == "1";
            
            var ret = new Object();
            loadVariables("QueryGameEngine?RESOURCES_OPTIONS",ret);
            var originalOptionValues: Array = new Array();
            trace("ret.RESOURCES_OPTIONS_VALUES: " + ret.RESOURCES_OPTIONS_VALUES)
            originalOptionValues = ret.RESOURCES_OPTIONS_VALUES.split(",");
            var currentChoice = Number(originalOptionValues.shift());
            // Not host, simply show first value.
            if (!isHost) {
                trace("I AM NOT HOST!");
                this.cachedResourcesIndex = null;
                resourcesDropdownComponent.setData(originalOptionValues, originalOptionValues);
                resourcesDropdownComponent.setSelectedIndex(0);
                return;
            }
            // If there is a catched index use it else use 0 (the first one).
            if (this.cachedResourcesIndex != null) {
                currentChoice = this.cachedResourcesIndex;
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
        trace("GAME SETUP BASE PATCHED");
    }
}
