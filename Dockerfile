FROM jrottenberg/ffmpeg:latest

RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY stream.sh /app/
COPY config.env /app/
COPY assets/ /app/assets/

RUN chmod +x /app/stream.sh

CMD ["/app/stream.sh"]
