FROM ubuntu

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get update -y && apt-get install -y postgresql apache2-utils

WORKDIR /app

COPY . .

RUN chmod +x build_data.sh

CMD ./build_data.sh
