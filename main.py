import os
import logging
from flask import Flask, jsonify

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

@app.route('/')
def hello_world():
    return jsonify({"message": "Hello, secure world!"})

@app.route('/health')
def health_check():
    return jsonify({"status": "healthy"})

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
