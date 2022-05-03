FROM ruby:2.6.9-slim

LABEL "maintainer"="Travis Truman <trumant@gmail.com>" \
      "repository"="https://github.com/trumant/terraform-module-versions-action" \
      "homepage"="https://github.com/trumant/terraform-module-versions-action" \
      "com.github.actions.name"="terraform-module-versions-action" \
      "com.github.actions.description"="Identify outdated terraform modules as github action" \
      "com.github.actions.icon"="check-circle" \
      "com.github.actions.color"="package"

WORKDIR /usr/src/app
ENV DEPENDABOT_NATIVE_HELPERS_PATH="/usr/src/app/native-helpers"

COPY ./src /usr/src/app
COPY ./src/run-action /usr/local/bin/run-action
RUN apt-get update && \
    apt-get install -y libxml2 libxml2-dev libxslt1-dev build-essential && \
    apt-get install -y curl git wget && \
    export PATH="$PATH:$DEPENDABOT_NATIVE_HELPERS_PATH/terraform/bin" && \
    bundle install && \
    mkdir -p $DEPENDABOT_NATIVE_HELPERS_PATH/terraform && \
    cp -r $(bundle show dependabot-terraform)/helpers $DEPENDABOT_NATIVE_HELPERS_PATH/terraform/helpers && \
    $DEPENDABOT_NATIVE_HELPERS_PATH/terraform/helpers/build $DEPENDABOT_NATIVE_HELPERS_PATH/terraform && \
    apt-get remove -y build-essential patch perl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/*

# By default, dependabot installs hcl2json v0.3.3 to parse Terraform files.
# This release has a bug (see https://github.com/tmccombs/hcl2json/issues/35) that
# causes a panic whenever a Terraform object has a null value.
#
# This bug was fixed in v0.3.4, so we overwrite the existing v0.3.3 installation of
# hcl2json with v0.3.4.
ARG HCL2JSON_URL="https://github.com/tmccombs/hcl2json/releases/download/v0.3.4/hcl2json_linux_amd64"
ARG HCL2JSON_INSTALL_PATH="${DEPENDABOT_NATIVE_HELPERS_PATH}/terraform/bin/hcl2json"
ARG HCL2JSON_CHECKSUM="219d01706bc421a4daf11498058fc5d35cae6e9f764e7677e45cc35252dae0f1"

RUN curl -sSLfo ${HCL2JSON_INSTALL_PATH} ${HCL2JSON_URL} && \
        echo ${HCL2JSON_CHECKSUM} ${HCL2JSON_INSTALL_PATH} | sha256sum -c && \
        chmod +x ${HCL2JSON_INSTALL_PATH}

CMD ["run-action"]
