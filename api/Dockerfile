FROM ubuntu

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt-get install -y postgresql python3 python3-pip wget
RUN pip install web.py
RUN pip install prometheus_client

WORKDIR /app

COPY . .

CMD python3 -u serve.py
