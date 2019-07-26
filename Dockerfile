ARG ALPINE=alpine:3.10

FROM ${ALPINE} AS verify

RUN apk add --no-cache \
    gnupg

ARG HASHICORP_PGP_FINGERPRINT=91a6e7f85d05c65630bef18951852d87348ffc4c
ARG TERRAFORM_PLATFORM=linux_amd64
ARG TERRAFORM_VERSION=0.12.5

WORKDIR /tmp

ADD https://keybase.io/hashicorp/pgp_keys.asc?fingerprint=${HASHICORP_PGP_FINGERPRINT} hashicorp.asc
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS .
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig .
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TERRAFORM_PLATFORM}.zip .

RUN gpg --import hashicorp.asc
RUN gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN grep ${TERRAFORM_PLATFORM}.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -cs

WORKDIR /build/opt/local/bin

RUN unzip /tmp/terraform_${TERRAFORM_VERSION}_${TERRAFORM_PLATFORM}.zip

WORKDIR /build/opt/local/share/doc/terraform

ADD https://raw.githubusercontent.com/hashicorp/terraform/v${TERRAFORM_VERSION}/README.md .
ADD https://raw.githubusercontent.com/hashicorp/terraform/v${TERRAFORM_VERSION}/CHANGELOG.md .

FROM scratch
COPY --from=verify /build/ /
ENV PATH="/opt/local/bin"
ENTRYPOINT ["terraform"]
CMD ["help"]
