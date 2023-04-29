package stats

import (
	"fmt"
	"strconv"

	"github.com/garyburd/redigo/redis"
)

const (
	maxConnections = 10

	lastUpdatedTimestampKey = "stats:last-updated"

	likeCountKey  = "likes"
	shareCountKey = "shares"
)

type Store struct {
	pool *redis.Pool
}

func NewStore(redisHost string) (*Store, error) {
	redisPool := redis.NewPool(func() (redis.Conn, error) {
		return redis.Dial("tcp", redisHost)
	}, maxConnections)

	return &Store{redisPool}, nil
}

func (s *Store) GetLastUpdatedTimestamp() (uint64, error) {
	conn := s.pool.Get()
	defer conn.Close()

	lastUpdated, err := redis.Uint64(conn.Do("GET", lastUpdatedTimestampKey))
	if err != nil {
		if err == redis.ErrNil {
			return 0, nil
		}
		return 0, err
	}

	return lastUpdated, nil
}

func (s *Store) SetLastUpdatedTimestamp(ts uint64) error {
	conn := s.pool.Get()
	defer conn.Close()

	if _, err := conn.Do("SET", lastUpdatedTimestampKey, ts); err != nil {
		return err
	}

	return nil
}

func (s *Store) IncrLikesForProduct(productID, brandID string, gender []string, count int) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	totalCount := 0
	for _, gen := range gender {
		key := fmt.Sprintf("brand:%s:%s:%s:product", gen, brandID, likeCountKey)
		counter, err := redis.Int(conn.Do("ZINCRBY", key, count, productID))
		if err != nil {
			return 0, err
		}
		totalCount += counter
	}

	return totalCount, nil
}

func (s *Store) IncrSharesForProduct(productID, brandID string, gender []string, count int) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	totalCount := 0
	for _, gen := range gender {
		key := fmt.Sprintf("brand:%s:%s:%s:product", gen, brandID, shareCountKey)
		counter, err := redis.Int(conn.Do("ZINCRBY", key, count, productID))
		if err != nil {
			return 0, err
		}
		totalCount += counter
	}

	return totalCount, nil
}

func (s *Store) IncrUserBrandInteractions(userID, brandID string, count int) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("user:%s:brand", userID)
	counter, err := redis.Int(conn.Do("ZINCRBY", key, count, brandID))
	if err != nil {
		return 0, err
	}

	return counter, nil
}

func (s *Store) GetTopUserBrands(userID string, topN int) ([]string, []int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("user:%s:brand", userID)
	members, err := redis.Strings(conn.Do("ZREVRANGE", key, 0, topN, "WITHSCORES"))
	if err != nil {
		return nil, nil, err
	}

	brands := make([]string, len(members)/2)
	scores := make([]int, len(members)/2)
	for i := 0; i < len(members)/2; i += 1 {
		brands[i] = members[i*2]

		score, _ := strconv.Atoi(members[i*2+1])
		scores[i] = score
	}

	return brands, scores, nil
}

func (s *Store) GetTopLikedProductsForBrand(brandID, gender string, topN int) ([]string, []int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s:%s:product", gender, brandID, likeCountKey)
	members, err := redis.Strings(conn.Do("ZREVRANGE", key, 0, topN-1, "WITHSCORES"))
	if err != nil {
		return nil, nil, err
	}

	brands := make([]string, len(members)/2)
	scores := make([]int, len(members)/2)
	for i := 0; i < len(members)/2; i += 1 {
		brands[i] = members[i*2]

		score, _ := strconv.Atoi(members[i*2+1])
		scores[i] = score
	}

	return brands, scores, nil
}

func (s *Store) GetTopSharedProductsForBrand(brandID, gender string, topN int) ([]string, []int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s:%s:product", gender, brandID, shareCountKey)
	members, err := redis.Strings(conn.Do("ZREVRANGE", key, 0, topN-1, "WITHSCORES"))
	if err != nil {
		return nil, nil, err
	}

	brands := make([]string, len(members)/2)
	scores := make([]int, len(members)/2)
	for i := 0; i < len(members)/2; i += 1 {
		brands[i] = members[i*2]

		score, _ := strconv.Atoi(members[i*2+1])
		scores[i] = score
	}

	return brands, scores, nil
}

