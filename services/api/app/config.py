from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "quickcart-api"
    database_url: str = "postgresql+psycopg://quickcart:quickcart@db:5432/quickcart"
    redis_url: str = "redis://redis:6379/0"
    cors_origins: str = "http://localhost:5173"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
