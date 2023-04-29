package instagram

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"regexp"
)

var (
	errNoMediaFound = errors.New("No media found")
)

type userData struct {
	EntryData struct {
		ProfilePage []*profilePage `json:"ProfilePage"`
	} `json:"entry_data"`
}

type profilePage struct {
	GraphQL struct {
		User struct {
			Media struct {
				Edges []*MediaEdge
			} `json:"edge_owner_to_timeline_media"`
		} `json:"user"`
	} `json:"graphql"`
}

type MediaEdge struct {
	Node *MediaItem `json:"node"`
}

type MediaItem struct {
	ID        string `json":id"`
	Timestamp uint64 `json:"taken_at_timestamp"`
	Caption   struct {
		Edges []*CaptionEdge `json:"edges"`
	} `json:"edge_media_to_caption"`
	MediaURL string `json:"thumbnail_src"`
	IsVideo  bool   `json:"is_video"`
}

type CaptionEdge struct {
	Node struct {
		Text string `json:"text"`
	} `json:"node"`
}

func GetUserMedia(username string, maxItems int, imagesOnly bool) ([]*MediaItem, error) {
	return GetUserMediaFromDate(username, maxItems, imagesOnly, 0)
}

func GetUserMediaFromDate(username string, maxItems int, imagesOnly bool, fromDate uint64) ([]*MediaItem, error) {
	url := fmt.Sprintf("https://www.instagram.com/%s", username)
	data, err := getUserData(url)
	if err != nil {
		return nil, err
	}

	if len(data.EntryData.ProfilePage) == 0 {
		return nil, errNoMediaFound
	}

	items := []*MediaItem{}
	for _, edge := range data.EntryData.ProfilePage[0].GraphQL.User.Media.Edges {
		if imagesOnly && edge.Node.IsVideo || edge.Node.Timestamp < fromDate {
			continue
		}
		items = append(items, edge.Node)
	}

	if len(items) > maxItems {
		items = items[:maxItems]
	}

	return items, nil
}

func getUserData(url string) (*userData, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	html, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	re := regexp.MustCompile("<script type=\"text/javascript\">window._sharedData =(.*?);</script>")
	match := re.FindSubmatch(html)

	if len(match) == 0 {
		return nil, errNoMediaFound
	}

	var userData *userData
	if err := json.Unmarshal(match[1], &userData); err != nil {
		return nil, err
	}

	return userData, nil
}
