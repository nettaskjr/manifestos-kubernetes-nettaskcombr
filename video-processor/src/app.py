from flask import Flask, request, jsonify
from processor import generate_video
import threading

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"}), 200

@app.route('/process', methods=['POST'])
def process():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    try:
        # Por enquanto, geração síncrona para facilitar o retorno da URL ao n8n
        # Em escala, isso deveria ser assíncrono com webhooks de retorno
        video_url = generate_video(data)
        return jsonify({"video_url": video_url}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
