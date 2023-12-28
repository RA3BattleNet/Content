class Ra3BattleNet.AutoMatchHint {
    private static var CLASS_NAME: String = "Ra3BattleNet.AutoMatchHint";
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
                "3：若其余玩家与您水平差距较大且选择了较小的分数范围，您可能在该时段不能进行成功的匹配。",
                "在极少数情况下，有可能出现 BUG 导致无法退出匹配，此时您可以尝试点击右上角的五角星，然后登出再重新登录"
            ],
            en: [
                "You can also try enabling the notification feature in the RA3BattleNet Client's Settings. Once enabled, you can minimize the game and go do something else while we notify you when a match is found.",
                "",
                "1: After starting automatch search, the system will wait for about 1 minute to find an opponent with a similar skill level (determined by the hidden ELO of both players).",
                "2: If the time is exceeded, the system will force the matching of opponents who meet the score limit into the battle, but the score limit of both parties must be met.",
                "3: If other players have a large gap with you and choose a smaller score range, you may not be able to match successfully at that time.",
                "In very rare cases, it may be impossible to exit the match due to a BUG. In this case, you can try clicking the pentagram in the upper right corner, then log out and log in again."
            ]
        };
        var hintTitle = {
            zh: "小知识",
            en: "Tips"
        }
        var hintTexts = [
            {
                ra3: true,
                corona: true,
                zh: [ "军犬的技能有效时间可以被高科技协议强化，但范围不会。" ],
                en: [ "The effect of Attack dog's skill can be enhanced by High Technology Protocol, though its range remains the same." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "军犬在陆地上比狗熊快，但水里比狗熊慢。" ],
                en: [ "Attack dogs run faster than War Bears on the land, but dogs swim slower in the water." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "军犬会被维和步兵和帝国武士一梭子击毙，建议绕行。" ],
                en: [ 
                    "Attack dogs are vulnerable to Peacekeepers and Imperial Warriors,",
                    "therefore, a detour is advised when you see them."
                ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "维和步兵在防暴盾模式下建议不要背对敌军炮火，那样依然有点疼。" ],
                en: [  "Do not expose Peacekeeper's back to enemy gunfire, even with Riot Shield, that hurts too." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "维和步兵在防暴盾模式下对特定伤害极其脆弱，如动员兵的燃烧瓶和维和轰炸机的炸弹。" ],
                en: [ 
                    "Peacekeepers in Riot Shield mode are extremely vulnerable to certian type of damage,",
                    "like Conscript's Molotov Cocktails and Vindicator's bombs."
                ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "盟军工程师在帐篷状态下可以承受住两次狗和熊的撕咬。" ],
                en: [ "For Dogs and Bears, it takes two bites to kill an engineer in tent mode." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "间谍、忍者渗透起重机没有任何效果，除了让你的朋友们笑笑。" ],
                en: [
                    "It has no effect to command your Spies and Shinobis to infiltrate Soviet Crusher Cranes,",
                    "except giving your friends a chance to laugh at their demise."
                ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "谭雅和工程师可从海面上飞行的世纪轰炸机上直接跳伞进入水中。" ],
                en: [ "Tanya and Engineers can parachute into the water from a Century Bomber flying over the sea." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "尽管 IFV 射的是火箭，但它其实打不动什么装甲单位。" ],
                en: [ "Although IFV launches something that appear to be rockets, it actually has no such ability to fight vehicles." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "守护者坦克的激光增伤并不能叠加，有一个使用技能就好了。" ],
                en: [ "The effect of Guardian Tank's laser won't accumulate, so one tank in laser mode is all what you need to get the job done." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "雅典娜炮的护盾不会因冷冻类武器而缩小。" ],
                en: [ "Freezing damage can not accelerate the shrinkage of Athena's shield." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "试着从派遣飞机从正上方攻击，那里是雅典娜护盾的缺口。" ],
                en: [
                    "Try to send air force to attack Athena's Aegis Shield from right above,",
                    "that's where the shield is vulnerable."
                ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "嘿，记得点个先进航空协议吧，这样我们的飞机飞得更快，打得更狠，还变得更帅！" ],
                en: [
                    "Hey, when playing as Allies, remember to select the Advanced Aeronautics Top Secret Protocol,",
                    "in that case our aircrafts fly faster, strike fiercer and they even get new skins!"
                ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "多数伤害都能一击将被冰冻住的东西击碎。" ],
                en: [ "A single bullet, or almost any other types of damage, is enough to smash a frozen stuff." ]
            }
        ];

        var language: String = "en";
        var query = new Object();
        loadVariables("RA3BattleNet_GameLanguage", query);
        if (query.languageId && query.languageId.indexOf("chinese") != -1) {
            language = "zh";
        }
        trace("[" + CLASS_NAME + "] language: " + language);

        query = new Object();
        loadVariables("RA3BattleNet_GameModName", query);
        var modName: String = (query.modName || "ra3").toLowerCase();
        trace("[" + CLASS_NAME + "] modName: " + modName);

        var candidates: Array = new Array();
        for (var i = 0; i < hintTexts.length; ++i) {
            if (hintTexts[i][modName]) {
                candidates.push(hintTexts[i]);
            }
        }

        _currentMainText = mainTexts[language].join("\n");
        _currentHintTexts = candidates[Math.floor(Math.random() * candidates.length)][language].slice()
        _currentHintTexts.unshift(hintTitle[language])
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
        trace("[" + CLASS_NAME + "] getNextText: " + text);
        return text;
    }
}
