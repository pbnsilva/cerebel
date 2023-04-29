package events

import (
	"bytes"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/petard/cerebel/shared/gcs"
	"github.com/petard/cerebel/shared/log"
	shared_time "github.com/petard/cerebel/shared/time"
)

const (
	flushEvery = time.Second * 60 * 60

	bucketName = "data.cerebel.io"
)

type Item struct {
	Value     json.RawMessage `json:"value"`
	CreatedAt int64           `json:"created_at"`
}

type Logger struct {
	items map[string][]*Item
	mu    *sync.RWMutex
}

func NewLogger() (*Logger, error) {
	logger := &Logger{map[string][]*Item{}, &sync.RWMutex{}}
	go logger.flush()
	return logger, nil
}

func (l *Logger) Save(key string, event interface{}) error {
	l.mu.Lock()
	defer l.mu.Unlock()
	if _, found := l.items[key]; !found {
		l.items[key] = []*Item{}
	}

	outBytes, err := json.Marshal(event)
	if err != nil {
		return err
	}
	l.items[key] = append(l.items[key], &Item{json.RawMessage(outBytes), shared_time.NowInMilliseconds()})

	return nil
}

func (l *Logger) flush() {
	ticker := time.NewTicker(flushEvery)
	for _ = range ticker.C {
		for k := range l.items {
			if len(l.items[k]) == 0 {
				continue
			}

			if err := l.saveItemsToKey(k, l.items[k]); err != nil {
				log.Error(err, "key", k)
				continue
			}

			// TODO lock
			l.mu.RLock()
			delete(l.items, k)
			l.mu.RUnlock()

			log.Info("Persisted events", "key", k, "count", len(l.items[k]))
		}
	}
}

func (l *Logger) saveItemsToKey(key string, items []*Item) error {
	l.mu.Lock()
	defer l.mu.Unlock()

	var buffer bytes.Buffer
	for _, item := range items {
		outBytes, err := json.Marshal(item)
		if err != nil {
			return err
		}
		buffer.Write(outBytes)
		buffer.WriteByte('\n')
	}

	date := time.Unix(items[0].CreatedAt/1000, 0).UTC()
	objectName := fmt.Sprintf("events/%s/%s/%d", key, date.Format("2006-01-02"), items[0].CreatedAt)
	if err := gcs.UploadObject(bucketName, objectName, bytes.NewReader(buffer.Bytes())); err != nil {
		return err
	}

	return nil
}
