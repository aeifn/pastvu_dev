FROM node AS builder
WORKDIR code
COPY ./pastvu .
RUN npm install
RUN npm install -g grunt
RUN grunt

FROM node
RUN apt-get update && apt-get -y install graphicsmagick webp
WORKDIR /code
COPY --from=builder /appBuild/ .
RUN npm install
COPY ./production.config.js /etc/pastvu.config.js
CMD node /code/bin/run.js --script /code/${MODULE}.js --config /etc/pastvu.config.js
