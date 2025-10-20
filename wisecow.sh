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
    <title>Kubernetes Knowledge Center</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f7fa;
            margin: 0;
            padding: 0;
        }
        header {
            background-color: #4a90e2;
            color: white;
            padding: 20px;
            text-align: center;
        }
        .signature {
            background-color: #fff;
            padding: 10px;
            text-align: center;
            font-weight: bold;
        }
        .fortune {
            background-color: #e6f7ff;
            padding: 15px;
            font-family: monospace;
            white-space: pre;
            border: 1px solid #cce7ff;
            margin: 20px;
        }
        .section {
            margin: 20px;
            padding: 20px;
            border-radius: 8px;
        }
        .section:nth-child(even) {
            background-color: #ffffff;
        }
        .section:nth-child(odd) {
            background-color: #f0f0f5;
        }
        h2 {
            color: #333;
        }
        .question {
            font-weight: bold;
            color: #1a237e;
        }
        .answer {
            margin-top: 5px;
            color: #2e7d32;
        }
    </style>
</head>
<body>
    <header>
        <h1>Welcome to deployment of wisecow application</h1>
    </header>

    <div class="signature">
        Successfully deployed the wisecow application 
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
    echo "Wisdom served on port=$SRVPORT..."

    while true; do
        cat $RSPFILE | nc -l $SRVPORT | handleRequest
        sleep 0.01
    done
}

main
