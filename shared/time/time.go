package time

import "time"

func NowInMilliseconds() int64 {
	return time.Now().UnixNano() / int64(time.Millisecond)
}

func HoursSince(milliseconds int64) float64 {
	return float64(NowInMilliseconds()-milliseconds) / 3600000.0
}
