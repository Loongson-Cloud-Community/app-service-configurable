#
# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#build stage
ARG BASE=cr.loongnix.cn/library/golang:1.19-alpine
FROM ${BASE} AS builder

ARG ALPINE_PKG_BASE="make git"
ARG ALPINE_PKG_EXTRA=""

ARG ADD_BUILD_TAGS=""

RUN apk add --update --no-cache ${ALPINE_PKG_BASE} ${ALPINE_PKG_EXTRA}
WORKDIR /app

ENV GO111MODULE=auto GOPROXY=https://goproxy.cn
COPY go.mod vendor* ./

COPY . .
RUN go mod tidy
ARG MAKE="make -e ADD_BUILD_TAGS=$ADD_BUILD_TAGS build"
RUN $MAKE

#final stage
FROM cr.loongnix.cn/library/alpine:3.11
LABEL license='SPDX-License-Identifier: Apache-2.0' \
  copyright='Copyright (c) 2023: Intel'
LABEL Name=app-service-configurable Version=${VERSION}

# dumb-init is required as security-bootstrapper uses it in the entrypoint script
RUN apk add --update --no-cache ca-certificates dumb-init

COPY --from=builder /app/Attribution.txt /Attribution.txt
COPY --from=builder /app/LICENSE /LICENSE
COPY --from=builder /app/res/ /res/
COPY --from=builder /app/app-service-configurable /app-service-configurable

EXPOSE 48095

# Must always specify the profile using
# environment:
#   - EDGEX_PROFILE: <profile>
# or use
# command: "-profile=<profile>"
# If not you will recive error:
# SDK initialization failed: Could not load configuration file (./res/configuration.toml)...

ENTRYPOINT ["/app-service-configurable"]
CMD ["-cp=consul.http://edgex-core-consul:8500", "--registry"]

