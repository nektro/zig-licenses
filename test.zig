const std = @import("std");
const licenses = @import("licenses");

test {
    _ = &licenses.spdx;
    _ = &licenses.osi;
    _ = &licenses.blueoak.model;
    _ = &licenses.blueoak.gold;
    _ = &licenses.blueoak.silver;
    _ = &licenses.blueoak.bronze;
    _ = &licenses.blueoak.lead;
}
