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
    # Read HTTP request headers
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
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Welcome to Deployment of Wisecow Application using Kubernetes EKS</title>
<style>
body {
    font-family: Arial, sans-serif;
    background: linear-gradient(135deg, #2193b0, #6dd5ed);
    margin: 0;
    padding: 0;
    color: #fff;
}
header {
    background-color: rgba(0,0,0,0.2);
    padding: 20px;
    text-align: center;
}
.signature {
    background-color: rgba(255,255,255,0.9);
    color: #222;
    padding: 10px;
    text-align: center;
    font-weight: bold;
    border-radius: 6px;
    margin: 20px auto;
    width: 80%;
}
.fortune {
    background-color: #fff9c4;
    color: #1a237e;
    padding: 15px;
    font-family: monospace;
    white-space: pre;
    border: 1px solid #cce7ff;
    margin: 20px auto;
    width: 80%;
    border-radius: 6px;
}
</style>
</head>
<body>

<header>
<h1>Welcome to Deployment of Wisecow Application</h1>
</header>

<div class="signature">
✅ Successfully Deployed the Wisecow Application
</div>

<div class="fortune">
$(cowsay "$mod")
</div>

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
