package search

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
)

type Client struct {
	endpoint string
	token    string
}

func NewClient(host, storeID, token string) (*Client, error) {
	endpoint := fmt.Sprintf("%s/v3/store/%s", host, storeID)
	return &Client{endpoint, token}, nil
}

func (c *Client) GetItem(id string) (*Response, error) {
	endpoint := fmt.Sprintf("%s/item/%s?token=%s", c.endpoint, id, c.token)
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

func (c *Client) TextSearch(request *TextRequest) (*Response, error) {
	endpoint := fmt.Sprintf("%s/search/text", c.endpoint)
	buf, err := json.Marshal(request)
	if err != nil {
		return nil, err
	}
	return c.doSearch(endpoint, buf)
}

func (c *Client) Scroll(request *ScrollRequest) (*Response, error) {
	endpoint := fmt.Sprintf("%s/scroll", c.endpoint)
	buf, err := json.Marshal(request)
	if err != nil {
		return nil, err
	}
	return c.doSearch(endpoint, buf)
}

func (c *Client) doSearch(endpoint string, requestBytes []byte) (*Response, error) {
	postReq, err := http.NewRequest("POST", endpoint, bytes.NewBuffer(requestBytes))
	if err != nil {
		return nil, err
	}

	postReq.Header.Set("X-Cerebel-Token", c.token)
	postReq.Header.Set("Content-Type", "application/json")

	httpClient := &http.Client{}
	httpResp, err := httpClient.Do(postReq)
	if err != nil {
		return nil, err
	}
	defer httpResp.Body.Close()

	data, err := ioutil.ReadAll(httpResp.Body)
	if err != nil {
		return nil, err
	}

	response := &Response{}
	if err := json.Unmarshal(data, &response); err != nil {
		return nil, err
	}

	return response, nil
}
