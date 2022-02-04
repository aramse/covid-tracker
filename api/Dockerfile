FROM ubuntu

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql python2 wget
RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && python2 get-pip.py
RUN pip install --upgrade pip
RUN pip install web.py
RUN pip install prometheus_client

WORKDIR /app

COPY . .

CMD python -u serve.py
