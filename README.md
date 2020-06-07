# Pastvu.com docker sources

We have two database service:
 * MongoDB
 * Redis

Also there are four internal services:
 * app
 * uploader
 * downloader
 * sitemap

everyone of which should be run into docker container.

# How to run

```
docker-compose run mongo
```

Then import dump into running container, as described here: https://github.com/pastvu/pastvu

To start application:

```
docker-compose run
```
