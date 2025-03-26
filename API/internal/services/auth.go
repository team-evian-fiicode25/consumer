package services

import (
	"context"
	"log"
	"net/http"

	"github.com/Khan/genqlient/graphql"
	"github.com/team-evian-fiicode25/business-logic/data"
	"github.com/team-evian-fiicode25/business-logic/user"
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
	resp, err := CreateLogin(ctx, s.client, username, email, phone_number, password)

	if err != nil {
		return "", err
	}

	var auth data.AuthData

	auth.Username = resp.NewLogin.GetUsername()
	auth.AuthID = resp.NewLogin.GetId()
	auth.Email = resp.NewLogin.GetEmail().GetAddress()

	if phoneNumber := resp.NewLogin.GetPhoneNumber(); phoneNumber != nil {
		auth.PhoneNumber = phoneNumber.GetNumber()
	}

	_, err = user.Create(&auth)

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
