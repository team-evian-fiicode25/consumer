package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"regexp"

	"github.com/team-evian-fiicode25/consumer/API/internal/models"
	"github.com/team-evian-fiicode25/consumer/API/internal/services"
)

type AuthHandler struct {
	authService *services.AuthService
}

func NewAuthHandler(client *services.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: client,
	}
}

func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request models.AuthRequest
	var response models.AuthResponse

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		response.Error = err.Error()
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(response)
		return
	}

	sessionId, err := h.authService.CreateLogin(context.Background(), request.Username, request.Email, request.Phone_number, request.Password)
	if err != nil {
		response.Error = err.Error()
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(response)
		return
	}

	response = models.AuthResponse{
		Id:         sessionId,
		Session_id: sessionId,
	}

	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(response)
}

func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var request models.AuthRequest
	var response models.AuthResponse

	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		response.Error = err.Error()

		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(response)
		return
	}

	sessionToken, err := h.authService.LogInWithPassword(context.Background(), request.Identifier, request.Password)
	if err != nil {
		response.Error = err.Error()

		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(response)
		return
	}

	response = models.AuthResponse{
		Session_id: sessionToken,
	}

	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

func (h *AuthHandler) AuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        header := r.Header.Get("Authorization")
        match := regexp.MustCompile(`^Bearer\s+(\S+)$`).FindStringSubmatch(header)

        if match == nil || !h.authService.VerifyToken(r.Context(), match[1]) {
            http.Error(w, "Unauthorized", http.StatusUnauthorized)
            return
        }

        next.ServeHTTP(w, r)
    })
}
