FROM aeifn/pastvu:stable AS ru
FROM aeifn/pastvu:en AS en
FROM nginx
RUN rm -r /etc/nginx
COPY --from=ru /code/public /public/ru
COPY --from=en /code/public /public/en
COPY . /etc/nginx
