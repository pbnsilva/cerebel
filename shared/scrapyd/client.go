package scrapyd

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
)

type Client struct {
	host string
}

type Spider string

type listSpidersResponse struct {
	Status  string   `json:"status"`
	Message string   `json:"message"`
	Spiders []Spider `json:"spiders"`
}

type listJobsResponse struct {
	Status   string `json:"status"`
	Message  string `json:"message"`
	Pending  []*Job `json:"pending"`
	Running  []*Job `json:"running"`
	Finished []*Job `json:"finished"`
}

type scheduleJobResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	JobID   string `json:"jobid"`
}

type cancelJobResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}

type Job struct {
	ID        string `json:"id"`
	Spider    Spider `json:"spider"`
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
	Indexed   int    `json:"indexed"`
}

type Jobs struct {
	Pending  []*Job `json:"pending"`
	Running  []*Job `json:"running"`
	Finished []*Job `json:"finished"`
}

func NewClient(host string) *Client {
	return &Client{host}
}

func (c *Client) ListSpiders(project string) ([]Spider, error) {
	endpoint := fmt.Sprintf("%s/listspiders.json?project=%s", c.host, project)
	resp, err := http.Get(endpoint)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	response := &listSpidersResponse{}
	if err := json.Unmarshal(data, &response); err != nil {
		return nil, err
	}

	if response.Status == "error" {
		return nil, errors.New(response.Message)
	}

	return response.Spiders, nil
}

func (c *Client) ListJobs(project string) (*Jobs, error) {
	endpoint := fmt.Sprintf("%s/listjobs.json?project=%s", c.host, project)
	resp, err := http.Get(endpoint)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	response := &listJobsResponse{}
	if err := json.Unmarshal(data, &response); err != nil {
		return nil, err
	}

	if response.Status == "error" {
		return nil, errors.New(response.Message)
	}

	return &Jobs{response.Pending, response.Running, response.Finished}, nil
}

func (c *Client) ScheduleJob(project, spider string) (string, error) {
	endpoint := fmt.Sprintf("%s/schedule.json", c.host)

	form := url.Values{
		"project": {project},
		"spider":  {spider},
	}

	body := bytes.NewBufferString(form.Encode())
	resp, err := http.Post(endpoint, "application/x-www-form-urlencoded", body)
	if err != nil {
		return "", nil
	}
	defer resp.Body.Close()

	body_byte, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	response := &scheduleJobResponse{}
	if err := json.Unmarshal(body_byte, &response); err != nil {
		return "", err
	}

	if response.Status == "error" {
		return "", errors.New(response.Message)
	}

	return response.JobID, nil
}

func (c *Client) CancelJob(project, jobID string) error {
	endpoint := fmt.Sprintf("%s/cancel.json", c.host)

	body := []byte(fmt.Sprintf("project=%s&job=%s", project, jobID))
	resp, err := http.Post(endpoint, "application/x-www-form-urlencoded", bytes.NewBuffer(body))
	if err != nil {
		return nil
	}
	defer resp.Body.Close()

	body_byte, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	response := &cancelJobResponse{}
	if err := json.Unmarshal(body_byte, &response); err != nil {
		return err
	}

	if response.Status == "error" {
		return errors.New(response.Message)
	}

	return nil
}
