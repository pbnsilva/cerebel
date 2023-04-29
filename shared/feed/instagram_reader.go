package feed

import (
	"errors"

	"github.com/petard/cerebel/shared/instagram"
)

const (
	InstagramMediaTypeImage = "image"
	InstagramMediaTypeVideo = "video"

	maxMediaItemsPerUser = 100
)

var (
	ErrNoMatchedItems = errors.New("No items could be matched")
)

type InstagramReader struct {
	account    string
	fromDate   uint64
	mediaItems []*instagram.MediaItem
	cursorPos  int
}

func NewInstagramReader(account string) (*InstagramReader, error) {
	return NewInstagramReaderFromDate(account, 0)
}

func NewInstagramReaderFromDate(account string, fromDate uint64) (*InstagramReader, error) {
	return &InstagramReader{account, fromDate, nil, -1}, nil
}

func (r *InstagramReader) Read() bool {
	if r.mediaItems == nil {
		items, err := instagram.GetUserMediaFromDate(r.account, maxMediaItemsPerUser, true, r.fromDate)
		if err != nil {
			// TODO hiding error!!!
			return false
		}
		r.mediaItems = items
	}

	r.cursorPos += 1
	return r.cursorPos < len(r.mediaItems)
}

func (r *InstagramReader) Item() (Item, error) {
	mediaItem := r.mediaItems[r.cursorPos]

	mediaType := InstagramMediaTypeImage
	if mediaItem.IsVideo {
		mediaType = InstagramMediaTypeVideo
	}

	caption := ""
	if len(mediaItem.Caption.Edges) > 0 {
		caption = mediaItem.Caption.Edges[0].Node.Text
	}

	return &InstagramItem{
		ID:        mediaItem.ID,
		Title:     caption,
		Date:      mediaItem.Timestamp,
		ImageURL:  mediaItem.MediaURL,
		MediaType: mediaType,
		Source: &ItemSource{
			Name:     "instagram",
			Username: r.account,
		},
	}, nil
}
