const std = @import("std");

const ecce = @import("ecce.zig");
const components = @import("components.zig");
const commands = @import("commands.zig");

test "init ecce and add components" 
{
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    const PlayerData = comptime struct { id: i32, name: []const u8 };
    const HealthData = comptime struct { value: i32 };
    
    const Player = comptime components.create_component(PlayerData, "player_components");
    const Health = comptime components.create_component(HealthData, "health_components");

    const component_types = [_]type {
        Player,
        Health,
    };

    const ECCE = comptime ecce.create_ecce(&component_types, &[_]type{});

    var world = ECCE.new(&alloc.allocator());    
    defer world.deinit();

    const entity1: ecce.Entity = try world.add_entity();
    {
        const player1 = Player { .id = world.components.entries.player_components.values().len, .entity = entity1, .data = PlayerData { .id = 42, .name = "Red" } };
        const health1 = Health { .id = world.components.entries.health_components.values().len, .entity = entity1, .data = HealthData { .value = 100 } };
        try world.add_component(entity1, player1);
        try world.add_component(entity1, health1);

        try std.testing.expectEqual(2, world.entities.get(entity1).?.values().len);
        try std.testing.expectEqual(player1.id, world.entities.get(entity1).?.get(Player.t_id).?);

        const stored_player = world.components.entries.player_components.get(player1.id).?;
        try std.testing.expectEqual(player1.data.name, stored_player.data.name);
        const stored_health = try world.get_component_by_id(Health, health1.id);
        try std.testing.expectEqual(health1.data.value, stored_health.data.value);
    }
    
    const entity2: ecce.Entity = try world.add_entity();
    {        
        const player2 = Player { .id = world.components.entries.player_components.values().len, .entity = entity2, .data = PlayerData { .id = 42, .name = "Blue" } };
        const health2 = Health { .id = world.components.entries.health_components.values().len, .entity = entity2, .data = HealthData { .value = 150 } };
        try world.add_component(entity2, player2);
        try world.add_component(entity2, health2);

        try std.testing.expectEqual(2, world.entities.get(entity2).?.values().len);
        try std.testing.expectEqual(player2.id, world.entities.get(entity2).?.get(Player.t_id).?);
        
        const stored_player = world.components.entries.player_components.get(player2.id).?;
        try std.testing.expectEqual(player2.data.name, stored_player.data.name);
        const stored_health = try world.get_component_by_id(Health, health2.id);
        try std.testing.expectEqual(health2.data.value, stored_health.data.value);
    }

    try std.testing.expectEqual(world.entities.values().len, 2);
    try std.testing.expectEqual(world.components.entries.player_components.values().len, 2);
    try std.testing.expectEqual(world.components.entries.health_components.values().len, 2);
}

test "init ecce, add commands and handle" 
{
    var alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer alloc.deinit();

    const GreetingCmdData = comptime struct { text: []const u8 };
    const FarewellCmdData = comptime struct { text: []const u8 };
    
    const GreetCommand = comptime commands.create_command(GreetingCmdData, "greet_commands");
    const FarewellCommand = comptime commands.create_command(FarewellCmdData, "farewell_commands");

    const command_types = [_]type {
        GreetCommand,
        FarewellCommand,
    };

    const ECCE = comptime ecce.create_ecce(&[_]type{}, &command_types);

    var world = ECCE.new(&alloc.allocator());    
    defer world.deinit();

    try world.dispatch_command(GreetCommand { .id = world.get_next_command_id(), .data = GreetingCmdData { .text = "Hello" } });
    try world.dispatch_command(FarewellCommand { .id = world.get_next_command_id(), .data = FarewellCmdData { .text = "Goodbye" } });

    try std.testing.expectEqual(1, world.commands.entries.greet_commands.values().len);
    try std.testing.expectEqual(1, world.commands.entries.farewell_commands.values().len);

    for (world.commands.entries.greet_commands.values()) |_| 
    {
        handle_greet_command(world.commands.entries.greet_commands.pop().?.value.data);
    }

    try std.testing.expectEqual(0, world.commands.entries.greet_commands.values().len);

    for (world.commands.entries.farewell_commands.values()) |_| 
    {
        handle_farewell_command(world.commands.entries.farewell_commands.pop().?.value.data);
    }

    try std.testing.expectEqual(0, world.commands.entries.farewell_commands.values().len);
}

test "Compile-time struct with function, const, and var" 
{
    const fields = [_]ecce.Field { 
        .{ .name = "x", ._type = i32, .value = null },
        .{ .name = "y", ._type = i32, .value = null },
    };

    const Position = ecce.makeStruct(fields, fields.len);

    _ = Position { .x = 10, .y = 3 };
    

    try std.testing.expect(true);
}

fn handle_greet_command(command_data: anytype) void
{
    std.debug.print("\n{s}", .{command_data.?.text});
}

fn handle_farewell_command(command_data: anytype) void
{
    std.debug.print("\n{s}\n", .{command_data.?.text});
}