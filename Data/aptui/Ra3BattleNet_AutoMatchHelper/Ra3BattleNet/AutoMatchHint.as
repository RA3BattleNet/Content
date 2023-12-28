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
            },
            {
                ra3: true,
                corona: true,
                zh: [ "看见那个被缩小的天启坦克了吗？现在，随便来个坦克都能踩扁他！" ],
                en: [ "See that shrinked apocalypse tank? Now any tanks can teach him a lesson by crushing him!" ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "海豚——唯一在海上还能倒着游的武装兵种。" ],
                en: [ "Dolphin, the only armed unit that can reverse on the sea." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "工程师占领中立建筑不需要读条哦。" ],
                en: [ "There is no delay when a engineer occupy a neutral building." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "红色警戒3里并没有轻重甲之分，每个单位都有自己的伤害修正比。" ],
                en: [ "There is no distinction between light and heavy armor in Red Alert 3, each unit has its own damage modifier ratio." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "当你不在中国，与在中国的玩家玩而不开加速器，那么高概率会有比较卡的游戏体验。" ],
                en: [ "When you are not in China and play with players in China without any network improvement tools, then there is a high probability of lag." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "铁锤的特殊技能可以卡在三家基础炮台的极限距离攻击。" ],
                en: [ "The special ability of hammer tank allows it attack T1 defense turret without getting damaged." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "双刃与牛蛙是一个很强的组合，天狗VX也是。" ],
                en: [ "Twinblade and Bullfrog is a strong combo, as is Tengu VX." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "你知道吗？维护者轰炸机四颗炸弹就能炸掉一个牛蛙。" ],
                en: [ "Did you know that Vindicators can take out a bullfrog with only four bombs?" ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "矿场可以补矿车。" ],
                en: [ "You can build ore miner in ore refinery." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "一般来说，最好通过搬动基地的方式去开三矿。" ],
                en: [ "Generally, the best way to deploy the third ore refinery is moving your MCV to there." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "速机场的建造顺序是电站机场，而0矿机是兵营电站机场。" ],
                en: [ "For Allied fast airbase, you can build the airbase immediately after the power plan. However, 0-ore-airbase strategy requires you to have a boot camp first." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "Shift+空格可以开血条。" ],
                en: [ "Shift+space to turn on the HP bar." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "按A键可以让单位行进攻击。" ],
                en: [ "Pressing A allows units to attack a target." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "按一下W可以选定同屏幕同种单位，而两下W可以选定全图的同种单位。" ],
                en: [ "One press of W selects the same type of unit on the same screen, while two presses of W selects the same type of unit on the whole map." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "在侵略模式下，【除了指定攻击目标之外的】其他指令不会让单位转移攻击目标。" ],
                en: [ "In Aggression Mode, commands [other than those that specify the target of the attack] do not cause the unit to shift the target of the attack." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "选中一堆单位按X键散开时，散开的中心点是所有单位坐标的加权平均。" ],
                en: [ "When you select a bunch of units and press X to spread them out, the center point of the spread is a weighted average of all the unit coordinates." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "熊或狗互相拼杀主要比拼的是数量。" ],
                en: [ "When dogs and bears are fighting against each other, the key factor is the number." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "星级动员兵可以在大多数房子的攻击范围之外向房子内投掷燃烧弹。" ],
                en: [ "Elite conscript can throw Molotov cocktail into most buildings from outside the attack range of that building." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "默认键位下，空格键可以让你的屏幕中心对准上一个发生的事件。比如你家里矿车被打了但你的屏幕在前线，你可以按一下空格把视角切到矿车。" ],
                en: [ "With the default keystrokes, the spacebar centers your screen on the last event that happened. For example, if your ore miner is under attack but your screen is in the front line, you can press space to cut the view to the ore miner." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "如果你想提高你的PVP技术，不建议你经常使用Q来同时操作所有战斗单位。" ],
                en: [ "If you want to improve your PVP skills, it is not recommended that you regularly use Q to operate all combat units at the same time." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "编队不是队伍数越多越好，而是使用编队的频率越高越好。" ],
                en: [ "Teams are not better the more teams you have, but the more often you use them." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "选中一批单位，按下鼠标左右键，然后朝某个方向拖动，可以给这批单位拉阵型。" ],
                en: [ "Select a group of units, press the left and right mouse buttons, and drag in a certain direction to pull formations for that group of units." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "基地车闲置时，可以提前拖到想要造下一个建筑的位置。" ],
                en: [ "When the MCV is idle, it can be towed ahead to the location where you want to build the next building." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "蜘蛛可以秒杀海豚和一切步兵。" ],
                en: [ "Terror drones can kill dolphins and all infantry in seconds." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "蜘蛛可以定住载具上附着的蜻蜓，别烦了！" ],
                en: [ "Terror drones can immobilize the burst drone that is attaching a vehicle, don't bother!" ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "当局面僵持不下，试着攀升科技或者转型海军空军。" ],
                en: [ "When the situation is stalemated, try to upgrade the tech or consider using navy and air force." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "远程重轰炸是防御塔的克星。" ],
                en: [ "Long range artillery is the nemesis of defense towers." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "用围墙把矿石精炼厂围上有百利无一害。" ],
                en: [ "There is no harm in fencing off the ore refinery." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "与红色警戒2不同，当你失去所有建筑时，即使你有防御塔，你也会立刻战败。" ],
                en: [ "Unlike Red Alert 2, when you lose all your buildings, even if you have defense towers, you lose the battle immediately." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "当你想要短时间内集中力量一举击败对手，不妨卖掉基地！" ],
                en: [ "When you want to focus on beating your opponents in one fell swoop in a short period of time, you may want to sell your MCV!" ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "选中一些部队时，再按住shift然后框选一批部队，可以把后选中的部队加入先选中的部队中。" ],
                en: [ "When you select some units, then hold shift and then box a batch of units, you can select all of them at once." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "有人使用违禁bug？不妨试试去举报他吧！" ],
                en: [ "Someone using a banned bug? Try reporting him!" ]
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
