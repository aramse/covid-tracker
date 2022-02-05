FROM ubuntu

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get install -y postgresql apache2-utils curl

WORKDIR /app

COPY . .

RUN chmod +x build_data.sh

CMD ./build_data.sh
