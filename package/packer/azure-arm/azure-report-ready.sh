#!/usr/bin/env bash

# check marker file
[[ -f /var/.azure-provision ]] && exit 0

# mount Azure-provided CD containing initial instance metadata
mount -o ro -t udf /dev/cdrom /media/cdrom >>/tmp/prov-log.txt

# grab user-data from the CD's ovf-env.xml file
USER_DATA_BASE64=$(grep "CustomData" </media/cdrom/ovf-env.xml | sed "s/.*<CustomData>\(.*\)<\/CustomData>.*/\1/")

if [[ -n "$USER_DATA_BASE64" ]]; then
    # decode
    USER_DATA=$(printf '%s' "$USER_DATA_BASE64" | base64 --decode 2>/dev/null)
    # append to k3OS configuration
    printf '\n%s' "$USER_DATA" >>/var/lib/rancher/k3os/config.yaml
fi

# query ContainerId and InstanceId from WireServer
GOAL_STATE=$(curl -X GET -H "x-ms-version: 2012-11-30" "http://168.63.129.16/machine?comp=goalstate" | tr -d "\r")
CONTAINER_ID=$(printf '%s' "$GOAL_STATE" | grep "ContainerId" | sed "s/.*<ContainerId>\(.*\)<\/ContainerId>.*/\1/")
INSTANCE_ID=$(printf '%s' "$GOAL_STATE"  | grep "InstanceId"  | sed "s/.*<InstanceId>\(.*\)<\/InstanceId>.*/\1/")

# construct XML response
read -r -d '' REPORT_READY_XML <<EOF
<Health>
    <GoalStateIncarnation>1</GoalStateIncarnation>
    <Container>
        <ContainerId>CONTAINER_ID</ContainerId>
        <RoleInstanceList>
            <Role>
            <InstanceId>INSTANCE_ID</InstanceId>
            <Health>
                <State>Ready</State>
            </Health>
            </Role>
        </RoleInstanceList>
    </Container>
</Health>
EOF
REPORT_READY_XML=$(printf '%s' "${REPORT_READY_XML}" | sed "s~CONTAINER_ID~${CONTAINER_ID}~;s~INSTANCE_ID~${INSTANCE_ID}~")

# post XML response to WireServer
curl \
    -X POST \
    -H "x-ms-version: 2012-11-30" \
    -H "x-ms-agent-name: WALinuxAgent" \
    -H "Content-Type: text/xml;charset=utf-8" \
    -d "${REPORT_READY_XML}" \
    "http://168.63.129.16/machine?comp=health"

# disable for subsequent reboots with marker file
touch /var/.azure-provision

# reboot after 30s delay
reboot -d 30 &