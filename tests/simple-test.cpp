#include <fmt/args.h>
#include <fmt/base.h>
#include <fmt/chrono.h>
#include <fmt/color.h>
#include <fmt/compile.h>
#include <fmt/core.h>
#include <fmt/format.h>
#include <fmt/os.h>
#include <fmt/ostream.h>
#include <fmt/printf.h>
#include <fmt/ranges.h>
#include <fmt/std.h>
#include <fmt/xchar.h>

#include <iostream>
#include <vector>
#include <map>
#include <chrono>
#include <string>
#include <fstream>

struct CustomType {
    int value;
};

template <>
struct fmt::formatter<CustomType> : fmt::formatter<std::string> {
    auto format(const CustomType& c, fmt::format_context& ctx) const {
        return formatter<std::string>::format("Custom(" + std::to_string(c.value) + ")", ctx);
    }
};


// ostream.h: enables fmt to work with types that have `operator<<`
std::ostream& operator<<(std::ostream& os, const CustomType& c) {
    return os << "Custom(" << c.value << ")";
}

int main() {
    // core.h / format.h
    fmt::print("Hello, {}!\n", "world");

    // chrono.h
    auto now = std::chrono::system_clock::now();
    std::time_t t = std::chrono::system_clock::to_time_t(now);
    std::tm* tm = std::localtime(&t);
    fmt::print("Time: {:%Y-%m-%d %H:%M:%S}\n", *tm);


    // color.h
    fmt::print(fmt::fg(fmt::color::cyan), "This is cyan text\n");

    // compile.h (constexpr formatting)
    constexpr auto compiled = FMT_COMPILE("Compiled: {} = {}\n");
    fmt::print(compiled, "two plus two", 2 + 2);

    // printf.h
    fmt::printf("Printf-style: %d + %d = %d\n", 3, 4, 3 + 4);

    // ranges.h
    std::vector<int> v = {1, 2, 3};
    fmt::print("Vector: {}\n", v);

    // std.h (format STL types like std::map)
    std::map<std::string, int> m = {{"apple", 1}, {"banana", 2}};
    fmt::print("Map: {}\n", m);

    // args.h (manual argument formatting)
    fmt::dynamic_format_arg_store<fmt::format_context> store;
    store.push_back("dynamic");
    store.push_back(42);
    fmt::print("Args: {}\n", fmt::vformat("Stored: {} {}", store));

    // UTF-8 string test
    fmt::print("Wide string (UTF-8): {}\n", reinterpret_cast<const char*>(u8"こんにちは"));


    // base.h - not typically used directly, but proves inclusion
    static_assert(FMT_VERSION >= 100000, "fmt version too low");

    // format-inl.h - usually internal, but proves it compiles
    fmt::memory_buffer buf;
    fmt::format_to(std::back_inserter(buf), "Buffer: {}\n", 123);
    fmt::print("{}", fmt::to_string(buf));

    // ostream.h + custom type
    CustomType c{42};
    fmt::print("Custom type: {}\n", c);

    return 0;
}
