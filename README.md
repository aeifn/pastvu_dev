# Pastvu.com docker sources

We have two database services:
 * MongoDB
 * Redis

Also there are four internal services:
 * app
 * uploader
 * downloader
 * sitemap

everyone of which should be run into docker container.

# How to run

Clone the repository with submodules:

```
git clone --recursive https://github.com/aeifn/pastvu_dev
```

To start application:

```
cd pastvu_dev
docker-compose up
```

Then navigate to http://localhost:3000/
