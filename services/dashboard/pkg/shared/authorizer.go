package shared

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/gin-gonic/contrib/sessions"
	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/rand"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

const (
	sessionUserIDKey      = "user-id"
	sessionUserEmailKey   = "user-email"
	sessionUserNameKey    = "user-name"
	sessionLoginOriginKey = "login-origin"
	sessionStateKey       = "state"

	adminTokenSuffix = "_admin_token"

	stateStringLength = 32

	endpointProfileURL = "https://www.googleapis.com/oauth2/v3/userinfo" //endpointProfile points to Google OAuth handshake url
	userKey            = "user"

	credsSecretPath = "/secret/client_secret_709437372174-jv5d4uk9194l37ti9njnl3a5ad5qrjag.apps.googleusercontent.com.json"
)

var (
	errMissingAuthCredentials = errors.New("OAuth2 credentials are not set.")
	errInvalidSessionState    = errors.New("Invalid session state.")
	errUserNotAuthorized      = errors.New("User not authorized.")

	emailWhitelist = map[string]bool{
		"petar@cerebel.io":     true,
		"petar@wearefaer.com":  true,
		"petar@faer.app":       true,
		"petard2008@gmail.com": true,

		"p@e6.ai":             true,
		"pedro@cerebel.io":    true,
		"pedro@wearefaer.com": true,
		"pedro@faer.app":      true,

		"lisa@wearefaer.com": true,
		"lisa@faer.app":      true,

		"johanna@wearefaer.com": true,
		"johanna@faer.app":      true,
	}
)

