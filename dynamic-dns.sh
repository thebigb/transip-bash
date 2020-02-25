#!/bin/bash
set -x

api_key_file="${TRANSIP_API_KEY_FILE}"
api_user="${TRANSIP_API_USER}"

dns_domain="${DYNAMIC_DNS_DOMAIN}"
dns_name="${DYNAMIC_DNS_NAME}"
dns_expire="${DYNAMIC_DNS_EXPIRE:-300}"
dns_type="${DYNAMIC_DNS_TYPE:-A}"

external_ip=$(dig @resolver1.opendns.com ANY myip.opendns.com +short)

json_body=$(cat <<EOT | tr -d '\n'
{
    "dnsEntry":
    {
        "name":"${dns_name}",
        "expire":"${dns_expire}",
        "type":"${dns_type}",
        "content":"${external_ip}"
    }
}
EOT
)

api_url="https://api.transip.nl/v6/domains/${dns_domain}/dns"
api_header="Authorization: Bearer $(./fetch-token.sh -u ${api_user} -g -e '1 minute' -k ${api_key_file} -p)"

function api_call()
{
    curl \
        --write-out "\n%{http_code}" \
        -s \
        -H "${api_header}" \
        -X "${1}" \
        -d "${3}" \
        "${2}"
}

function get_response_code()
{
    echo "${1}" | tail -n1
}

response=$(api_call PATCH "${api_url}" "${json_body}")

if [ $(get_response_code "${response}") -eq 404 ]; then
    response=$(api_call POST "${api_url}" "${json_body}")
    if [ $(get_response_code "${response}") -ne 201 ]; then
        echo "${response}"
    fi
fi
