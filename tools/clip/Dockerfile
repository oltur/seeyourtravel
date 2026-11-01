FROM python:3.12-slim
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu \
 && pip install --no-cache-dir sentence-transformers pillow numpy
ENV HF_HOME=/models TOKENIZERS_PARALLELISM=false
# the two halves of one model: the image side makes the index, the multilingual text side (50+ languages) answers the questions
RUN python -c "from sentence_transformers import SentenceTransformer as S; S('clip-ViT-B-32'); S('sentence-transformers/clip-ViT-B-32-multilingual-v1')"
