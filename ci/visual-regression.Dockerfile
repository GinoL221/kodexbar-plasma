FROM registry.opensuse.org/opensuse/tumbleweed@sha256:486ca7bf37bf87be5f4401ad1965e908c405b7b17a0298665c5765f2d81df078

LABEL org.opencontainers.image.source="https://github.com/GinoL221/kodexbar-plasma" \
      org.opencontainers.image.description="Qt 6, Kirigami, Plasma, Pillow, Noto Sans, and Breeze color schemes for KodexBar QML visual regression"

# Base Qt6/Kirigami/Plasma set mirrors ci/qml-lint.Dockerfile so org.kde.kirigami
# resolves the same way it does for qmllint6 in that already-working image.
# `breeze6` is a best-effort guess for the package that ships
# /usr/share/color-schemes/BreezeLight.colors and BreezeDark.colors on Tumbleweed;
# it was not verified against a live zypper repo and may need correction after
# the first real run of this workflow (the job is continue-on-error, so a wrong
# name here fails visibly without blocking merges).
RUN zypper --non-interactive install --no-recommends \
        breeze6 \
        fontconfig \
        git-core \
        kf6-kcmutils-imports \
        kf6-kirigami-imports \
        libplasma6-components \
        noto-sans-fonts \
        plasma5support6 \
        python3-Pillow \
        python3-base \
        qt6-declarative-imports \
        qt6-declarative-tools \
    && zypper clean --all

COPY ci/qml-import-smoke.qml /tmp/qml-import-smoke.qml
RUN qmllint6 /tmp/qml-import-smoke.qml && rm /tmp/qml-import-smoke.qml
