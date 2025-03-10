package services

import (
	"context"
	"net/http"

	"github.com/Khan/genqlient/graphql"
)

type AuthService struct {
	client graphql.Client
}

func NewAuthService(endpoint string) *AuthService {
	return &AuthService{
		client: graphql.NewClient(endpoint, http.DefaultClient),
	}
}

func (s *AuthService) CreateLogin(ctx context.Context, username, email, phone_number, password string) (*CreateLoginResponse, error) {
	resp, err := CreateLogin(ctx, s.client, username, email, phone_number, password)
	if err != nil {
		return nil, err
	}
	return resp, nil
}

func (s *AuthService) LogInWithPassword(ctx context.Context, identifier string, password string) (*LogInWithPasswordResponse, error) {
	var response *LogInWithPasswordResponse
	var err error
	if isValidEmail(identifier) {
		response, err = LogInWithPassword(ctx, s.client, &identifier, nil, password)
	} else {
		response, err = LogInWithPassword(ctx, s.client, nil, &identifier, password)
	}

	if err != nil {
		return nil, err
	}
	return response, nil
}
