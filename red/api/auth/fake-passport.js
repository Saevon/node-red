module.exports = {
    needsPermission: function needsPermission(permission) {
        return function (req, res, next) {
            return next();
        };
    }
}
