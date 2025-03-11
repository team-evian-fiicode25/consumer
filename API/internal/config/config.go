package config

import (
	"fmt"
	"os"
)

func AuthServiceUrl() (string, error){
    const envName = "AUTH_URL"
    var url string = os.Getenv(envName)

    if url == ""{
        return "", newUndefinedEnvError(envName)
    }

    return url, nil
}

type UndefinedEnvError struct{
    varName string
}

func (e UndefinedEnvError) Error() string{
    return fmt.Sprintf("Missing required environment variable: %s", e.varName)
}

func newUndefinedEnvError(varName string) UndefinedEnvError{
    return UndefinedEnvError{varName}
}
