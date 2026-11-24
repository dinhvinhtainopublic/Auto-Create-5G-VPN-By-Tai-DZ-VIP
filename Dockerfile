FROM alpine:3.19

# --- Dependencies ---
RUN apk add --no-cache \
    curl \
    bash \
    ca-certificates \
    tzdata \
    sqlite \
    nginx \
    gettext \
    && ln -sf /usr/share/zoneinfo/Asia/Tehran /etc/localtime

# --- Download 3x-ui ---
RUN curl -fsSL \
    https://github.com/mhsanaei/3x-ui/releases/download/v3.8.5/x-ui-linux-amd64.tar.gz \
    -o /tmp/x-ui.tar.gz \
    && tar -xzf /tmp/x-ui.tar.gz -C /usr/local/ \
    && rm /tmp/x-ui.tar.gz \
    && chmod +x /usr/local/x-ui/x-ui \
    && mkdir -p /etc/x-ui /var/log/nginx /var/lib/nginx/tmp

COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Railway injects $PORT at runtime — nginx will bind to it via envsubst
EXPOSE 8080

CMD ["/start.sh"]
