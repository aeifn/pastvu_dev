FROM node AS builder
ARG BRANCH
WORKDIR code
COPY ./pastvu .
RUN git checkout ${BRANCH}
RUN npm install
RUN npm install -g grunt
RUN grunt

FROM node
ENV LANG en
RUN apt-get update && apt-get -y install graphicsmagick webp
WORKDIR /code
COPY --from=builder /appBuild/ .
RUN npm install
CMD node /code/bin/run.js --script /code/${MODULE}.js --config /config/pastvu.config.js
