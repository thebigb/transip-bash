#!/bin/bash

api_url="${TRANSIP_API_URL:-https://api.transip.nl/v6/auth}"
api_user="${TRANSIP_API_USER}"
api_key_file="${TRANSIP_API_KEY_FILE}"
token_read_only="false"
token_global_key="false"
token_expiration="30 minutes"
parse_output=false

function print_usage()
{
    echo ""
    echo "Usage:"
    echo "    $(basename "$0") -u|--user='foo' [-a|--api-url=https://api.transip.nl/v6/auth] [-r|--readonly] [-g|--globalkey] [-e|--expiration='30 minutes'] [-l|--label='some-label'] [-p|--parseoutput] [-h|--help]"
    echo ""
}

function check_dependencies()
{
    shift 1
    for arg in $@; do
        if ! which ${arg} > /dev/null || [ ! -x "$(which ${arg})" ]; then
            echo "Missing dependency '${arg}'"
            exit 4
        fi
    done
}

check_dependencies getopt curl openssl base64


opts=$(getopt \
    --options "a:u:k:rge:l:ph" \
    --longoptions "api-url:,user:,keyfile:,readonly,globalkey,expiration:,label:,parseoutput,help" \
    --name "$(basename "$0")" \
    -- "$@"
)

eval set --$opts

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--api-url)
            api_url=$2
            shift 2
            ;;
        -u|--user)
            api_user=$2
            shift 2
            ;;
        -k|--keyfile)
            api_key_file=$2
            shift 2
            ;;
        -r|--readonly)
            token_read_only="true"
            shift 1
            ;;
        -g|--globalkey)
            token_global_key="true"
            shift 1
            ;;
        -e|--expiration)
            token_expiration=$2
            shift 2
            ;;
        -l|--label)
            token_label=$2
            shift 2
            ;;
        -p|--parseoutput)
            parse_output=true
            shift 1
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

if [ -z "${api_user}" ]; then
    echo "No username provided"
    print_usage
    exit 1
fi

if [ -z "${api_key_file}" ]; then
    echo "No key file provided"
    print_usage
    exit 2
fi

if [ ! -f "${api_key_file}" ]; then
    echo "Provided key file does not exist"
    print_usage
    exit 3
fi

if [ -z "${token_label}" ]; then
    token_label="fetch-token-sh-$(openssl rand -hex 4)"
fi

nonce=$(openssl rand -hex 12)

json=$(cat <<EOT | tr -d '\n'
{"login":"${api_user}","nonce":"${nonce}","read_only":${token_read_only},"expiration_time":"${token_expiration}","label":"${token_label}","global_key":${token_global_key}}
EOT
)

signature=$(echo -n "${json}" | openssl dgst -sha512 -sign "${api_key_file}" | base64 -w0)

token_json=$(curl \
    -s \
    "${api_url}" \
    --data "${json}" \
    -H "Signature: ${signature}" \
    -H "Content-Type: application/json"
)

if $parse_output; then
    echo "$token_json" | cut -d':' -f2 | tr -d '"{}'
else
    echo "$token_json"
fi