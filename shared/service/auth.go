package service

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"regexp"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/shared/auth"
	grpcMetadata "google.golang.org/grpc/metadata"
)

const (
	AuthAccountIDContextParam  = "auth_account_id"
	AuthStoreIDContextParam    = "auth_store_id"
	AuthDeviceInfoContextParam = "device_info"
	AuthUserIDContextParam     = "user_id"

	AuthTokenHeader = "X-Cerebel-Token"
	UserIDHeader    = "X-User-Id"

	UserAgentHeader = "User-Agent"

	tokenQueryParam = "token"

	DeviceIOS     = "ios"
	DeviceAndroid = "android"
	DeviceUnknown = "unknown"
)

var (
	errUserAgentHeaderNotFound = errors.New("User-Agent header missing")
	errUserIDHeaderNotFound    = errors.New("UserID header missing")

	errAuthStoreIDContextNotFound    = errors.New(fmt.Sprintf("'%s' not found.", AuthStoreIDContextParam))
	errAuthAccountIDContextNotFound  = errors.New(fmt.Sprintf("'%s' not found.", AuthAccountIDContextParam))
	errAuthTokenContextNotFound      = errors.New(fmt.Sprintf("'%s' not found.", AuthTokenHeader))
	errAuthDeviceInfoContextNotFound = errors.New(fmt.Sprintf("'%s' not found.", UserAgentHeader))
	errAuthUserIDContextNotFound     = errors.New(fmt.Sprintf("'%s' not found.", AuthUserIDContextParam))

	iosRegex     = regexp.MustCompile("^faer/[0-9]+")
	androidRegex = regexp.MustCompile("Android [0-9]+")
)

type DeviceInfo struct {
	OS          string
	OSVersion   string
	AppVersion  string
	BuildNumber int
}

func GetAuthTokenFromGRPCContext(ctx context.Context) (string, error) {
	if md, ok := grpcMetadata.FromIncomingContext(ctx); ok {
		param := strings.ToLower(AuthTokenHeader)
		if len(md[param]) > 0 {
			return md[param][0], nil
		}
	}
	return "", errAuthTokenContextNotFound
}

func ReadAuthMiddleware(authStore *auth.Store) gin.HandlerFunc {
	return authMiddleware(authStore, authStore.AuthRead)
}

func AdminAuthMiddleware(authStore *auth.Store) gin.HandlerFunc {
	return authMiddleware(authStore, authStore.AuthAdmin)
}

func authMiddleware(authStore *auth.Store, authFunc func(string, string) error) gin.HandlerFunc {
	return func(c *gin.Context) {
		// get the token from the request header or query parameter
		token, err := GetAuthTokenFromGinContext(c)
		if err != nil {
			c.JSON(http.StatusUnauthorized, NewErrorResponse(ErrUnauthorizedRequest.Error()))
			c.Abort()
			return
		}

		// get the store ID from the URL
		storeID := c.Params.ByName(AuthStoreIDContextParam)
		if storeID == "" {
			c.JSON(http.StatusBadRequest, NewErrorResponse(ErrBadRequest.Error()))
			c.Abort()
			return
		}

		// authorize the store with the given token
		if err := authFunc(storeID, token); err != nil {
			c.JSON(http.StatusUnauthorized, NewErrorResponse(ErrUnauthorizedRequest.Error()))
			c.Abort()
			return
		}

		// get the user ID (optional)
		userID, _ := GetUserIDFromRequestHeader(c)

		// get device information
		deviceInfo, _ := GetDeviceInfoFromGinContext(c)

		// set context variables
		c.Set(AuthStoreIDContextParam, storeID)
		c.Set(AuthDeviceInfoContextParam, deviceInfo)
		c.Set(AuthUserIDContextParam, userID)

		c.Next()
	}
}

func GetUserIDFromRequestHeader(c *gin.Context) (string, error) {
	userID := c.Request.Header[UserIDHeader]
	if len(userID) == 0 {
		return "", errUserIDHeaderNotFound
	}
	return userID[0], nil
}

func GetAuthUserIDFromGinContext(c *gin.Context) (string, error) {
	userID, found := c.Get(AuthUserIDContextParam)
	if !found {
		return "", errAuthUserIDContextNotFound
	}
	return userID.(string), nil
}

func GetDeviceInfoFromGinContext(c *gin.Context) (*DeviceInfo, error) {
	userAgent := c.Request.Header[UserAgentHeader]
	if len(userAgent) == 0 {
		return nil, errUserAgentHeaderNotFound
	}

	if iosMatch := iosRegex.FindString(userAgent[0]); iosMatch != "" {
		buildNumber, err := strconv.Atoi(strings.Split(iosMatch, "/")[1])
		if err != nil {
			return nil, err
		}
		return &DeviceInfo{DeviceIOS, "", "", buildNumber}, nil
	}

	if androidMatch := androidRegex.FindString(userAgent[0]); androidMatch != "" {
		return &DeviceInfo{DeviceAndroid, strings.Split(androidMatch, " ")[1], "", -1}, nil
	}

	return &DeviceInfo{DeviceUnknown, "", "", -1}, nil
}

func GetAuthTokenFromGinContext(c *gin.Context) (string, error) {
	// read token from http header
	token := c.Request.Header[AuthTokenHeader]
	if len(token) > 0 {
		return token[0], nil
	}

	// try query parameter
	token = c.Request.URL.Query()[tokenQueryParam]
	if len(token) > 0 {
		return token[0], nil
	}

	return "", errAuthTokenContextNotFound
}

func GetAuthStoreIDFromGinContext(c *gin.Context) (string, error) {
	storeID, found := c.Get(AuthStoreIDContextParam)
	if !found {
		return "", errAuthStoreIDContextNotFound
	}
	return storeID.(string), nil
}

func GetAuthDeviceInfoFromGinContext(c *gin.Context) (*DeviceInfo, error) {
	deviceInfo, found := c.Get(AuthDeviceInfoContextParam)
	if !found {
		return nil, errAuthDeviceInfoContextNotFound
	}
	return deviceInfo.(*DeviceInfo), nil
}
