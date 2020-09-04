FROM node AS builder
ARG branch=master
WORKDIR code
COPY ./pastvu .
RUN git checkout -f ${branch} && \
	npm install && \
	npm install -g grunt && \
	grunt

FROM node
ENV LANG ru
RUN apt-get update && apt-get -y install graphicsmagick webp
WORKDIR /code
COPY --from=builder /appBuild/ .
RUN npm install
COPY ./production.config.js /etc/app.config.js
CMD node /code/bin/run.js --script /code/${MODULE}.js --config /etc/app.config.js
