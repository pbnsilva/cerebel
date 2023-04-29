package instagram

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math/rand"
	"time"

	"github.com/petard/cerebel/shared/instagram/goinsta"
	"github.com/petard/cerebel/shared/log"
)

type Int64Set map[int64]struct{}

func (s Int64Set) Add(val int64) {
	s[val] = struct{}{}
}

func (s Int64Set) Contains(val int64) bool {
	_, found := s[val]
	return found
}

type StringSet map[string]struct{}

func (s StringSet) Add(val string) {
	s[val] = struct{}{}
}

func (s StringSet) Contains(val string) bool {
	_, found := s[val]
	return found
}

type Bot struct {
	insta     *goinsta.Instagram
	tags      []string
	state     *state
	followers Int64Set
}

type state struct {
	// date for the last post we saw
	LastPostAt float64 `json:"last_post_at"`

	// dates when we last interacted with the users
	LastInteractedAt map[int64]int64 `json:"last_interacted_at"`

	IgnoreUsers Int64Set `json:"ignore_users"`
}

// TODO persist and update
func NewBot(username, pass string, tags []string) (*Bot, error) {
	inst := goinsta.New(username, pass)

	log.Info("Logging in... ")
	if err := inst.Login(); err != nil {
		return nil, err
	}

	log.Info("Getting followers... ")
	followers := Int64Set{}
	users := inst.Account.Followers()
	for users.Next() {
		for _, user := range users.Users {
			followers.Add(user.ID)
		}
	}

	return &Bot{
		insta:     inst,
		tags:      tags,
		state:     &state{0, map[int64]int64{}, Int64Set{}},
		followers: followers,
	}, nil
}

func (b *Bot) LoadState(fpath string) error {
	bytes, err := ioutil.ReadFile(fpath)
	if err != nil {
		return err
	}

	var state *state
	if err := json.Unmarshal(bytes, &state); err != nil {
		return err
	}

	b.state = state

	log.Info("Loaded state")

	return nil
}

func (b *Bot) SaveState(fpath string) error {
	stateBytes, err := json.Marshal(b.state)
	if err != nil {
		return err
	}

	err = ioutil.WriteFile(fpath, stateBytes, 0644)
	if err != nil {
		return err
	}

	log.Info("Saved state")

	return nil
}

func (b *Bot) doRun(maxUsers, maxLikesPerUser, maxFollows int, dryRun bool) error {
	users, err := b.selectUsers(maxUsers)
	if err != nil {
		return err
	}

	log.Info("Selected users", "count", len(users))

	posts, err := b.selectPosts(users, maxLikesPerUser)
	if err != nil {
		return err
	}

	log.Info("Selected posts", "count", len(posts))

	lastActionTime := time.Now()

	// like posts
	for _, p := range posts {
		media, err := b.insta.GetMedia(p)
		if err != nil {
			log.Error(err)
			continue
		}

		log.Info("Liking post", "url", b.getPostURL(media.Items[0].Code), "user", media.Items[0].User.Username)

		if !dryRun {
			if time.Now().Sub(lastActionTime).Seconds() < 10 {
				b.randSleep(6, 18)
			}

			if err := media.Items[0].Like(); err != nil {
				log.Error(err)
				continue
			}

			if _, found := b.state.LastInteractedAt[media.Items[0].User.ID]; !found {
				b.state.LastInteractedAt[media.Items[0].User.ID] = time.Now().Unix()
			}

			lastActionTime = time.Now()
		}
	}

	// follow users
	followCount := 0
	for _, userID := range users {
		if followCount == maxFollows {
			break
		}

		user, err := b.insta.Profiles.ByID(userID)
		if err != nil {
			log.Error(err)
			continue
		}

		log.Info("Following user", "user", user.Username)

		if !dryRun {
			if time.Now().Sub(lastActionTime).Seconds() < 10 {
				b.randSleep(6, 18)
			}

			if err := user.Follow(); err != nil {
				log.Error(err)
				continue
			}

			lastActionTime = time.Now()
		}

		followCount += 1
	}

	return nil
}

