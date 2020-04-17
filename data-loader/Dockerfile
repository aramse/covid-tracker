FROM centos:7

RUN yum install -y postgresql

WORKDIR /app

COPY . .

RUN chmod +x build_data.sh

CMD ./build_data.sh
