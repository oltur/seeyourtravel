FROM python:3.12-slim@sha256:aa943ce411423c7582288f18707ff66eddcbaeb510502d747a72aeb34f30d159
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir torch==2.15.0 --index-url https://download.pytorch.org/whl/cpu \
 && pip install --no-cache-dir -r /tmp/requirements.txt
ENV HF_HOME=/models TOKENIZERS_PARALLELISM=false
# the two halves of one model: the image side makes the index, the multilingual text side (50+ languages) answers the questions
RUN python -c "from sentence_transformers import SentenceTransformer as S; S('clip-ViT-B-32'); S('sentence-transformers/clip-ViT-B-32-multilingual-v1')"
# runs as an ordinary user (uid 1000 owns the bind-mounted index), not as root
ENV HOME=/tmp
USER 1000:1000
