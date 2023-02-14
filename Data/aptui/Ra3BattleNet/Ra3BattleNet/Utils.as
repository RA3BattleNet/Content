class Ra3BattleNet.Utils {
    public static function getNextHighestDepth(parent: MovieClip): Number {
        var TRACE_PREFIX: String = "[Ra3BattleNet::getNextHighestDepth] ";
        var depth: Number = 1;
        for (var k: String in parent) {
            if (k == "_parent") {
                trace(TRACE_PREFIX + "skipping _parent");
                continue;
            }
            if (Utils.instanceOf(parent[k], MovieClip)) {
                trace(TRACE_PREFIX + parent[k] + " has depth " + parent[k].getDepth())
                var mc: MovieClip = parent[k];
                if (mc.getDepth() >= depth) {
                    trace(TRACE_PREFIX + mc + " already has depth " + mc.getDepth());
                    depth = mc.getDepth() + 1;
                }
            }
            else if (Utils.instanceOf(parent[k], TextField)) {
                trace(TRACE_PREFIX + parent[k] + " has depth " + parent[k].getDepth())
                var tf: TextField = parent[k];
                if (tf.getDepth() >= depth) {
                    trace(TRACE_PREFIX + tf + " already has depth " + mc.getDepth());
                    depth = tf.getDepth() + 1;
                }
            }
        }
        trace(TRACE_PREFIX + "next depth available in " + parent + " is " + depth);
        return depth;
    }

    // https://github.com/lanyizi/apt-danmaku/blob/23f9e7ea6c6e4b5be84dd8552fdb28902010af03/Data/AptUI/feg_m_mainMenu3d/danmaku/GameObject.as#L148
    // self 可以是对象或者构造函数，或者是 null / undefined
    // check 可以是对象或者构造函数，但是不能是 null / undefined
    public static function instanceOf(self, check): Boolean {
        if (!self) {
            return false;
        }
        self = typeof self === 'function'
            ? self.prototype
            : self.__proto__;
        check = typeof check === 'function'
            ? check.prototype
            : check.__proto__;
        while (self) {
            if (self === check) {
                return true;
            }
            self = self.__proto__;
        }
        return false;
    }
}