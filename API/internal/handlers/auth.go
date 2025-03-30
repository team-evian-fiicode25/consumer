package handlers

import (
	"context"
	"encoding/json"
	"net/http"

	"github.com/team-evian-fiicode25/consumer/API/internal/models"
	"github.com/team-evian-fiicode25/consumer/API/internal/services"
)

type AuthHandler struct {
	consumerService *services.AuthService
}

func NewAuthHandler(client *services.AuthService) *AuthHandler {
	return &AuthHandler{
		consumerService: client,
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

	sessionId, err := h.consumerService.CreateLogin(context.Background(), request.Username, request.Email, request.Phone_number, request.Password)
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

	sessionToken, err := h.consumerService.LogInWithPassword(context.Background(), request.Identifier, request.Password)
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
