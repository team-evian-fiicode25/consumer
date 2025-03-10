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
    url, err := config.GetConfig().AuthServiceUrl();
    if err != nil{
        log.Fatalln(err.Error())
    }

	return &AuthService{
		client: graphql.NewClient(url, http.DefaultClient),
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
