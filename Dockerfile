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

# We use these to dynamically replace hcl2json v0.3.3 with v0.3.4 prior to
# building the dependabot helpers.
#
# hcl2json v0.3.3 has a bug that causes a panic whenever a HCL file contains null values.
ARG OLD_HCL2JSON_VER="v0.3.3"
ARG OLD_HCL2JSON_CHECKSUM="24068f1e25a34d8f8ca763f34fce11527472891bfa834d1504f665855021d5d4"
ARG NEW_HCL2JSON_VER="v0.3.4"
ARG NEW_HCL2JSON_CHECKSUM="219d01706bc421a4daf11498058fc5d35cae6e9f764e7677e45cc35252dae0f1"

COPY ./src /usr/src/app
COPY ./src/run-action /usr/local/bin/run-action
RUN apt-get update && \
    apt-get install -y libxml2 libxml2-dev libxslt1-dev build-essential && \
    apt-get install -y curl git wget && \
    export PATH="$PATH:$DEPENDABOT_NATIVE_HELPERS_PATH/terraform/bin" && \
    bundle install && \
    mkdir -p $DEPENDABOT_NATIVE_HELPERS_PATH/terraform && \
    cp -r $(bundle show dependabot-terraform)/helpers $DEPENDABOT_NATIVE_HELPERS_PATH/terraform/helpers && \
    sed -i 's/${OLD_HCL2JSON_VER}/${NEW_HCL2JSON_VER}/g' "${DEPENDABOT_NATIVE_HELPERS_PATH}/terraform/helpers/build" && \
    sed -i 's/${OLD_HCL2JSON_CHECKSUM}/${NEW_HCL2JSON_CHECKSUM}/g' "${DEPENDABOT_NATIVE_HELPERS_PATH}/terraform/helpers/build" && \
    $DEPENDABOT_NATIVE_HELPERS_PATH/terraform/helpers/build $DEPENDABOT_NATIVE_HELPERS_PATH/terraform && \
    apt-get remove -y build-essential patch perl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /tmp/*


CMD ["run-action"]
