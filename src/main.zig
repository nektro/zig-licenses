const std = @import("std");
const licenses = @import("./lib.zig");

pub fn main() anyerror!void {
    inline for (licenses.osi) |item| {
        std.log.info("{s}", .{@field(licenses.spdx, item).url});
    }
}
