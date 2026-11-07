FROM runpod/worker-comfyui:5.10.0-base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

COPY comfyui_version.txt /tmp/comfyui_version.txt
RUN set -e; v="v$(tr -d '[:space:]' < /tmp/comfyui_version.txt)"; cd /comfyui; \
    [ -d .git ] || git init -q; \
    git fetch -q --depth 1 https://github.com/Comfy-Org/ComfyUI.git tag "$v" && git checkout -q -f "$v"; \
    uv pip install --python /opt/venv/bin/python -r requirements.txt; \
    echo "ComfyUI in image: $v"

COPY custom_nodes/ /comfyui/custom_nodes/

RUN set -e; \
    for r in /comfyui/custom_nodes/*/requirements.txt; do \
      [ -f "$r" ] || continue; \
      echo "== installing $r"; \
      uv pip install --python /opt/venv/bin/python -r "$r" || echo "REQ""UIREMENTS FAILED: $r"; \
    done; \
    uv pip install --python /opt/venv/bin/python "transformers>=4.50.3,<5" "huggingface-hub<1.0"

RUN cd /comfyui && timeout 600 python main.py --quick-test-for-ci --cpu 2>&1 | tee /comfyui/node_import_check.log; \
    grep -E "IMPORT[ ]FAILED|Cannot[ ]import" /comfyui/node_import_check.log || echo "All custom nodes imported."

COPY start_worker.sh /start_worker.sh
RUN chmod +x /start_worker.sh

CMD ["/start_worker.sh"]
