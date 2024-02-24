FROM python:3.11-bookworm
WORKDIR /app
COPY . /app
RUN scripts/setup
ENTRYPOINT [ "uvicorn", "archetype.main:app", "--host=0.0.0.0"]