package models

type AuthRequest struct {
	Email        string `json:"email"`
	Username     string `json:"username"`
	Password     string `json:"password"`
	Phone_number string `json:"phone_number"`
	Nickname     string `json:"nickname"`
	Identifier   string `json:"identifier"`
}

type AuthResponse struct {
	Id         string `json:"id,omitempty"`
	Session_id string `json:"session_id,omitempty"`
	Error      string `json:"error,omitempty"`
}
