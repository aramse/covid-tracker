FROM ubuntu

ENV DEBIAN_FRONTEND=noninteractive 
RUN apt-get update -y && apt-get install -y postgresql python2 wget tzdata
RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && python2 get-pip.py
RUN pip install --upgrade pip
RUN pip install web.py
RUN pip install prometheus_client

WORKDIR /app

COPY . .

CMD python -u serve.py
