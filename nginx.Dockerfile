FROM node AS builder
WORKDIR code
COPY ./pastvu .
RUN mkdir /public
RUN git checkout -f master && \
	npm install && \
	npm install -g grunt && \
	grunt && \
	mv /appBuild/public /public/ru
RUN git checkout -f en && \
	npm install && \
	npm install -g grunt && \
	grunt && \
	mv /appBuild/public /public/en

FROM nginx
RUN rm -r /etc/nginx
COPY --from=builder /public /public
COPY ./nginx /etc/nginx
