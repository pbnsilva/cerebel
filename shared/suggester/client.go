package suggester

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"
)

type Client struct {
	endpoint string
	token    string
}

func NewClient(host, storeID, token string) (*Client, error) {
	endpoint := fmt.Sprintf("%s/store/%s", host, storeID)
	return &Client{endpoint, token}, nil
}

func (c *Client) Suggest(q string, gender []string) (*Response, error) {
	endpoint := fmt.Sprintf("%s/suggest?token=%s&q=%s", c.endpoint, c.token, q)
	if len(gender) > 0 {
		endpoint += "&gender=" + strings.Join(gender, ",")
	}

	resp, err := http.Get(endpoint)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	response := &Response{}
	if err := json.Unmarshal(data, &response); err != nil {
		return nil, err
	}

	return response, nil
}
