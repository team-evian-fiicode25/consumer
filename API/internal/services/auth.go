package services

import (
	"context"
	"log"
	"net/http"

	"github.com/Khan/genqlient/graphql"
	"github.com/team-evian-fiicode25/consumer/API/internal/config"
)

type AuthService struct {
	client graphql.Client
}

func NewAuthService() *AuthService {
	url, err := config.AuthServiceUrl()
	if err != nil {
		log.Fatalln(err.Error())
	}

	return &AuthService{
		client: graphql.NewClient(url, http.DefaultClient),
	}
}

func (s *AuthService) CreateLogin(ctx context.Context, username, email, phone_number, password string) (string, error) {
	_, err := CreateLogin(ctx, s.client, username, email, phone_number, password)

	if err != nil {
		return "", err
	}

	loginSession, err := LogInWithEmail(ctx, s.client, email, password)

	if err != nil {
		return "", err
	}

	return loginSession.LoginSession.GetSessionToken().GetToken(), nil
}

func (s *AuthService) LogInWithPassword(ctx context.Context, identifier string, password string) (string, error) {
	if isValidEmail(identifier) {
		response, err := LogInWithEmail(ctx, s.client, identifier, password)
		if err != nil {
			return "", err
		}

		return response.LoginSession.GetSessionToken().GetToken(), nil
	}

	response, err := LogInWithUsername(ctx, s.client, identifier, password)
	if err != nil {
		return "", err
	}

	return response.LoginSession.GetSessionToken().GetToken(), nil
}

func (s *AuthService) VerifyToken(ctx context.Context, token string) bool {
	resp, err := VerifyToken(ctx, s.client, token)

	if err != nil || resp.GetLogin() == nil {
		return false
	}

	return true
}
