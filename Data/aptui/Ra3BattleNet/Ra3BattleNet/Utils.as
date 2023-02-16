class Ra3BattleNet.Utils {
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