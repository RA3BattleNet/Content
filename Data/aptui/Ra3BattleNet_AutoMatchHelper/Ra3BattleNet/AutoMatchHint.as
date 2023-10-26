class Ra3BattleNet.AutoMatchHint {
    private var _currentMainText: String;
    private var _currentHintTexts: Array;
    private var _hintIndex: Number;
    
    public function AutoMatchHint() {
        var mainTexts = {
            zh: [
                "您也可以尝试在战网客户端的设置页面启用提醒功能。",
                "启用后，您可以放心将游戏最小化并去做其他事情，我们会在匹配到对手时提醒您。",
                "",
                "1：点击匹配后，系统会等待约 1 分钟，为您寻找水平最为接近的对手（按照双方隐藏分数决定）。",
                "2：若超出该时间，系统将强制撮合满足分数限制的对手进入对战，但双方的分数限制均需满足。",
                "3：若其余玩家与您水平差距较大且选择了较小的分数范围，您可能在该时段不能进行成功的匹配。"
            ],
            en: [
                "You can also try enabling the notification feature in the RA3BattleNet Client's Settings. Once enabled, you can minimize the game and go do something else while we notify you when a match is found.",
                "",
                "1: After starting automatch search, the system will wait for about 1 minute to find an opponent with a similar skill level (determined by the hidden ELO of both players).",
                "2: If the time is exceeded, the system will force the matching of opponents who meet the score limit into the battle, but the score limit of both parties must be met.",
                "3: If other players have a large gap with you and choose a smaller score range, you may not be able to match successfully at that time."
            ]
        };
        var hintTexts = [
            {
                zh: [
                    "你知道吗？铁锤坦克可以吸自己的重工回血！"
                ],
                en: [
                    "Did you know? Hammer Tanks can heal themselves by sucking up their own War Factory!"
                ]
            },
            {
                zh: [
                    "你知道吗？假如你只有三辆守护者坦克，那么无论其中一辆是否使用了技能，它们造成的伤害都是一样的！",
                    "但是，点了高科技协议就不一样了"
                ],
                en: [
                    "Did you know? If you only have three Guardian Tanks, then no matter which one uses its ability, they will all deal the same damage!",
                    "But, if you have the High Technology secret protocol, then it's a different story."
                ]
            },
            {
                zh: [
                    "你知道吗？你在进行自动匹配的时候，依然可以点击上方的聊天大厅和房间列表、看看其他人在聊什么和玩什么",
                    "在你盯着自动匹配界面的这些小提示的时候，你说不定刚好错过了正在大厅里聊天的【那个人】！"
                ],
                en: [
                    "Did you know? You can still click on the chat lobby and room list above to see what other people are talking about and playing while you are in the auto-match queue.",
                    "While you are staring at these tips on the auto-match screen, you might just miss THAT person who might be chatting in the lobby!"
                ]
            }
        ];


        var language: String = "en";
        var query = new Object();
        loadVariables("RA3BattleNet_GameLanguageId", query);
        if (query.languageId.indexOf("chinese") != -1) {
            language = "zh";
        }

        _currentMainText = mainTexts[language].join("\n");
        _currentHintTexts = hintTexts[Math.floor(Math.random() * hintTexts.length)][language];
        _hintIndex = 0;
    }

    public function getNextText(): String {
        var text: String = _currentMainText;
        if (_currentHintTexts.length > 0) {
            if (_hintIndex < _currentHintTexts.length) {
                ++_hintIndex;
            }
            text += "\n\n" + _currentHintTexts.slice(0, _hintIndex).join("\n");;
            if (_hintIndex < _currentHintTexts.length) {
                text += "\n...";
            }
        }
        return text;
    }
}
