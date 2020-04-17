FROM centos

RUN echo foo
RUN yum install -y postgresql
RUN yum install -y epel-release
RUN yum install -y python-pip
RUN pip install --upgrade pip
RUN pip install web.py
RUN pip install prometheus_client

WORKDIR /app

COPY . .

CMD python serve.py
