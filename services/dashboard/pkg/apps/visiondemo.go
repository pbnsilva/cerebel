package apps

import (
	"bufio"
	"bytes"
	"encoding/json"
	"io"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/petard/cerebel/services/dashboard/pkg/shared"
	"github.com/petard/cerebel/shared/annotation"
	pb "github.com/petard/cerebel/shared/rpc/annotation"
)

type VisionDemo struct {
	cfg *shared.DashboardConfig
}

func NewVisionDemo(engine *gin.Engine, auth *shared.Authorizer, cfg *shared.DashboardConfig) *VisionDemo {
	app := &VisionDemo{cfg}

	engine.GET("/visiondemo", auth.AuthorizeRequestMiddleware(engine), app.getVisionDemo)
	engine.POST("/visiondemo/annotate", auth.AuthorizeRequestMiddleware(engine), app.annotate)

	return app
}

func (a *VisionDemo) getVisionDemo(ctx *gin.Context) {
	ctx.HTML(http.StatusOK, "visiondemo.html", gin.H{})
}

func (a *VisionDemo) annotate(c *gin.Context) {
	// Set a lower memory limit for multipart forms (default is 32 MiB)
	// router.MaxMultipartMemory = 8 << 20  // 8 MiB
	file, _, err := c.Request.FormFile("file")
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"message": "File upload failed"})
		return
	}
	var imageData bytes.Buffer
	writer := bufio.NewWriter(&imageData)
	_, err = io.Copy(writer, file)

	client, err := annotation.NewClient(a.cfg.GetAnnotationHost())
	if err != nil {
		c.JSON(http.StatusInternalServerError, "There was an error connecting to the service.")
		return
	}

	features := []*pb.ImageFeature{
		&pb.ImageFeature{Type: pb.ImageFeature_CATEGORY_PREDICTION, MaxResults: 5},
		&pb.ImageFeature{Type: pb.ImageFeature_ITEM_DETECTION, MaxResults: 5},
		&pb.ImageFeature{Type: pb.ImageFeature_COLOR_DETECTION, MaxResults: 5},
		&pb.ImageFeature{Type: pb.ImageFeature_HAS_FACE_PREDICTION, MaxResults: 2},
		&pb.ImageFeature{Type: pb.ImageFeature_TEXTURE_PREDICTION, MaxResults: 5},
	}

	var response *pb.BatchAnnotateImagesResponse
	response, err = client.BatchAnnotateImagesFromBytes([][]byte{imageData.Bytes()}, features)
	if err != nil {
		c.JSON(http.StatusInternalServerError, "There was an error annotating the image.")
		return
	}

	jsonResponse, err := json.MarshalIndent(response, "", "    ")
	if err != nil {
		c.JSON(http.StatusInternalServerError, "There was an error annotating the image.")
		return
	}

	c.JSON(http.StatusOK, gin.H{"response": response.Responses[0], "json": string(jsonResponse)})
}