// User holds all data about the given user
type User struct {
	Sub           string `json:"sub"`
	Name          string `json:"name"`
	GivenName     string `json:"given_name"`
	FamilyName    string `json:"family_name"`
	Profile       string `json:"profile"`
	Picture       string `json:"picture"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	Gender        string `json:"gender"`
}

type credentials struct {
	Web struct {
		ClientID     string `json:"client_id"`
		ClientSecret string `json:"client_secret"`
	} `json:"web"`
}

type Authorizer struct {
	conf *oauth2.Config
}

func NewAuthorizer(cfg *DashboardConfig) (*Authorizer, error) {
	var cid string
	var csecret string
	if cfg.IsProductionEnvironment() {
		creds, err := loadCredentials()
		if err != nil {
			return nil, errMissingAuthCredentials
		}
		cid = creds.Web.ClientID
		csecret = creds.Web.ClientSecret
	} else {
		if cfg.GetCID() == "" || cfg.GetCSecret() == "" {
			return nil, errMissingAuthCredentials
		}
		cid = cfg.GetCID()
		csecret = cfg.GetCSecret()
	}

	conf := &oauth2.Config{
		ClientID:     cid,
		ClientSecret: csecret,
		RedirectURL:  cfg.GetHomeBaseURL() + "/auth",
		Scopes: []string{
			"https://www.googleapis.com/auth/userinfo.email", // You have to select your own scope from here -> https://developers.google.com/identity/protocols/googlescopes#google_sign-in
		},
		Endpoint: google.Endpoint,
	}

	return &Authorizer{conf}, nil
}

// AuthorizeRequestMiddleware is Gin middleware used to authorize a request for a certain end-point group.
func (a *Authorizer) AuthorizeRequestMiddleware(e *gin.Engine) gin.HandlerFunc {
	return func(c *gin.Context) {
		session := sessions.Default(c)
		v := session.Get(sessionUserIDKey)
		if v == nil {
			session.Set(sessionLoginOriginKey, c.Request.URL.String()) // redirect user to entry page after login
			if err := session.Save(); err != nil {
				c.HTML(http.StatusBadRequest, "error.html", "Error during login")
			} else {
				state := a.GetRandomStateString()
				a.SetState(c, state)
				link := a.GetLoginURLFromState(state)
				c.HTML(http.StatusUnauthorized, "sign-in.html", link)
			}
			c.Abort()
		}
		c.Next()
	}
}

func (a *Authorizer) AuthenticateWithContext(c *gin.Context) error {
	session := sessions.Default(c)

	// validate state value
	retrievedState := session.Get("state")
	queryState := c.Query("state")
	if retrievedState != queryState {
		return errInvalidSessionState
	}

	// get an access token
	code := c.Query("code")
	tok, err := a.conf.Exchange(oauth2.NoContext, code)
	if err != nil {
		return err
	}

	// fetch user info
	client := a.conf.Client(oauth2.NoContext, tok)
	userinfo, err := client.Get(endpointProfileURL)
	if err != nil {
		return err
	}
	defer userinfo.Body.Close()

	data, err := ioutil.ReadAll(userinfo.Body)
	if err != nil {
		return err
	}

	user := User{}
	if err = json.Unmarshal(data, &user); err != nil {
		return err
	}

	if !a.isWhitelisted(user.Email) {
		return errUserNotAuthorized
	}

	// update session variables
	session.Set(sessionUserIDKey, user.Email)
	session.Set(sessionUserEmailKey, user.Email)
	session.Set(sessionUserNameKey, user.Name)
	if err = session.Save(); err != nil {
		return err
	}

	return nil
}

func (a *Authorizer) GetRandomStateString() string {
	return rand.StringBytes(stateStringLength)
}

// GetCurrentUser returns the currently signed in user
func (a *Authorizer) GetCurrentUser(c *gin.Context) *User {
	session := sessions.Default(c)
	userID := session.Get(sessionUserIDKey)
	if userID != nil {
		return &User{
			Name:  session.Get(sessionUserNameKey).(string),
			Email: session.Get(sessionUserEmailKey).(string),
		}
	}
	return nil
}

func (a *Authorizer) GetLoginOrigin(c *gin.Context) string {
	session := sessions.Default(c)
	origin := session.Get(sessionLoginOriginKey)
	if origin != nil {
		return origin.(string)
	}
	return "/"
}

func (a *Authorizer) GetLoginURLFromState(state string) string {
	return a.conf.AuthCodeURL(state)
}

func (a *Authorizer) GetUserID(c *gin.Context) string {
	session := sessions.Default(c)
	userID := session.Get(sessionUserIDKey)
	if userID != nil {
		return userID.(string)
	}
	return ""
}

func (a *Authorizer) GetCurrentStore(ctx *gin.Context, userID string) string {
	session := sessions.Default(ctx)
	token := session.Get(fmt.Sprintf("%s_current_store", userID))
	if token != nil {
		return token.(string)
	}
	return ""
}

func (a *Authorizer) SetCurrentStore(ctx *gin.Context, userID, storeID string) {
	session := sessions.Default(ctx)
	session.Set(fmt.Sprintf("%s_current_store", userID), storeID)
	session.Save()
}

func (a *Authorizer) GetStoreAdminToken(ctx *gin.Context, storeID string) string {
	session := sessions.Default(ctx)
	token := session.Get(storeID + adminTokenSuffix)
	if token != nil {
		return token.(string)
	}
	return ""
}

func (a *Authorizer) SetStoreAdminToken(ctx *gin.Context, storeID, token string) {
	session := sessions.Default(ctx)
	session.Set(storeID+adminTokenSuffix, token)
	session.Save()
}

func (a *Authorizer) SetState(c *gin.Context, state string) {
	session := sessions.Default(c)
	session.Set(sessionStateKey, state)
	session.Save()
}

func (a *Authorizer) DeleteSessionVariables(c *gin.Context) {
	session := sessions.Default(c)
	session.Delete(sessionUserIDKey)
	session.Delete(sessionUserEmailKey)
	session.Delete(sessionUserNameKey)
	session.Save()
}

func (a *Authorizer) isWhitelisted(email string) bool {
	_, found := emailWhitelist[email]
	return found
}

func loadCredentials() (*credentials, error) {
	raw, err := ioutil.ReadFile(credsSecretPath)
	if err != nil {
		return nil, err
	}

	var creds *credentials
	if err := json.Unmarshal(raw, &creds); err != nil {
		return nil, err
	}

	return creds, nil
}
