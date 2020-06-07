FROM node

WORKDIR /code

COPY ./pastvu/package*.json ./

RUN npm install

COPY ./pastvu/ ./

COPY ./local.config.js ./config

EXPOSE 3000

CMD [ "node", "/code/bin/run.js", "--script", "/code/app.js" ]
