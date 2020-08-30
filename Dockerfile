FROM node

RUN apt-get update && apt-get -y install graphicsmagick webp

WORKDIR /code

COPY ./pastvu/package*.json ./

RUN npm install

COPY ./pastvu/ ./

COPY ./local.config.js ./config

CMD node /code/bin/run.js --script /code/${MODULE}.js
