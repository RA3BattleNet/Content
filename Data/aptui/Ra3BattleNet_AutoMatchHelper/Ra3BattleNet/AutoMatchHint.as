﻿class Ra3BattleNet.AutoMatchHint {
    private static var CLASS_NAME: String = "Ra3BattleNet.AutoMatchHint";
    private var _currentMainText: String;
    private var _currentHintTexts: Array;
    private var _hintTitle: String;
    private var _hintIndex: Number;
    private var _hintCandidates: Array;
    
    public function AutoMatchHint() {
        var mainTexts = {
            zh: [
                "您也可以尝试在战网客户端的设置页面启用提醒功能。",
                "启用后，您可以放心将游戏最小化并去做其他事情，我们会在匹配到对手时提醒您。",
                "1：点击匹配后，系统会等待约 1 分钟，为您寻找水平最为接近的对手。",
                "2：若超出该时间，系统将强制撮合满足分数限制的对手进入对战，但双方的分数限制均需满足。",
                "3：若其余玩家与您水平差距较大且选择了较小的分数范围，您可能在该时段不能进行成功的匹配。",
                "在极少数情况下，有可能出现 BUG 导致无法退出匹配，此时您可以尝试点击右上角的五角星，然后登出再重新登录"
            ],
            en: [
                "You can also try enabling the notification feature in the RA3BattleNet Client's Settings. Once enabled, you can minimize the game and go do something else while we notify you when a match is found.",
                "1: The system will wait for about 1 minute to find an opponent with a similar skill level.",
                "2: If the time is exceeded, the system will match opponents who meet the score limit of both parties.",
                "3: If all players have a large gap with you, you may not be able to match successfully.",
                "In very rare cases, you cannot exit the automatch due to a bug. In this case, log out and log in again."
            ]
        };
        var hintTitle = {
            zh: "小知识",
            en: "Tips"
        }
        // def是默认显示,会在所有mod上显示内容
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
                corona: false,
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
                corona: false,
                zh: [ "看见那个被缩小的天启坦克了吗？现在，随便来个坦克都能踩扁他！" ],
                en: [ "See that shrinked apocalypse tank? Now any tanks can teach him a lesson by crushing him!" ]
            },
            {
                ra3: true,
                corona: false,
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
                def: true,
                ra3: true,
                corona: true,
                zh: [ "红色警戒3里并没有轻重甲之分，每个单位都有自己的伤害修正比。" ],
                en: [ "There is no distinction between light and heavy armor in Red Alert 3, each unit has its own damage modifier ratio." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "当你不在中国，与在中国的玩家玩而不开加速器，那么高概率会有比较卡的游戏体验。" ],
                en: [ "When you are not in China and play with players in China without any network improvement tools, then there is a high probability of lag." ]
            },
            {
                ra3: true,
                corona: false,
                zh: [ "铁锤的特殊技能可以卡在三家基础炮台的极限距离攻击。" ],
                en: [ "The special ability of hammer tank allows it attack T1 defense turret without getting damaged." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "双刃与牛蛙是一个很强的组合，天狗 VX 也是。" ],
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
                zh: [ "对于盟军、苏联和帝国来说，最好通过移动主基地的方式去开三矿。" ],
                en: [ "For Allies, Soviets and Empire, the best way to deploy the third ore refinery is moving your MCV to there." ]
            },
            {
                ra3: true,
                corona: true,
                zh: [ "速机场的建造顺序是电站机场，而0矿机是兵营电站机场。" ],
                en: [ "For Allied fast airbase, you can build the airbase immediately after the power plan. However, 0-ore-airbase strategy requires you to have a boot camp first." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ 
                    "Shift+空格键可以开启或关闭血条。",
                    "在战网客户端的设置里可以让游戏默认启用或者禁用血条。"
                ],
                en: [
                    "Press Shift+Space to turn on the HP bar.",
                    "You can enable or disable the HP bar by default in the settings of the RA3BattleNet Client."
                ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "按 A 键可以让单位行进攻击。" ],
                en: [ "Pressing 'A' allows units to attack-move towards a destination." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "按一下 W 键可以选定同屏幕同种单位，按两下 W 可以选定全图的同种单位。" ],
                en: [ "One press of 'W' key selects the same type of unit on the same screen, while two presses of 'W' selects the same type of unit on the whole map." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "在侵略模式下，（除了指定攻击目标之外的）其他指令不会让单位转移当前的攻击目标。" ],
                en: [ "In Aggression Mode, commands (other than those that specify the target of the attack) do not cause the unit to shift the target of the attack." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "选中一堆单位按 X 键散开时，散开的中心点是所有单位坐标的加权平均。" ],
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
                corona: false,
                zh: [ "星级动员兵可以在大多数房子的攻击范围之外向房子内投掷燃烧弹。" ],
                en: [ "Elite conscript can throw Molotov cocktail into most buildings from outside the attack range of that building." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "默认键位下，空格键可以让你的屏幕中心对准上一个发生的事件。比如你家里矿车被打了但你的屏幕在前线，你可以按一下空格把视角切到矿车。" ],
                en: [ "With the default hotkey settings, the spacebar centers your screen on the last event that happened. For example, if your ore miner is under attack but your screen is in the front line, you can press space to cut the view to the ore miner." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "如果你想提高你的 PVP 技术，不建议你经常使用 Q 来同时操作所有战斗单位。" ],
                en: [ "If you want to improve your PVP skills, it is not recommended that you regularly use Q to operate all combat units at the same time." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "编队不是队伍数越多越好，而是使用编队的频率越高越好。" ],
                en: [ "Teams are not better the more teams you have, but the more often you use them." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "选中一批单位，按下鼠标左右键，然后朝某个方向拖动，可以给这批单位拉阵型。" ],
                en: [ "Select a group of units, press the left and right mouse buttons, and drag in a certain direction to pull formations for that group of units." ]
            },
            {
                def: true,
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
                zh: [ "蜘蛛可以定住载具上附着的蜻蜓" ],
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
                def: true,
                ra3: true,
                corona: true,
                zh: [ "与红色警戒2不同，当你失去所有建筑时，即使你有防御塔，你也会立刻战败。" ],
                en: [ "Unlike Red Alert 2, when you lose all your buildings, even if you have defense towers, you lose the battle immediately." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "当你想要短时间内集中力量一举击败对手，不妨卖掉基地！" ],
                en: [ "When you want to focus on beating your opponents in one fell swoop in a short period of time, you may want to sell your MCV!" ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "选中一些部队时，再按住 Shift 然后框选一批部队，可以把后选中的部队加入先选中的部队中。" ],
                en: [ "When you select some units, then hold shift and then box a batch of units, you can select all of them at once." ]
            },
            {
                def: true,
                ra3: true,
                corona: true,
                zh: [ "有人使用违禁 BUG？不妨试试去举报他吧！" ],
                en: [ "Someone using a banned bug? Report him!" ]
            },
            {
                armorrush: true,
                zh: [ "工程师可以远程入侵防御塔，而星级的工程师可以远程入侵建筑" ],
                en: [ "Engineers can remotely infiltrate defense towers, while star-rated engineers can remotely infiltrate buildings." ]
            },
            {
                armorrush: true,
                zh: [ "在AR中升级往往是决定胜负的关键" ],
                en: [ "Upgrading in AR is often the key to victory or defeat." ]
            },
            {
                armorrush: true,
                zh: [ "航母的打击范围是非常大的同时也非常消耗资金,所以它往往是对战的转折点" ],
                en: [ "The carrier has a very large strike range but consumes a lot of resources, so it is often a turning point in battle." ]
            },
            {
                armorrush: true,
                zh: [ "轩辕长戟的导弹是有血量的，所以在发射时要小心不被攻击" ],
                en: [ "The missiles of Xuanyuan Changji have health points, so be careful not to be attacked when launching them." ]
            },
            {
                armorrush: true,
                zh: [ "血月的突击兵在房子中可以丢手雷" ],
                en: [ "Blood Moon's assault troops can throw grenades while inside houses." ]
            },
            {
                armorrush: true,
                zh: [ "即使在海上也可以建立围墙" ],
                en: [ "Walls can be built even at sea." ]
            },
            {
                armorrush: true,
                zh: [ "大部分建筑都有自己的独立升级" ],
                en: [ "Most buildings have their own independent upgrades." ]
            },
            {
                armorrush: true,
                zh: [ "AR中船是有碾压等级的" ],
                en: [ "In AR, ships have crushing levels." ]
            },
            {
                armorrush: true,
                zh: [ "AR的蜘蛛是可以倒车的" ],
                en: [ "In AR, spiders can reverse." ]
            },
            {
                armorrush: true,
                zh: [ "阳炎帽子可以反步兵" ],
                en: [ "Kamikaze's tankbuster can counter infantry." ]
            },
            {
                armorrush: true,
                zh: [ "阳炎宫女反装甲防空且追踪" ],
                en: [ "Kamikaze's archer counters armor and air defense, and has tracking capabilities." ]
            },
            {
                armorrush: true,
                zh: [ "血月运兵车被摧毁后掉的枪能被突击兵捡起" ],
                en: [ "When the Blood Moon's transport vehicle is destroyed, the guns it drops can be picked up by assault troops." ]
            },
            {
                armorrush: true,
                zh: [ "大部分的特种单位都是可以隐身的" ],
                en: [ "Most special units are invisible." ]
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
        var modName: String = (query.modName || "ra3").toLowerCase().split(" ").join(""); // 把空格去掉
        trace("[" + CLASS_NAME + "] modName: " + modName);

        _hintTitle = hintTitle[language];

        _hintCandidates = new Array();
        for (var i = 0; i < hintTexts.length; ++i) {
            if (hintTexts[i]["def"]) { // 如果是默认显示的就直接添加,如果没有"def"会直接到else
                _hintCandidates.push(hintTexts[i]);
            }
            else if (hintTexts[i][modName]) {
                _hintCandidates.push(hintTexts[i]);
            }
        }

        _currentMainText = mainTexts[language].join("\n");
        if (_hintCandidates.length > 0) {
            _currentHintTexts = _hintCandidates[Math.floor(Math.random() * _hintCandidates.length)][language].slice()
            _currentHintTexts.unshift(_hintTitle)
        }
        else {
            _currentHintTexts = new Array();
        }
        _hintIndex = 0;
    }

    public function getNextText(): String {
        var language: String = "en";
        var query = new Object();
        loadVariables("RA3BattleNet_GameLanguage", query);
        if (query.languageId && query.languageId.indexOf("chinese") != -1) {
            language = "zh";
        }

        if (_hintCandidates.length > 0) {
            _currentHintTexts = _hintCandidates[Math.floor(Math.random() * _hintCandidates.length)][language].slice()
            _currentHintTexts.unshift(_hintTitle);
        }
        else {
            _currentHintTexts = new Array();
        }

        var text: String = _currentMainText + "\n\n" + _currentHintTexts.join("\n");
        trace("[" + CLASS_NAME + "] getNextText: " + text);
        return text;
    }
}
