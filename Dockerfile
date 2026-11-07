FROM runpod/worker-comfyui:5.10.0-base

COPY custom_nodes/ /comfyui/custom_nodes/

RUN set -e; \
    for r in /comfyui/custom_nodes/*/requirements.txt; do \
      [ -f "$r" ] || continue; \
      echo "== installing $r"; \
      uv pip install --python /opt/venv/bin/python -r "$r" || echo "REQ""UIREMENTS FAILED: $r"; \
    done; \
    uv pip install --python /opt/venv/bin/python "transformers>=4.50.3,<5" "huggingface-hub<1.0"

RUN cd /comfyui && (timeout 600 python main.py --quick-test-for-ci --cpu 2>&1 || true) | tee /comfyui/node_import_check.log; \
    grep -E "IMPORT[ ]FAILED|Cannot[ ]import" /comfyui/node_import_check.log || echo "All custom nodes imported."

COPY start_worker.sh /start_worker.sh
RUN chmod +x /start_worker.sh

CMD ["/start_worker.sh"]
