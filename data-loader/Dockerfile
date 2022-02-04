FROM ubuntu

RUN apt-get install -y postgresql apache2-utils

WORKDIR /app

COPY . .

RUN chmod +x build_data.sh

CMD ./build_data.sh
