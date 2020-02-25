# What

Shell helpers to use the [TransIP REST API](https://www.transip.eu/transip/api/).

# Tools

## fetch-token.sh

### Dependencies

- `getopt`
- `curl`
- `openssl`
- `base64`

### Usage

```sh
./fetch-token.sh -u example -g -e '1 hour' -k mykey.pem
```

## dynamic-dns.sh

### Dependencies

- `fetch-token.sh`

### Usage

```sh
TRANSIP_API_KEY_FILE=mykey.pem TRANSIP_API_USER=transipdemo DYNAMIC_DNS_DOMAIN=example.com DYNAMIC_DNS_NAME=subdomain ./dynamic-dns.sh
```
