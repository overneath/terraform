ARG ALPINE=alpine:3.10
ARG TERRAFORM_PLATFORM=linux_amd64
ARG TERRAFORM_VERSION=0.12.5

FROM ${ALPINE} AS build

RUN apk add --no-cache \
    gnupg

ARG HASHICORP_PGP_FINGERPRINT=91a6e7f85d05c65630bef18951852d87348ffc4c
ARG TERRAFORM_PLATFORM
ARG TERRAFORM_VERSION

WORKDIR /tmp

ADD https://keybase.io/hashicorp/pgp_keys.asc?fingerprint=${HASHICORP_PGP_FINGERPRINT} hashicorp.asc
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS .
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig .
ADD https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${TERRAFORM_PLATFORM}.zip .

RUN gpg --import hashicorp.asc
RUN gpg --verify terraform_${TERRAFORM_VERSION}_SHA256SUMS.sig terraform_${TERRAFORM_VERSION}_SHA256SUMS
RUN grep ${TERRAFORM_PLATFORM}.zip terraform_${TERRAFORM_VERSION}_SHA256SUMS | sha256sum -cs

WORKDIR /layer/opt/local/bin

RUN unzip /tmp/terraform_${TERRAFORM_VERSION}_${TERRAFORM_PLATFORM}.zip

WORKDIR /layer/opt/local/share/doc/terraform

ADD https://raw.githubusercontent.com/hashicorp/terraform/v${TERRAFORM_VERSION}/README.md .
ADD https://raw.githubusercontent.com/hashicorp/terraform/v${TERRAFORM_VERSION}/CHANGELOG.md .


FROM ${ALPINE} AS provider
ARG TERRAFORM_PLATFORM
ARG TERRAFORM_PROVIDER_NAME=aws
ARG TERRAFORM_PROVIDER_VERSION="~> 2.21"
ARG TERRAFORM_VERSION
WORKDIR /work
COPY --from=build /layer/opt/local/bin/ /usr/local/bin/
COPY provider.tf.sh .
RUN set -x \
 && apk --no-cache add \
    ca-certificates \
 && sh -ex ./provider.tf.sh "${TERRAFORM_PROVIDER_NAME}" "${TERRAFORM_PROVIDER_VERSION}" \
 && terraform init
WORKDIR /layer/opt/local/bin
RUN cp -vf /work/.terraform/plugins/${TERRAFORM_PLATFORM}/terraform-provider-aws* .

FROM scratch AS terraform
COPY --from=build /layer/ /
ENV PATH="/opt/local/bin" \
    TF_IN_AUTOMATION=1 \
    TF_CLI_CONFIG_FILE=/opt/local/share/terraform
ENTRYPOINT ["terraform"]
CMD ["help"]
