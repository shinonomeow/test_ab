# syntax=docker/dockerfile:1

# 构建阶段
FROM python:3.11-slim AS builder

# 安装构建依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
  curl \
  && rm -rf /var/lib/apt/lists/*

# 安装 uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

# 设置工作目录
WORKDIR /build

# 复制依赖文件并安装
COPY backend/pyproject.toml backend/uv.lock ./

# 安装Python依赖
RUN uv sync --frozen --no-dev

# 运行阶段
FROM python:3.11-slim AS runtime

ENV LANG="C.UTF-8" \
  TZ=Asia/Shanghai \
  PUID=1000 \
  PGID=1000 \
  UMASK=022 \
  PATH="/root/.local/bin:$PATH"

WORKDIR /app

# 只安装运行时依赖
RUN set -ex && \
  apt-get update && apt-get install -y --no-install-recommends \
  bash \
  curl \
  gosu \
  tini \
  openssl \
  && rm -rf /var/lib/apt/lists/* && \
  mkdir -p /home/ab && \
  groupadd -g 911 ab && \
  useradd -u 911 -g ab -d /home/ab -s /sbin/nologin ab

# 从构建阶段复制虚拟环境
COPY --from=builder /build/.venv /app/.venv

# 复制应用代码
COPY --chmod=755 backend/src/. ./src
COPY --chmod=755 backend/dist/. ./dist
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
EXPOSE 7892
VOLUME [ "/app/config" , "/app/data" ]
