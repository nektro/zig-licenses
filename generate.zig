//! Run this with `zig build gen`

const std = @import("std");
const json = @import("json");
const nfs = @import("nfs");

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const alloc = gpa.allocator();

    const f = try nfs.cwd().createFile("src/lib.zig", .{});
    const w = f;

    {
        std.log.info("spdx", .{});
        const doc = try simple_fetch(alloc, "https://raw.githubusercontent.com/spdx/license-list-data/master/json/licenses.json");
        defer doc.deinit(alloc);
        const val = doc.root.object();

        try w.writeAll("// SPDX License Data generated from https://github.com/spdx/license-list-data\n");
        try w.writeAll("//\n");
        try w.print("// Last generated from version {s}\n", .{val.getS("licenseListVersion").?});
        try w.writeAll("//\n");

        const licenses = try mutdupe(alloc, json.ValueIndex, val.getA("licenses").?);
        std.mem.sort(json.ValueIndex, licenses, {}, spdxlicenseLessThan);

        try w.writeAll("\n");
        try w.writeAll("pub const spdx = &[_][]const u8{\n");
        for (licenses) |lic| {
            try w.print("    \"{s}\",\n", .{
                lic.object().getS("licenseId").?,
            });
        }
        try w.writeAll("};\n");

        try w.writeAll("\n");
        try w.writeAll("pub const osi = &[_][]const u8{\n");
        for (licenses) |lic| {
            if (!lic.object().getB("isOsiApproved").?) continue;
            try w.print("    \"{s}\",\n", .{lic.object().getS("licenseId").?});
        }
        try w.writeAll("};\n");
    }

    {
        std.log.info("blueoak", .{});
        const doc = try simple_fetch(alloc, "https://blueoakcouncil.org/list.json");
        defer doc.deinit(alloc);
        const val = doc.root.object();

        try w.writeAll("\n");
        try w.writeAll("// Blue Oak Council data generated from https://blueoakcouncil.org/list\n");
        try w.writeAll("//\n");
        try w.print("// Last generated from version {s}\n", .{val.getS("version").?});
        try w.writeAll("//\n");

        try w.writeAll("\n");
        try w.writeAll("pub const blueoak = struct {\n");
        for (val.getA("ratings").?) |rating| {
            try w.print("    pub const {s} = &[_][]const u8{{\n", .{try std.ascii.allocLowerString(alloc, rating.object().getS("name").?)});
            for (rating.object().getA("licenses").?) |lic| {
                try w.print("        \"{s}\",\n", .{
                    lic.object().getS("id").?,
                });
            }
            try w.print("    }};\n", .{});
        }
        try w.writeAll("};\n");
    }
}

pub fn simple_fetch(alloc: std.mem.Allocator, url: []const u8) !json.Document {
    const io = std.Options.debug_io;
    var client = std.http.Client{ .allocator = alloc, .io = io };
    defer client.deinit();

    var list = std.Io.Writer.Allocating.init(alloc);
    defer list.deinit();

    const fetch = try client.fetch(.{
        .location = .{ .url = url },
        .response_writer = &list.writer,
    });
    const opts = json.Parser.Options{ .maximum_depth = 100, .support_trailing_commas = true };
    if (fetch.status != .ok) return try json.parseFromSlice(alloc, url, "{}", opts);
    return try json.parseFromSlice(alloc, url, list.written(), opts);
}

fn spdxlicenseLessThan(context: void, lhs: json.ValueIndex, rhs: json.ValueIndex) bool {
    _ = context;
    const l = lhs.object().getS("licenseId").?;
    const r = rhs.object().getS("licenseId").?;
    return std.mem.lessThan(u8, l, r);
}

fn mutdupe(alloc: std.mem.Allocator, comptime T: type, original: anytype) ![]T {
    const slice = try alloc.alloc(T, original.len);
    for (original, 0..) |item, i| slice[i] = item;
    return slice;
}
