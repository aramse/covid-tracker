FROM centos:7

RUN yum install -y postgresql
RUN yum install -y httpd-tools

WORKDIR /app

COPY . .

RUN chmod +x build_data.sh

CMD ./build_data.sh
