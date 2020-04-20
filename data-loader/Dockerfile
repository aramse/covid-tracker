FROM centos:7

RUN yum install -y postgresql
RUN wget https://github.com/lukasmartinelli/pgfutter/releases/download/v1.2/pgfutter_linux_amd64 -O /usr/local/bin/pgflutter && chmod +x /usr/local/bin/pgfutter

WORKDIR /app

COPY . .

RUN chmod +x build_data.sh

CMD ./build_data.sh
