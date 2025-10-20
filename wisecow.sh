#!/usr/bin/env bash

SRVPORT=4499
RSPFILE=response

rm -f $RSPFILE
mkfifo $RSPFILE

get_api() {
    read line
    echo $line
}

handleRequest() {
    # 1) Process the request
    get_api
    mod=$(fortune)

cat <<EOF > $RSPFILE
HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Deployment of Wisecow Application using Kubernetes EKS</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #74ABE2, #5563DE);
            margin: 0;
            padding: 0;
            color: #fff;
        }
        header {
            background-color: rgba(0, 0, 0, 0.2);
            color: #fff;
            padding: 20px;
            text-align: center;
        }
        .signature {
            background-color: rgba(255, 255, 255, 0.9);
            color: #222;
            padding: 10px;
            text-align: center;
            font-weight: bold;
            border-radius: 6px;
            margin: 20px auto;
            width: 80%;
        }
        .fortune {
            background-color: rgba(255, 255, 255, 0.85);
            color: #1a237e;
            padding: 15px;
            font-family: monospace;
            white-space: pre;
            border: 1px solid #cce7ff;
            margin: 20px auto;
            width: 80%;
            border-radius: 6px;
        }
        h2 {
            color: #fff;
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
    command -v cowsay >/dev/null 2>&1 &&
    command -v fortune >/dev/null 2>&1 ||
        {
            echo "Install prerequisites: cowsay, fortune"
            exit 1
        }
}

main() {
    prerequisites
    echo "Wisecow server running on port=$SRVPORT..."
    while true; do
        cat $RSPFILE | nc -l $SRVPORT | handleRequest
        sleep 0.01
    done
}

main
