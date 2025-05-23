﻿import Ra3BattleNet.AutoMatchHint;

class Ra3BattleNet.AutoMatchHelper {
    private static var CLASS_NAME: String = "Ra3BattleNet.AutoMatchHelper";
    private static var RANKED_CHECKBOX: String = "rankedCheckBox";
    private static var RANKED_CHECKBOX_OFFSET_Y: Number = -30;
    private static var RANKED_LABEL_OFFSET_X: Number = 22.5;
    private static var RANKED_LABEL_OFFSET_Y: Number = -11.5;
    private static var RANKED_DETAILS_OFFSET_X: Number = 0;
    private static var RANKED_DETAILS_OFFSET_Y: Number = -5;
    private static var RANKED_DETAILS_WIDTH: Number = 500;
    private static var RANKED_DETAILS_HEIGHT: Number = 60;
    private static var AUTOMATCH_SEARCH_DETAILS: String = "Ra3BattleNet_AutoMatchHelper_AutomatchSearchDetails";
    private static var AUTOMATCH_SEARCH_DETAILS_SHADOW: String = "Ra3BattleNet_AutoMatchHelper_AutomatchSearchDetailsShadow";
    private static var AUTOMATCH_SEARCH_DETAILS_X: Number = -491.5 + /* 边框太窄了，加一点 */ 20;
    private static var AUTOMATCH_SEARCH_DETAILS_Y: Number = -210.5;
    private static var AUTOMATCH_SEARCH_DETAILS_WIDTH: Number = 979.5 - /* 边框太窄了，加一点 */ 40;
    private static var AUTOMATCH_SEARCH_DETAILS_HEIGHT: Number = /* 55.95 */ 350;
    private static var AUTOMATCH_SEARCH_DETAILS_COLOR: Number = 0xF3B061;
    private static var AUTOMATCH_SEARCH_DETAILS_HINT_INTERVAL: Number = 30000; // 30s
    private static var AUTOMATCH_SEARCH_CHATBUTTON: String = "Ra3BattleNet_AutoMatchHelper_AutomatchSearchChatButton";
    private static var AUTOMATCH_SEARCH_ROOMSBUTTON: String = "Ra3BattleNet_AutoMatchHelper_AutomatchSearchRoomsButton";
    private static var AUTOMATCH_SEARCH_CHATBUTTON_X: Number = -166 - 10;
    private static var AUTOMATCH_SEARCH_CHATBUTTON_Y: Number = 80;
    private static var AUTOMATCH_SEARCH_ROOMSBUTTON_X: Number = 10;
    private static var AUTOMATCH_SEARCH_ROOMSBUTTON_Y: Number = 80;
    private static var _apt: MovieClip;
    private static var _intervalId: Number;
    // 这玩意可能不是那么有用，本来是想要提示一行一行地显示出来
    // 可是实际上这个 interval 是从提示被创建的时候就开始了，而不是从显示的时候开始……
    private static var _hintIntervalId: Number;

    public function AutoMatchHelper(thisApt: MovieClip) {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::AutoMatchHelper] ";
        if (typeof _apt === "movieclip") {
            trace(TRACE_PREFIX + "already initialized");
            return;
        }
        _apt = thisApt;
        _apt.swapDepths(_apt._parent.broadcastCheckBox.getDepth() + 1);

