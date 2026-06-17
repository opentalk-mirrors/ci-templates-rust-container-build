# SPDX-FileCopyrightText: OpenTalk GmbH <mail@opentalk.eu>
#
# SPDX-License-Identifier: EUPL-1.2

FROM quay.io/skopeo/stable:v1.20

COPY create-container-tags.sh /usr/local/bin/create-container-tags

RUN chmod +x /usr/local/bin/create-container-tags
