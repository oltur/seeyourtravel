FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 g++ && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir insightface==0.7.3 onnxruntime numpy pillow pillow-heif scikit-learn opencv-python-headless
