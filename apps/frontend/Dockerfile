FROM flutter/flutter:latest

WORKDIR /app

COPY pubspec.yaml ./
RUN flutter pub get

COPY . .

RUN flutter build web

EXPOSE 5000

CMD ["flutter", "run", "-d", "web-server", "--web-port", "5000", "--web-hostname", "0.0.0.0"]