## 统一日志系统
extends Node

enum LogLevel {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3
}

const LEVEL_NAMES = ["DEBUG", "INFO", "WARN", "ERROR"]
const ENABLE_LOGGING = true

# 日志输出
static func log(message: String, level: int = LogLevel.INFO) -> void:
    if not ENABLE_LOGGING:
        return
    var timestamp = Time.get_datetime_string_from_system()
    var level_name = LEVEL_NAMES[level] if level < len(LEVEL_NAMES) else "UNKNOWN"
    print("[%s] [%s] %s" % [timestamp, level_name, message])

static func debug(message: String) -> void:
    log(message, LogLevel.DEBUG)

static func info(message: String) -> void:
    log(message, LogLevel.INFO)

static func warn(message: String) -> void:
    log(message, LogLevel.WARNING)

static func error(message: String) -> void:
    log(message, LogLevel.ERROR)
