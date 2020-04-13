#!/bin/bash
# appli qui permet l'automatisation de l'ouverture des ports de la freebox via son API
APP_ID="fw-fbx.sh"
APP_NAME="firewall"
APP_VERSION="0.0.1"
DEVICE_NAME="$(hostname -s)"
FREEBOX_BASE_URL='http://mafreebox.freebox.fr'

[ -z $DEBUG ] && exec 2>/dev/null || set -x
echo "***DEBUG***" >&2

config=${CONFIG:-"$HOME/.fw-fbx.conf"}
# set -eu
set -e
set -o pipefail

function read_config() {
  set -a
  . $config
  set +a
}

function set_param() {
  param=$1
  value=$2
  grep "$param" $config > /dev/null || echo "$param=$value" >> $config
  read_config
}


function post() {
  url=$1
  data=$2
  session_token=$3

  echo "POST $url" >&2
  echo "$data" >&2

  if [ "$session_token" != "" ]; then
    session_token_header="X-Fbx-App-Auth: $session_token"
  fi

  result=$(curl -s \
                -X POST \
                -H "Content-Type: application/json" \
                -H "$session_token_header" \
                -d "$data" \
                ${FREEBOX_BASE_URL}${url} | jq '.')

  echo "RESULT:" >&2
  echo "$result" >&2

  echo $result
}

function get() {
  url=$1 # '/api_version'

  echo "GET $url" >&2

  result=$(curl -s \
       ${FREEBOX_BASE_URL}${url} \
       | jq .)

  echo "RESULT:" >&2
  echo "$result" >&2
  echo "$result"
}


function hmac_sha1() {
  app_token=$1
  challenge=$2
  echo -n "$challenge" | openssl sha1 -hmac "$app_token" | awk '{print $2}'
}

echo "$APP_ID" >&2
echo "- config file: $config" >&2
[ -f $config ] || touch $config

read_config

api_version=$(get '/api_version' | jq -r '.api_version')
echo "api_version: $api_version"
# si le token est vide, on le récupère ainsi que le track_id grâce un POST pour l'appli:
if [ "$app_token" == "" ]; then
  data="{
    \"app_id\": \"$APP_ID\",
    \"app_name\": \"$APP_NAME\",
    \"app_version\": \"$APP_VERSION\",
    \"device_name\": \"$DEVICE_NAME\"
  }"

  result=$(post "/api/v4/login/authorize" "$data")

  app_token=$(echo $result| jq -r '.result.app_token')
  echo $result| jq -r '.result.app_token'
  set_param 'app_token' "'$app_token'"

  track_id=$(echo $result| jq -r '.result.track_id')
  set_param 'track_id' "$track_id"
fi

echo "app_token $app_token" >&2
echo "track_id: $track_id"

# on attend la confirmation sur l'écran de la FREEBOX
status='pending'
echo -n 'waiting'
while [ $status == 'pending' ]
do
  sleep 1
  result=$(get "/api/v4/login/authorize/$track_id")
  status=$(echo $result | jq -r '.result.status')
  challenge=$(echo $result | jq -r '.result.challenge')
  password_salt=$(echo $result | jq -r '.result.password_salt')
  echo -n '.'
done
echo ""

if [ "$status" != "granted" ]; then
  echo "Error: status $status"
  exit 1
fi

password=$(hmac_sha1 $app_token $challenge)
echo "password: $password" >&2

data="{
  \"app_id\": \"$APP_ID\",
  \"password\": \"$password\"
}"

port="{
    \"enabled\": \"true\",
    \"comment\": \"ssh on backup\",
    \"valid\": \"true\",
    \"src_ip\": \"0.0.0.0\",
    \"hostname\": \"m4800\",
    \"lan_port\": 22,
    \"wan_port_end\": 22,
    \"wan_port_start\": 22,
    \"lan_ip\": \"192.168.1.44\",
    \"ip_proto\": \"tcp\"
}"

result=$(post "/api/v4/login/session" "$data")
session_token=$(echo $result | jq -r '.result.session_token')

echo "session_token: $session_token" >&2

function fw_close_port() {
  put="{
    \"enabled\": false
  }"

  action=$(curl -s -X PUT \
                -H "Content-Type: application/json; charset=utf-8" \
                -H "X-Fbx-App-Auth: $session_token" \
                -d "$put" \
                $FREEBOX_BASE_URL/api/v4/fw/redir/5 | jq '.')
# 5 is id of firewall object; change it !!
  echo $action | jq '.success'
}

function fw_open_port() {
  put="{
    \"enabled\": true
  }"

  action=$(curl -s -X PUT \
                -H "Content-Type: application/json; charset=utf-8" \
                -H "X-Fbx-App-Auth: $session_token" \
                -d "$put" \
                $FREEBOX_BASE_URL/api/v4/fw/redir/5 | jq '.')
# 5 is id of firewall object; change it !!
  echo $action | jq '.success'
}

function fw_list_port() {
  put="{
    \"enabled\": true
  }"
  action=$(curl -s -X GET \
    -H "Content-Type: application/json; charset=utf-8" \
    -H "X-Fbx-App-Auth: $session_token" \
    -d "$put" \
    $FREEBOX_BASE_URL/api/v4/fw/redir/ | jq '.')
  echo $action | jq '.success'
  echo $action | jq '.'
}


fw_"$1"_port
