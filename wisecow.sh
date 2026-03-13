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
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Wisecow DevOps Deployment</title>

<style>

body {
font-family: Arial, sans-serif;
margin: 0;
padding: 0;
background: linear-gradient(to right, #2c3e50, #4ca1af);
color: white;
}

header {
text-align: center;
padding: 40px;
background: rgba(0,0,0,0.3);
}

header h1 {
margin: 0;
font-size: 36px;
}

header p {
margin-top: 10px;
font-size: 18px;
}

.container {
text-align: center;
padding: 30px;
}

.badges {
margin: 20px 0;
}

.badge {
display: inline-block;
background: #1e293b;
padding: 10px 18px;
margin: 6px;
border-radius: 20px;
border: 1px solid #334155;
font-size: 14px;
}

.success-box {
background: #16a34a;
padding: 15px;
margin: 20px auto;
width: 60%;
border-radius: 6px;
font-weight: bold;
}

.fortune {
background: #020617;
color: #22c55e;
padding: 20px;
margin: 30px auto;
width: 70%;
font-family: monospace;
white-space: pre;
border-radius: 6px;
border: 1px solid #334155;
}

footer {
text-align: center;
padding: 20px;
margin-top: 40px;
background: rgba(0,0,0,0.3);
}

</style>

</head>

<body>

<header>
<h1>🐄 Wisecow Application</h1>
<p>Deployed using CI/CD Pipeline on Kubernetes EKS</p>
</header>

<div class="container">

<div class="badges">
<span class="badge">Docker</span>
<span class="badge">Amazon ECR</span>
<span class="badge">GitHub Actions</span>
<span class="badge">Kubernetes</span>
<span class="badge">Amazon EKS</span>
</div>

<div class="success-box">
✅ Application Successfully Deployed
</div>

<div class="fortune">
$(cowsay "$mod")
</div>

</div>

<footer>
DevOps Demo Project | Wisecow Deployment
</footer>

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

while true
do
    cat "$RSPFILE" | nc -l "$SRVPORT" | handleRequest
    sleep 0.01
done

}

main
