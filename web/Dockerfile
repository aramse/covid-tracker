FROM nginx:latest

WORKDIR /app

COPY . .

RUN rm /etc/nginx/conf.d/*
RUN cp nginx.conf /etc/nginx/conf.d/

