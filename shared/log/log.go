package log

import (
	"io"
	"os"

	"github.com/go-kit/kit/log"
)

const (
	levelDebug = "DEBUG"
	levelInfo  = "INFO"
	levelWarn  = "WARN"
	levelError = "ERROR"
	levelFatal = "FATAL"
)

var (
	stdoutLogger = newLogger(os.Stdout)
	stderrLogger = newLogger(os.Stderr)
)

func newLogger(writer io.Writer) log.Logger {
	var logger log.Logger
	logger = log.NewLogfmtLogger(log.NewSyncWriter(writer))
	logger = log.With(logger, "ts", log.DefaultTimestampUTC, "caller", log.Caller(4)) // 4 is the callstack depth
	return logger
}

func Debug(msg string, keyvals ...interface{}) {
	kvs := append([]interface{}{"level", levelDebug, "msg", msg}, keyvals...)
	stdoutLogger.Log(kvs...)
}

func Info(msg string, keyvals ...interface{}) {
	kvs := append([]interface{}{"level", levelInfo, "msg", msg}, keyvals...)
	stdoutLogger.Log(kvs...)
}

func Warn(msg string, keyvals ...interface{}) {
	kvs := append([]interface{}{"level", levelWarn, "msg", msg}, keyvals...)
	stdoutLogger.Log(kvs...)
}

func Error(err error, keyvals ...interface{}) {
	kvs := append([]interface{}{"level", levelError, "err", err.Error()}, keyvals...)
	stderrLogger.Log(kvs...)
}

func Fatal(err error, keyvals ...interface{}) {
	kvs := append([]interface{}{"level", levelFatal, "err", err.Error()}, keyvals...)
	stderrLogger.Log(kvs...)
	os.Exit(1)
}
