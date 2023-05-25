module tla.util;

import std.stdio;
import std.conv;
import std.algorithm;
import std.traits;
import std.format;

import toml;

static class TomlConfigHelper {
    static T bind(T)(TOMLDocument doc, string table_name) {
        auto ret = T.init; // default value for config model

        if (table_name !in doc) {
            // table not found in doc
            return ret;
        }

        auto table = doc[table_name];

        // for each member of T, bind the value from the table
        foreach (member_name; __traits(allMembers, T)) {
            // if the member is not in the table, skip it
            if (member_name !in table) {
                continue;
            }

            // get the model member type
            alias member_type = typeof(__traits(getMember, T, member_name));

            static if (is(member_type == string)) {
                __traits(getMember, ret, member_name) = table[member_name].str;
            } else static if (is(member_type == bool)) {
                __traits(getMember, ret, member_name) = table[member_name].boolean;
            } else static if (is(member_type == float)) {
                __traits(getMember, ret, member_name) = table[member_name].floating;
            } else static if (is(member_type == long)) {
                __traits(getMember, ret, member_name) = table[member_name].integer;
            } else {
                static assert(0, format("cannot bind model member %s of type %s", member_name, member_type.stringof));
            }
        }

        return ret;
    }
}
