package auth

import "github.com/petard/cerebel/shared/rand"

const (
	tokenLength = 30
)

type Tokens struct {
	ReadTokens []string `json:"read_tokens"`
	AdminToken string   `json:"admin_token"`
}

func GenerateTokens() *Tokens {
	return &Tokens{
		ReadTokens: []string{GenerateRandomToken()},
		AdminToken: GenerateRandomToken(),
	}
}

func GenerateRandomToken() string {
	return rand.StringBytes(tokenLength)
}
