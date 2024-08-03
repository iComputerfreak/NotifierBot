# ================================
# Build image
# ================================
FROM swift:5.9-jammy as build

# Install OS updates
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y\
    && rm -rf /var/lib/apt/lists/*

# Set up a build area
WORKDIR /build

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Shared ./Shared

WORKDIR /build/NotifierBot

COPY ./NotifierBot/Package.* ./
RUN swift package resolve --skip-update \
        $([ -f ./Package.resolved ] && echo "--force-resolved-versions" || true)

# Copy entire repo into container
COPY . ..

# Go into the NotifierBot subdirectory for building
WORKDIR /build/NotifierBot

# Build everything, with optimizations
RUN swift build -c release --static-swift-stdlib \
    # Workaround for https://github.com/apple/swift/pull/68669
    # This can be removed as soon as 5.9.1 is released, but is harmless if left in.
    -Xlinker -u -Xlinker _swift_backtrace_isThunkFunction

# Switch to the staging area
WORKDIR /staging

# Copy main executable to staging area
RUN cp "$(swift build --package-path /build/NotifierBot -c release --show-bin-path)/Notifier" ./

# Copy resources bundled by SPM to staging area
RUN find -L "$(swift build --package-path /build/NotifierBot -c release --show-bin-path)/" -regex '.*\.resources$' -exec cp -Ra {} ./ \;

# ================================
# Run image
# ================================
FROM swift:5.9-jammy-slim

# Make sure all system packages are up to date, and install only essential packages.
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      ca-certificates \
      tzdata \
# If your app or its dependencies import FoundationNetworking, also install `libcurl4`.
      libcurl4 \
# If your app or its dependencies import FoundationXML, also install `libxml2`.
      # libxml2 \
    && rm -r /var/lib/apt/lists/*

# Create a bot user and group with /app as its home directory
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app bot

# Switch to the new home directory
WORKDIR /app

# Copy built executable and any staged resources from builder
COPY --from=build --chown=bot:bot /staging /app

# Provide configuration needed by the built-in crash reporter and some sensible default behaviors.
ENV SWIFT_ROOT=/usr SWIFT_BACKTRACE=enable=yes,sanitize=yes,threads=all,images=all,interactive=no

# Ensure all further commands run as the bot user
USER bot:bot

# Start the bot when the image is run
ENTRYPOINT ["./Notifier"]
CMD []
