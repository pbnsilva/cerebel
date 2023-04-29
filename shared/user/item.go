package user

import "time"

type Item struct {
	ID                   string     `json:"id"`
	CreationDate         time.Time  `json:"creation_date"`
	OS                   string     `json:"os,omitempty"`
	FCMToken             string     `json:"fcm_token,omitempty"`
	LastNotificationDate *time.Time `json:"last_notification_date,omitempty"`
}
