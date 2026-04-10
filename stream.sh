#!/bin/bash

echo "========================================="
echo "📺 Mapim WebTV - Transmissão 24/7"
echo "========================================="

# Carregar configurações
source /app/config.env

# Verificar se os arquivos existem
if [ ! -f "$VIDEO_PATH" ]; then
    echo "❌ ERRO: Arquivo de vídeo não encontrado em $VIDEO_PATH"
    exit 1
fi

if [ ! -f "$AUDIO_PATH" ]; then
    echo "❌ ERRO: Arquivo de áudio não encontrado em $AUDIO_PATH"
    exit 1
fi

echo "✅ Vídeo encontrado: $(basename $VIDEO_PATH)"
echo "✅ Áudio encontrado: $(basename $AUDIO_PATH)"

# Converter GIF para MP4 temporário se necessário
TEMP_VIDEO="/tmp/stream_video.mp4"
if [[ "$VIDEO_PATH" == *.gif ]]; then
    echo "🎬 Convertendo GIF para MP4..."
    ffmpeg -i "$VIDEO_PATH" -vf "fps=$FRAMERATE" -c:v libx264 -preset fast "$TEMP_VIDEO" -y
    VIDEO_SOURCE="$TEMP_VIDEO"
else
    VIDEO_SOURCE="$VIDEO_PATH"
fi

# Montar URL RTMP com autenticação
RTMP_URL="${RTMP_SERVER}/${STREAM_KEY}?user=${STREAM_USER}&pass=${STREAM_PASS}"

echo "🌐 Conectando ao servidor: $RTMP_SERVER"
echo "🔑 Stream Key: $STREAM_KEY"
echo "========================================="

# Loop infinito de transmissão
while true; do
    echo "📡 Iniciando stream - $(date)"
    
    ffmpeg -stream_loop -1 -i "$VIDEO_SOURCE" \
           -stream_loop -1 -i "$AUDIO_PATH" \
           -c:v libx264 -preset veryfast \
           -b:v $VIDEO_BITRATE -maxrate ${VIDEO_BITRATE%k}000k -bufsize ${VIDEO_BITRATE%k}000k \
           -vf "fps=$FRAMERATE,scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,format=yuv420p" \
           -c:a aac -b:a $AUDIO_BITRATE -ar 44100 \
           -g 48 -keyint_min 48 \
           -f flv "$RTMP_URL" \
           2>&1 | tee -a /app/stream.log
    
    echo "⚠️ Stream caiu. Reiniciando em 5 segundos..."
    sleep 5
done
