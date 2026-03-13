#!/usr/bin/env bash

SRVPORT=4499
RSPFILE="response"

rm -f "$RSPFILE"
mkfifo "$RSPFILE"

cleanup() {
    rm -f "$RSPFILE"
    exit
}

trap cleanup EXIT

get_api() {
    while read -r line; do
        [ "$line" = $'\r' ] && break
    done
}

handleRequest() {

    get_api

    mod=$(fortune)

cat <<EOF > "$RSPFILE"
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Connection: close

<!DOCTYPE html>
<html>
<head>
<title>Wisecow Application</title>
</head>
<body style="font-family:Arial;text-align:center;margin-top:40px;">
<h1>🐄 Wisecow Application</h1>
<h3>Deployed on Kubernetes EKS</h3>
<pre>
$(cowsay "$mod")
</pre>
</body>
</html>
EOF
}

prerequisites() {
    for cmd in cowsay fortune nc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "$cmd is not installed"
            exit 1
        fi
    done
}

main() {

    prerequisites
    echo "Wisecow server running on port=$SRVPORT..."

    while true; do
        cat "$RSPFILE" | nc -l "$SRVPORT" | handleRequest
        sleep 0.01
    done
}

main
