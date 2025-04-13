package main

import (
	"log"
	"os"

	"github.com/joho/godotenv"
	"github.com/team-evian-fiicode25/business-logic/database"
	"github.com/team-evian-fiicode25/consumer/API/internal/apis"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	dsn := os.Getenv("POSTGRES_CONNECTION")
	if dsn == "" {
		log.Fatalln("Missing required env variable: POSTGRES_CONNECTION")
	}

	if err := database.InitDB(dsn); err != nil {
		log.Fatalf("failed to initialize database: %v", err)
	}

	apis.SetupRoutes()
}
