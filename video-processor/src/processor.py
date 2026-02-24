import os
import json
import requests
from moviepy.editor import ImageClip, concatenate_videoclips, AudioFileClip
from gtts import gTTS
import boto3
from botocore.client import Config

# Configurações de Ambiente
MINIO_ENDPOINT = os.getenv('MINIO_ENDPOINT', 'http://minio.minio.svc.cluster.local:9000')
MINIO_ACCESS_KEY = os.getenv('MINIO_ACCESS_KEY')
MINIO_SECRET_KEY = os.getenv('MINIO_SECRET_KEY')
BUCKET_NAME = os.getenv('BUCKET_NAME', 'videos-tiktok')

def generate_video(product_data):
    """
    Gera um vídeo curto baseado nos dados do produto.
    product_data: { 'id': '...', 'name': '...', 'images': [...], 'description': '...' }
    """
    product_id = product_data.get('id', 'temp')
    name = product_data.get('name', 'Produto Amazon')
    images = product_data.get('images', [])
    description = product_data.get('description', '')

    # 1. Download das Imagens
    img_clips = []
    for i, img_url in enumerate(images[:5]): # Limite de 5 imagens
        img_path = f"tmp_img_{i}.jpg"
        response = requests.get(img_url)
        with open(img_path, 'wb') as f:
            f.write(response.content)
        
        # Criar clip de imagem (2 segundos cada)
        clip = ImageClip(img_path).set_duration(2)
        img_clips.append(clip)

    video = concatenate_videoclips(img_clips, method="compose")

    # 2. Gerar Áudio (TTS)
    text_to_say = f"Confira este produto incrível: {name}. {description}"
    tts = gTTS(text=text_to_say, lang='pt')
    tts.save("audio.mp3")
    
    audio = AudioFileClip("audio.mp3")
    video = video.set_audio(audio)
    
    # Ajustar duração do vídeo ao áudio se necessário
    if video.duration < audio.duration:
        video = video.set_duration(audio.duration)

    # 3. Exportar Vídeo
    video_filename = f"video_{product_id}.mp4"
    video.write_videofile(video_filename, fps=24, codec='libx264')

    # 4. Upload para MinIO
    s3 = boto3.client('s3',
                      endpoint_url=MINIO_ENDPOINT,
                      aws_access_key_id=MINIO_ACCESS_KEY,
                      aws_secret_access_key=MINIO_SECRET_KEY,
                      config=Config(signature_version='s3v4'))
    
    # Garantir que o bucket existe
    try:
        s3.create_bucket(Bucket=BUCKET_NAME)
    except:
        pass

    s3.upload_file(video_filename, BUCKET_NAME, video_filename)
    
    # Limpeza
    os.remove("audio.mp3")
    os.remove(video_filename)
    for i in range(len(img_clips)):
        if os.path.exists(f"tmp_img_{i}.jpg"):
            os.remove(f"tmp_img_{i}.jpg")

    return f"{MINIO_ENDPOINT}/{BUCKET_NAME}/{video_filename}"

if __name__ == "__main__":
    # Exemplo para teste local
    sample_data = {
        "id": "123",
        "name": "Secador de Cabelo Profissional",
        "images": ["https://m.media-amazon.com/images/I/61DbgHExK2L._AC_SL1000_.jpg"],
        "description": "Alta potência e brilho intenso para seu cabelo."
    }
    # url = generate_video(sample_data)
    # print(f"Vídeo gerado: {url}")
    pass
