//! This file serves as the main entry point for the library, exporting the
//! public API. Currently, it exposes the `CosLcsIterator`.

pub const CosLcsIterator = @import("cos.zig");

test {
    _ = CosLcsIterator;
}
