package apps

import (
	"net/http"

	"github.com/gin-gonic/contrib/sessions"
	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/log"
	"github.com/petard/cerebel/shared/rand"
)

const (
	sessionsName = "websession"
)

// Auth represents the user authentication app
type Auth struct {
	auth *shared.Authorizer
	cfg  *shared.DashboardConfig
}

func NewAuth(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *Auth {
	app := &Auth{auth, cfg}

	store := sessions.NewCookieStore([]byte(rand.StringBytes(64)))
	store.Options(sessions.Options{
		Path:   "/",
		MaxAge: 86400 * 7,
	})

	engine.Use(sessions.Sessions(sessionsName, store))

	engine.GET("/sign-in", app.loginHandler)
	engine.GET("/auth", app.authHandler)
	engine.GET("/sign-out", app.logoutHandler)

	return app
}

// authHandler handles authentication of a user and initiates a session.
func (u *Auth) authHandler(c *gin.Context) {
	// do authentication
	if err := u.auth.AuthenticateWithContext(c); err != nil {
		log.Error(err)
		c.HTML(http.StatusBadRequest, "error.html", "Login failed. Please try again.")
		return
	}

	// redirect the user back to the same page
	c.Redirect(http.StatusSeeOther, u.auth.GetLoginOrigin(c))
}

// loginHandler handles the login procedure.
func (u *Auth) loginHandler(c *gin.Context) {
	state := u.auth.GetRandomStateString()
	u.auth.SetState(c, state)
	link := u.auth.GetLoginURLFromState(state)
	c.HTML(http.StatusOK, "sign-in.html", link)
}

// logoutHandler handles the logout procedure.
func (u *Auth) logoutHandler(c *gin.Context) {
	u.auth.DeleteSessionVariables(c)
	c.Redirect(http.StatusSeeOther, "/")
}
