//! Run this with `zig build gen`

const std = @import("std");
const zfetch = @import("zfetch");
const json = @import("json");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = &gpa.allocator;

    const f = try std.fs.cwd().createFile("src/lib.zig", .{});
    const w = f.writer();

    {
        std.log.info("spdx", .{});
        const val = try simple_fetch(alloc, "https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json");

        try w.writeAll("// SPDX License Data generated from https://github.com/spdx/license-list-data\n");
        try w.writeAll("//\n");
        try w.print("// Last generated from version {s}\n", .{val.get("licenseListVersion").?.String});
        try w.writeAll("//\n");

        try w.writeAll("\n");
        try w.writeAll(
            \\pub const License = struct {
            \\    url: []const u8,
            \\};
            \\
        );

        var licenses = val.get("licenses").?.Array;
        std.sort.sort(json.Value, licenses, {}, spdxlicenseLessThan);

        try w.writeAll("\n");
        try w.writeAll("pub const spdx = struct {\n");
        for (licenses) |lic| {
            try w.print("    pub const @\"{s}\" = License{{ .url = \"{s}\" }};\n", .{
                lic.get("licenseId").?.String,
                lic.get("reference").?.String,
            });
        }
        try w.writeAll("};\n");

        try w.writeAll("\n");
        try w.writeAll("pub const osi = &[_][]const u8{\n");
        for (licenses) |lic| {
            if (!lic.get("isOsiApproved").?.Bool) continue;
            try w.print("    \"{s}\",\n", .{lic.get("licenseId").?.String});
        }
        try w.writeAll("};\n");
    }
}

pub fn simple_fetch(alloc: *std.mem.Allocator, url: []const u8) !json.Value {
    const req = try zfetch.Request.init(alloc, url, null);
    defer req.deinit();
    try req.do(.GET, null, null);
    const r = req.reader();
    const body_content = try r.readAllAlloc(alloc, std.math.maxInt(usize));
    const val = try json.parse(alloc, body_content);
    return val;
}

fn spdxlicenseLessThan(context: void, lhs: json.Value, rhs: json.Value) bool {
    _ = context;
    const l = lhs.get("licenseId").?.String;
    const r = rhs.get("licenseId").?.String;
    return std.mem.lessThan(u8, l, r);
}