func (b *Bot) selectPosts(users []int64, maxPostsPerUser int) ([]string, error) {
	posts := []string{}

	for _, u := range users {
		user, err := b.insta.Profiles.ByID(u)
		if err != nil {
			return nil, err
		}

		log.Info("Fetching posts for user", "user", user.Username)

		count := 0
		feed := user.Feed()
		for feed.Next() {
			for _, item := range feed.Items {
				hasTag := false
				for _, itemTag := range item.Hashtags() {
					for _, tag := range b.tags {
						if tag == itemTag.Name {
							hasTag = true
							break
						}
					}
					if hasTag {
						break
					}
				}

				if !hasTag {
					continue
				}

				posts = append(posts, item.ID)
				count += 1

				if count == maxPostsPerUser {
					break
				}
			}

			if count == maxPostsPerUser {
				break
			}
		}
	}

	return posts, nil
}

func (b *Bot) DryRun(maxUsers, maxLikesPerUser, maxFollows int) error {
	return b.doRun(maxUsers, maxLikesPerUser, maxFollows, true)
}

func (b *Bot) Run(maxUsers, maxLikesPerUser, maxFollows int) error {
	return b.doRun(maxUsers, maxLikesPerUser, maxFollows, false)
}

// Select users to interact with
// by looking at posts with the given tags
func (b *Bot) selectUsers(max int) ([]int64, error) {
	posts := map[int64]struct{}{}
	users := map[int64]struct{}{}
	result := []int64{}

	for _, tag := range b.tags {
		log.Info("Fetching users", "tag", tag)
		h := b.insta.NewHashtag(tag)

		// get the relevant posts
		for h.Next() {
			for s := range h.Sections {
				for _, p := range h.Sections[s].LayoutContent.Medias {
					// skip posts we've already seen (e.g. share tags)
					if _, found := posts[p.Item.Pk]; found {
						continue
					}
					posts[p.Item.Pk] = struct{}{}

					// skip posts older than the last time we looked
					if p.Item.TakenAt < b.state.LastPostAt {
						continue
					}

					if _, found := users[p.Item.User.ID]; found {
						continue
					}

					if b.state.IgnoreUsers.Contains(p.Item.User.ID) {
						continue
					}

					// skip users that already follow us
					if _, isFollowing := b.followers[p.Item.User.ID]; isFollowing {
						log.Info("Skipping user", "user", p.Item.User.Username, "reason", "already follows")
						b.state.IgnoreUsers.Add(p.Item.User.ID)
						continue
					}

					// skip users we interacted with recently
					if interactedAt, found := b.state.LastInteractedAt[p.Item.User.ID]; found {
						if time.Now().Sub(time.Unix(interactedAt, 0)).Hours() < 72 {
							log.Info("Skipping user", "user", p.Item.User.Username, "reason", "interacted recently")
							continue
						}
					}

					b.randSleep(5, 12)

					// fetch the user's info
					followerCount, err := b.getUserFollowerCount(p.Item.User.ID)
					if err != nil {
						continue
					}

					followingCount, err := b.getUserFollowingCount(p.Item.User.ID)
					if err != nil {
						continue
					}

					// we don't want very unpopular or very popular users
					if followingCount < 200 || followerCount > 3000 {
						log.Info("Skipping user", "user", p.Item.User.Username, "reason", "not enough or too many followers")
						b.state.IgnoreUsers.Add(p.Item.User.ID)
						continue
					}

					users[p.Item.User.ID] = struct{}{}
					result = append(result, p.Item.User.ID)
					log.Info("Selecting user", "user", p.Item.User.Username)

					if p.Item.TakenAt > b.state.LastPostAt {
						b.state.LastPostAt = p.Item.TakenAt
					}

					// we've collected enough users, return
					if len(result) == max {
						return result, nil
					}
				}
			}
		}
	}

	return result, nil
}

func (b *Bot) getUserFollowerCount(userID int64) (int, error) {
	user, err := b.insta.Profiles.ByID(userID)
	if err != nil {
		return 0, err
	}

	return user.FollowerCount, nil
}

func (b *Bot) getUserFollowingCount(userID int64) (int, error) {
	count := 0

	user, err := b.insta.Profiles.ByID(userID)
	if err != nil {
		return 0, err
	}

	users := user.Following()
	for users.Next() {
		count += len(users.Users)
	}

	return count, nil
}

func (b *Bot) getPostURL(code string) string {
	return fmt.Sprintf("https://www.instagram.com/p/%s", code)
}

func max(vals ...int) int {
	cur := vals[0]
	for i := 1; i < len(vals); i++ {
		if vals[i] > cur {
			cur = vals[i]
		}
	}
	return cur
}

func (b *Bot) randSleep(min, max int) {
	time.Sleep(time.Duration(min+rand.Intn(max-min)) * time.Second)
}