        trace(TRACE_PREFIX + "running on " + _apt);
        if (!createElements()) {
            trace(TRACE_PREFIX + "failed to create elements");
            return;
        }
        _apt._visible = false;
        _intervalId = setInterval(update, 500);
        // 下面这代码实在是太诡异了，但也只能这样了
        // 我们必须依靠这段代码才能在我们“寄生”的 screen 退出时，把自己 unload 掉
        _global.gSM.setOnExitScreen(_global.bind1(this, function(previousOnExitScreen: Function) {
            unload();
            if(String(previousOnExitScreen) == "[function]" || previousOnExitScreen != null) {
                trace("[" + CLASS_NAME + "::onExitScreen] calling previous onExitScreen");
                previousOnExitScreen.call(_global.gSM);
            }
        }, _global.gSM.m_onExitScreenFunc));
    }

    private static function unload(): Void {
        trace("[" + CLASS_NAME + "::unload] apt unloading");
        if (_hintIntervalId != null) {
            clearInterval(_hintIntervalId);
            delete _hintIntervalId;
        }
        clearInterval(_intervalId);
        _apt.removeMovieClip();
        delete _intervalId;
        delete _apt;
        delete _global.Ra3BattleNet.AutoMatchHelper;
        trace("[" + CLASS_NAME + "::unload] apt unloaded");
    }

    public static function update(): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::update] ";
        if (typeof _apt !== "movieclip") {
            trace(TRACE_PREFIX + "apt is not a movieclip");
            return;
        }
        var autoMatchSetup = _apt._parent;
        if (typeof autoMatchSetup !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchSetup is not a movieclip");
            return;
        }
        var autoMatchPanel: MovieClip = autoMatchSetup._parent;
        if (typeof autoMatchPanel !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchPanel is not a movieclip");
            return;
        }

        // 邀请按钮和排位复选框的位置重叠了。
        // 我们在邀请按钮不需要使用的时候，把它隐藏掉
        // 在邀请按钮需要使用的时候，显示它、并把排位复选框隐藏掉
        var firstSelection = String(autoMatchSetup.gameTypesMenu.getValueAtIndex(0));
        var currentSelection = String(autoMatchSetup.gameTypesMenu.getValueAtIndex(autoMatchSetup.gameTypesMenu.getCurrentIndex()));
        if (currentSelection == firstSelection) {
            _apt._visible = true;
            // 假如排位复选框并不是隐藏状态，请求它的值
            var rankedCheckBox: MovieClip = _apt[RANKED_CHECKBOX];
            if (rankedCheckBox.isEnabled() === false) {
                trace(TRACE_PREFIX + "ranked checkbox does not have value, request it");
                var result: Object = new Object();
                loadVariables("Ra3BattleNet_InGameHttpRequest", result);
                updateRankedCheckBox(rankedCheckBox, result["isCurrentPlayerRanked"]);
            }

            // 其实 2v2 匹配没人玩的，既然玩家默认选择了第一个选项，不如把后面的都隐藏掉
            // 隐藏除了 1v1 以外的匹配选项
            trace(TRACE_PREFIX + "hiding all game types except 1v1");
            limitTypeMenu(autoMatchSetup.gameTypesMenu);
        }
        else {
            _apt._visible = false;
        }
        var inviteButton: MovieClip = autoMatchSetup.inviteButton;
        if (inviteButton.isEnabled()) {
            inviteButton._alpha = 100;
        }
        else {
            inviteButton._alpha = 0;
        }
    }

    private static function createElements(): Boolean {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::createElements] ";
        if (typeof _apt !== "movieclip") {
            trace(TRACE_PREFIX + "apt is not a movieclip");
            return;
        }
        var autoMatchSetup: MovieClip = _apt._parent;
        if (typeof autoMatchSetup !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchSetup is not a movieclip");
            return;
        }
        var autoMatchPanel: MovieClip = autoMatchSetup._parent;
        if (typeof autoMatchPanel !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchPanel is not a movieclip");
            return;
        }
        var originalCheckBox: MovieClip = autoMatchSetup.broadcastCheckBox;
        if (typeof originalCheckBox !== "movieclip") {
            trace(TRACE_PREFIX + "original broadcast checkbox is not a movieclip");
            return false;
        }
        var autoMatchLobby: MovieClip = autoMatchPanel.autoMatchLobby;
        if (typeof autoMatchLobby !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchLobby is not a movieclip");
            return false;
        }
        var autoMatchLobbyCommander: MovieClip = autoMatchLobby.mcCommanderPlayer;
        if (typeof autoMatchLobbyCommander !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchLobbyCommander is not a movieclip");
            return false;
        }
        var originalLabel: MovieClip = autoMatchLobbyCommander.tfBroadcast;
        if (typeof originalLabel !== "movieclip") {
            trace(TRACE_PREFIX + "original broadcast label is not a movieclip");
            return false;
        }
        var originalDrop: TextField = originalLabel.drop;
        var originalTop: TextField = originalLabel.top;
        if (!originalDrop || !originalTop) {
            trace(TRACE_PREFIX + "original broadcast label does not have drop and top text fields");
            return false;
        }

        trace(TRACE_PREFIX + "creating elements on " + _apt);
        var newCheckbox: MovieClip = _apt.attachMovie(
            "std_MouseCheckBoxSymbol",
            RANKED_CHECKBOX,
            _apt.getNextHighestDepth(), {
                m_width: 200,
                m_textAlign: false,
                m_labelPosition: "right align",
                m_label_x: 0,
                m_label_y: 0,
                m_focusDirs: "Up/Down",
                m_iconType: "default",
                m_extLabel: "",
                m_nTruncateType: 0,
                m_label: "",
                m_bEnabled: true,
                m_refFM: "_root.gFM",
                m_initiallySelected: false,
                m_tabIndex: 1,
                m_bVisible: true,
                m_contentSymbol: "checkBoxContentClipSymbol"
            }
        );
        newCheckbox._x = originalCheckBox._x;
        newCheckbox._y = originalCheckBox._y + originalCheckBox._height + RANKED_CHECKBOX_OFFSET_Y;
        newCheckbox.disable();
        newCheckbox.setOnMouseDownFunction(function () {
            var parameters: String = "?setCurrentPlayerRanked=" + (newCheckbox.isChecked() ? "1" : "0");
            var result: Object = new Object();
            loadVariables("Ra3BattleNet_InGameHttpRequest" + parameters, result);
            updateRankedCheckBox(newCheckbox, result["isCurrentPlayerRanked"]);
        });

        var label: MovieClip = _apt.createEmptyMovieClip(
            "rankedCheckBoxLabel", 
            _apt.getNextHighestDepth()
        );
        label._x = newCheckbox._x + RANKED_LABEL_OFFSET_X;
        label._y = newCheckbox._y + RANKED_LABEL_OFFSET_Y;
        label.createTextField(
            "drop", 1, originalDrop._x, originalDrop._y,
            /* originalDrop._width */ RANKED_DETAILS_WIDTH, // 对于某些语言和字体来说，原来的宽度太小了
            originalDrop._height
        );
        label.createTextField(
            "top", 2, originalTop._x, originalTop._y,
            /* originalTop._width */ RANKED_DETAILS_WIDTH, // 对于某些语言和字体来说，原来的宽度太小了
            originalTop._height
        );
        var drop: TextField = label.drop;
        var top: TextField = label.top;
        drop.textColor = originalDrop.textColor;
        top.textColor = originalTop.textColor;
        // 红警3没有 setNewTextFormat，只有 setTextFormat
        drop.setTextFormat(originalDrop.getNewTextFormat());
        top.setTextFormat(originalTop.getNewTextFormat());
        drop.text = top.text = "$IsPersonaRankedLabel";
        top.text += "&Outline"

        _apt.createTextField(
            "rankedCheckBoxDetails", 
            _apt.getNextHighestDepth(),
            label._x + RANKED_DETAILS_OFFSET_X,
            label._y + label._height + RANKED_DETAILS_OFFSET_Y,
            RANKED_DETAILS_WIDTH,
            RANKED_DETAILS_HEIGHT
        );
        var details: TextField = _apt["rankedCheckBoxDetails"];
        details.multiline = true;
        details.wordWrap = true;
        details.setTextFormat(new TextFormat("Lucida Sans Unicode", 14, top.textColor));
        details.text = "$IsPersonaRankedDetails";
        trace(TRACE_PREFIX + "created elements on " + _apt);

        // 给搜索框也加个文本框
        trace(TRACE_PREFIX + "creating textfield on autoMatchSearch");
        var autoMatchSearch: MovieClip = autoMatchPanel.autoMatchSearch;
        if (typeof autoMatchSearch !== "movieclip") {
            trace(TRACE_PREFIX + "autoMatchSearch is not a movieclip");
            return false;
        }

        var searchDetailsTextFormat: TextFormat = new TextFormat("Lucida Sans Unicode", 16);
        searchDetailsTextFormat.align = "center";
        searchDetailsTextFormat.color = AUTOMATCH_SEARCH_DETAILS_COLOR;
        searchDetailsTextFormat.bold = true;
        var searchDetailsShadowTextFormat: TextFormat = new TextFormat("Lucida Sans Unicode", 16);
        searchDetailsShadowTextFormat.align = "center";
        searchDetailsShadowTextFormat.color = 0x000000;
        searchDetailsShadowTextFormat.bold = true;
        autoMatchSearch.createTextField(
            AUTOMATCH_SEARCH_DETAILS_SHADOW, 
            autoMatchSearch.getNextHighestDepth(),
            AUTOMATCH_SEARCH_DETAILS_X + 1,
            AUTOMATCH_SEARCH_DETAILS_Y + 1,
            AUTOMATCH_SEARCH_DETAILS_WIDTH,
            AUTOMATCH_SEARCH_DETAILS_HEIGHT
        );
        autoMatchSearch.createTextField(
            AUTOMATCH_SEARCH_DETAILS, 
            autoMatchSearch.getNextHighestDepth(),
            AUTOMATCH_SEARCH_DETAILS_X,
            AUTOMATCH_SEARCH_DETAILS_Y,
            AUTOMATCH_SEARCH_DETAILS_WIDTH,
            AUTOMATCH_SEARCH_DETAILS_HEIGHT
        );
        var searchDetails: TextField = autoMatchSearch[AUTOMATCH_SEARCH_DETAILS];
        searchDetails.multiline = true;
        searchDetails.wordWrap = true;
        searchDetails.setTextFormat(searchDetailsTextFormat);
        searchDetails.text = "$AutoMatchSearchDetails";
        var searchDetailsShadow: TextField = autoMatchSearch[AUTOMATCH_SEARCH_DETAILS_SHADOW];
        searchDetailsShadow.multiline = true;
        searchDetailsShadow.wordWrap = true;
        searchDetailsShadow.setTextFormat(searchDetailsShadowTextFormat);
        searchDetailsShadow.text = "$AutoMatchSearchDetails";

        var hintText: AutoMatchHint = new AutoMatchHint();
        searchDetails.text = hintText.getNextText();
        searchDetailsShadow.text = searchDetails.text;
        // 这玩意可能不是那么有用，本来是想要提示一行一行地显示出来
        // 可是实际上这个 interval 是从现在（提示被创建的时候）就开始了，而不是从显示的时候开始……
        _hintIntervalId = setInterval(function () {
            searchDetails.text = hintText.getNextText();
            searchDetailsShadow.text = searchDetails.text;
        }, AUTOMATCH_SEARCH_DETAILS_HINT_INTERVAL);

        trace(TRACE_PREFIX + "created textfield on autoMatchSearch");

        trace(TRACE_PREFIX + "creating buttons on autoMatchSearch");
        var screen = _global.Cafe2_BaseUIScreen.m_thisClass;
        var chatButton: MovieClip = autoMatchSearch.attachMovie(
            "std_MouseButtonSymbol",
            AUTOMATCH_SEARCH_CHATBUTTON,
            autoMatchSearch.getNextHighestDepth(), {
                m_focusDirs: "Up/Down",
                m_bEnabled: true,
                m_refFM: "_root.gFM",
                m_initiallySelected: false,
                m_tabIndex: -1,
                m_bVisible: true,
                m_label: "$CHATLOBBY",
                m_contentSymbol: "buttonContentSymbol"
            }
        );
        chatButton._x = AUTOMATCH_SEARCH_CHATBUTTON_X;
        chatButton._y = AUTOMATCH_SEARCH_CHATBUTTON_Y;
        
        var roomsButton: MovieClip = autoMatchSearch.attachMovie(
            "std_MouseButtonSymbol",
            AUTOMATCH_SEARCH_ROOMSBUTTON,
            autoMatchSearch.getNextHighestDepth(), {
                m_focusDirs: "Up/Down",
                m_bEnabled: true,
                m_refFM: "_root.gFM",
                m_initiallySelected: false,
                m_tabIndex: -1,
                m_bVisible: true,
                m_label: "$ROOMLIST",
                m_contentSymbol: "buttonContentSymbol"
            }
        );
        roomsButton._x = AUTOMATCH_SEARCH_ROOMSBUTTON_X;
        roomsButton._y = AUTOMATCH_SEARCH_ROOMSBUTTON_Y;
        
        var nextFrameIntervalId;
        nextFrameIntervalId = setInterval(function () {
            clearInterval(nextFrameIntervalId);
            chatButton.noIntro();
            chatButton.enable();
            chatButton.show();
            chatButton.visual_unhighlight();
            roomsButton.noIntro();
            roomsButton.enable();
            roomsButton.show();
            roomsButton.visual_unhighlight();
            chatButton.setOnMouseDownFunction(function () {
                if (_global.fem_m_onlineMultiplayer) {
                    screen.onTabClicked(_global.fem_m_onlineMultiplayer.PANEL_COMMUNITY);
                }
            });
            roomsButton.setOnMouseDownFunction(function () {
                if (_global.fem_m_onlineMultiplayer) {
                    screen.onTabClicked(_global.fem_m_onlineMultiplayer.PANEL_CUSTOM_MATCH);
                }
            });
        }, 0);

        return true;
    }

    private static function updateRankedCheckBox(checkBox: MovieClip, isRanked): Void {
        trace("[" + CLASS_NAME + "::updateRankedCheckBox] isRanked = " + isRanked);
        if (isRanked === "1") {
            checkBox.enable();
            checkBox.check();
        }
        else if (isRanked === "0") {
            checkBox.enable();
            checkBox.unCheck();
        }
        else {
            checkBox.disable();
        }
    }

    private static function limitTypeMenu(menuComponent): Void {
        var TRACE_PREFIX: String = "[" + CLASS_NAME + "::limitTypeMenu] ";
        if (menuComponent.m_itemValues.length <= 1) {
            // 已经被限制过了
            return;
        }
        var data = new Object();
        loadVariables("QueryGameEngine?AUTOMATCHTYPES", data);
        var values: Array = data.AUTOMATCHTYPES_VALUES.split(",");
        var strings: Array = data.AUTOMATCHTYPES_STRINGS.split(",");
        trace(TRACE_PREFIX + "values = " + values);
        trace(TRACE_PREFIX + "strings = " + strings);
        var firstVal: Number = Number(values.shift());
        values = values.slice(0, 1);
        strings = strings.slice(0, 1);
        menuComponent.setData(strings, values);
        menuComponent.setSelectedIndex(firstVal);
        trace(TRACE_PREFIX + "limited type menu, length = " + menuComponent.m_itemValues.length);
    }
}