func (s *Store) AddUserProductInteraction(userID, productName string) error {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("user:%s:product", userID)
	if _, err := conn.Do("SADD", key, productName); err != nil {
		return err
	}

	return nil
}

func (s *Store) GetUserInteractedProducts(userID string) ([]string, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("user:%s:product", userID)
	members, err := redis.Strings(conn.Do("SMEMBERS", key))
	if err != nil {
		return nil, err
	}

	return members, nil
}

func (s *Store) GetLikesForProduct(productID, brandID, gender string) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s:%s:product", gender, brandID, likeCountKey)
	count, err := redis.Int(conn.Do("ZSCORE", key, productID))
	if err != nil {
		return 0, err
	}

	return count, nil
}

func (s *Store) GetSharesForProduct(productID, brandID, gender string) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s:%s:product", gender, brandID, shareCountKey)
	count, err := redis.Int(conn.Do("ZSCORE", key, productID))
	if err != nil {
		return 0, err
	}

	return count, nil
}

func (s *Store) IncrLikesForCategory(category, gender string, count int) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("category:%s:%s", gender, category)
	counter, err := redis.Int(conn.Do("HINCRBY", key, likeCountKey, count))
	if err != nil {
		return 0, err
	}

	return counter, nil
}

func (s *Store) IncrSharesForCategory(category, gender string, count int) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("category:%s:%s", gender, category)
	counter, err := redis.Int(conn.Do("HINCRBY", key, shareCountKey, count))
	if err != nil {
		return 0, err
	}

	return counter, nil
}

func (s *Store) GetLikesForCategory(category, gender string) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("category:%s:%s", gender, category)
	count, err := redis.Int(conn.Do("HGET", key, likeCountKey))
	if err != nil {
		if err != redis.ErrNil {
			return 0, err
		}
	}

	return count, nil
}

func (s *Store) GetSharesForCategory(category, gender string) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("category:%s:%s", category)
	count, err := redis.Int(conn.Do("HGET", key, shareCountKey))
	if err != nil {
		if err != redis.ErrNil {
			return 0, err
		}
	}

	return count, nil
}

func (s *Store) IncrLikesForBrand(brandID, gender string, count int) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s", gender, brandID)
	counter, err := redis.Int(conn.Do("HINCRBY", key, likeCountKey, count))
	if err != nil {
		return 0, err
	}

	return counter, nil
}

func (s *Store) IncrSharesForBrand(brandID, gender string, count int) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s", gender, brandID)
	counter, err := redis.Int(conn.Do("HINCRBY", key, shareCountKey, count))
	if err != nil {
		return 0, err
	}

	return counter, nil
}

func (s *Store) GetLikesForBrand(brandID, gender string) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s", gender, brandID)
	count, err := redis.Int(conn.Do("HGET", key, likeCountKey))
	if err != nil {
		if err != redis.ErrNil {
			return 0, err
		}
	}

	return count, nil
}

func (s *Store) GetSharesForBrand(brandID, gender string) (int, error) {
	conn := s.pool.Get()
	defer conn.Close()

	key := fmt.Sprintf("brand:%s:%s", gender, brandID)
	count, err := redis.Int(conn.Do("HGET", key, shareCountKey))
	if err != nil {
		if err != redis.ErrNil {
			return 0, err
		}
	}

	return count, nil
}

// TODO this doesn't belong in a stats store
func (s *Store) GetKeys(pattern string) ([]string, error) {
	conn := s.pool.Get()
	defer conn.Close()

	keys, err := redis.Strings(conn.Do("keys", pattern))
	if err != nil {
		return nil, err
	}

	return keys, nil
}

func (s *Store) SetSearchTeasers(gender string, body interface{}) error {
	conn := s.pool.Get()
	defer conn.Close()

	if _, err := conn.Do("SET", "searchteasers:"+gender, body); err != nil {
		return err
	}

	return nil
}

func (s *Store) GetSearchTeasers(gender string) (interface{}, error) {
	conn := s.pool.Get()
	defer conn.Close()

	res, err := conn.Do("GET", "searchteasers:"+gender)
	if err != nil {
		return nil, err
	}

	return res, nil
}
