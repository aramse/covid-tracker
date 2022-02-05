FROM ubuntu

ENV TZ="Etc/UTC"
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update -y && apt-get install -y postgresql python2 wget
RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py && python2 get-pip.py
RUN pip install --upgrade pip
RUN pip install web.py
RUN pip install prometheus_client

WORKDIR /app

COPY . .

CMD python -u serve.py
