FROM registry.opensuse.org/opensuse/tumbleweed@sha256:486ca7bf37bf87be5f4401ad1965e908c405b7b17a0298665c5765f2d81df078

LABEL org.opencontainers.image.source="https://github.com/GinoL221/kodexbar-plasma" \
      org.opencontainers.image.description="Minimal Qt 6, Kirigami, and Plasma image for KodexBar QML linting"

RUN zypper --non-interactive install --no-recommends \
        git-core \
        kf6-kcmutils-imports \
        kf6-kirigami-imports \
        libplasma6-components \
        plasma5support6 \
        python3-base \
        qt6-declarative-imports \
        qt6-declarative-tools \
    && zypper clean --all

COPY ci/qml-import-smoke.qml /tmp/qml-import-smoke.qml
RUN qmllint6 /tmp/qml-import-smoke.qml && rm /tmp/qml-import-smoke.qml
