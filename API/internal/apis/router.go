package apis

import (
	"net/http"

	"github.com/team-evian-fiicode25/consumer/API/internal/handlers"
	"github.com/team-evian-fiicode25/consumer/API/internal/services"
)

func SetupRoutes() {
	mux := http.NewServeMux()

	authService := services.NewAuthService()
	registerAuthRoutes(mux, handlers.NewAuthHandler(authService))

	incidentHandler := handlers.NewIncidentHandler()
	registerIncidentRoutes(mux, incidentHandler)

	http.ListenAndServe(":8000", mux)
}

func registerAuthRoutes(mux *http.ServeMux, handler *handlers.AuthHandler) {
	mux.HandleFunc("/auth/register", handler.Register)
	mux.HandleFunc("/auth/login", handler.Login)
}

func registerIncidentRoutes(mux *http.ServeMux, handler *handlers.IncidentHandler) {
	mux.HandleFunc("/incidents/report", handler.Report)
	mux.HandleFunc("/incidents", handler.Get)
}
