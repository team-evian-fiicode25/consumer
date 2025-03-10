package config

func GetConfig() Config{
   return &EnvConfig{}
}

type Config interface{
    AuthServiceUrl() (string, error)
}
