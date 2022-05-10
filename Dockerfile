# Sample Dockerfile, used to illustrate how to set up target-aware `make build`.
# All files to be included in the image are assumed to be in a directory, at the
# same level as this Dockerfile, named 'context'
FROM alpine:3.15

ARG user=image-user
ARG group=image-group
ARG uid=1000
ARG gid=1000
ARG build_time

ENV INSTALL_DIR=/opt/my-package

RUN apk update && apk upgrade
RUN apk add --no-cache \
    gcompat \
    bash \
    python3 \
    python3-dev \
    libffi-dev \
    build-base \
    py3-pip

# Alpine's default adduser/addgroup commands are provided by BusyBox - and those
# implementations can't create IDs > 256000. As our computers are joined to an
# Active Directory domain (which provides IDs that can easily exceed this
# limit) we need to use the standalone commands:
RUN apk add shadow

RUN pip install --upgrade pip

RUN groupadd --non-unique --gid ${gid} ${group}
RUN useradd  --non-unique --gid ${gid} --uid ${uid} --no-log-init --create-home ${user}
# See if our GID has been passed through successfully.
# RUN ls -aln /home
RUN >&2 echo "Created user '${user}' (${uid}) in group '${group}' (${gid})."

COPY ./extra/entrypoint.sh /entrypoint.sh
# You shouldn't have to set executable bit on entrypoint in Dockerfile if it was
# set with "git add --chmod=+x..."
# RUN chmod +x //entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["start"]

COPY --chown="${user}:${group}" ./package ${INSTALL_DIR}
ENV PATH=${INSTALL_DIR}:${PATH}
ENV BUILD_TIME=${build_time}

WORKDIR ${INSTALL_DIR}
USER ${user}