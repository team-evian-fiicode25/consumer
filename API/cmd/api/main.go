package main

import (
	"log"
	"os"

	"github.com/team-evian-fiicode25/business-logic/database"
	"github.com/team-evian-fiicode25/consumer/API/internal/apis"
)

func main() {
    dsn := os.Getenv("POSTGRES_CONNECTION");

    if dsn == "" {
        log.Fatalln("Missing required env variable: POSTGRES_CONNECTION")
    }

    database.InitDB(dsn)

	apis.SetupRoutes()
}
