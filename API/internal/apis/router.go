package apis

import (
	"net/http"

	"github.com/team-evian-fiicode25/consumer/API/internal/handlers"
	"github.com/team-evian-fiicode25/consumer/API/internal/services"
)

func SetupRoutes() {
	mux := http.NewServeMux()

	consumerService := services.NewAuthService()

	registerAuthRoutes(mux, "/", handlers.NewAuthHandler(consumerService))

	http.ListenAndServe(":8000", mux)
}

func registerAuthRoutes(mux *http.ServeMux, basePath string, handler *handlers.AuthHandler) {
	mux.HandleFunc(basePath+"/auth/register", handler.Register)
	mux.HandleFunc(basePath+"/auth/login", handler.Login)
}
