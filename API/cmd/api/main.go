package main

import (
	"log"

	"github.com/team-evian-fiicode25/business-logic/database"

	"github.com/team-evian-fiicode25/consumer/API/internal/apis"
)

func main() {
	err := database.InitDBFromEnv()

	if err != nil {
		log.Fatal(err)
	}

	apis.SetupRoutes()
}
