FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir setuptools
COPY . .
EXPOSE 8005
CMD ["gunicorn", "--bind", "0.0.0.0:8005", "app:app"]