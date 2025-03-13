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
    url, err := config.AuthServiceUrl();
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

func (s *AuthService) LogInWithPassword(ctx context.Context, identifier string, password string) (string, error) {
	if isValidEmail(identifier) {
        response, err := LogInWithEmail(ctx, s.client, identifier, password)
        if err != nil{ 
            return  "", err
        }

        return response.LoginSession.GetSessionToken().GetToken(), nil;
	} 

    response, err := LogInWithUsername(ctx, s.client, identifier, password)
    if err != nil{
        return "", err
    }

    return response.LoginSession.GetSessionToken().GetToken(), nil;
}
