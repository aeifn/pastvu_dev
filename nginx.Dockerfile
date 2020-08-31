FROM node AS builder
WORKDIR code
COPY ./pastvu .
RUN npm install
RUN npm install -g grunt
RUN grunt

FROM nginx
RUN rm -r /etc/nginx
COPY --from=builder /appBuild/public /public
COPY ./nginx /etc/nginx
