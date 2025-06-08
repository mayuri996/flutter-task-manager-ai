FROM python:3.10

WORKDIR /app

COPY mock_server.py .

RUN pip install flask

EXPOSE 5000

CMD ["python", "mock_server.py"]
