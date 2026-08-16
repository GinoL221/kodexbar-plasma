FROM registry.opensuse.org/opensuse/tumbleweed:latest

LABEL org.opencontainers.image.source="https://github.com/GinoL221/kodexbar-plasma" \
      org.opencontainers.image.description="Qt 6, Kirigami, Plasma, Pillow, Noto Sans, and Breeze color schemes for KodexBar QML visual regression"

# Floating :latest, not a pinned digest: Tumbleweed is a rolling release and
# registry.opensuse.org garbage-collects old digests (the pinned sha256 this
# Dockerfile started from, copied from ci/qml-lint.Dockerfile, stopped
# resolving after a few months). This job is already continue-on-error and
# tolerates day-to-day package drift, so a floating tag trades
# reproducibility for a base image that keeps resolving.
#
# Base Qt6/Kirigami/Plasma set mirrors ci/qml-lint.Dockerfile so org.kde.kirigami
# resolves the same way it does for qmllint6 in that already-working image.
# plasma6-integration-plugin provides the "kde" QPA platform theme
# (KDEPlasmaPlatformTheme6.so) that QT_QPA_PLATFORMTHEME=kde loads for the
# Dark-scenario palette probe; it pulls in plasma6-workspace as a hard
# dependency, which is the bulk of this image's size.
RUN zypper --non-interactive install --no-recommends \
        breeze6 \
        fontconfig \
        git-core \
        kf6-kcmutils-imports \
        kf6-kirigami-imports \
        libplasma6-components \
        noto-sans-fonts \
        plasma5support6 \
        plasma6-integration-plugin \
        python3-Pillow \
        python3-base \
        qt6-declarative-imports \
        qt6-declarative-tools \
    && zypper clean --all

COPY ci/qml-import-smoke.qml /tmp/qml-import-smoke.qml
RUN qmllint6 /tmp/qml-import-smoke.qml && rm /tmp/qml-import-smoke.qml
