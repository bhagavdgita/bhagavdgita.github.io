from flask import Flask,jsonify
import random, datetime
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


def getshlokaforday():
    x = datetime.datetime.today().strftime("%Y:%m:%d")
    random.seed(x)
    shlokas = [
        "0",
        "47",
        "72",
        "43",
        "42",
        "29",
        "47",
        "30",
        "28",
        "34",
        "42",
        "55",
        "20",
        "35",
        "27",
        "20",
        "24",
        "28",
        "78",
    ]
    r_int = random.randint(1, 18)
    r1_int = random.randint(1, int(shlokas[r_int]))
    return [r_int, r1_int]


@app.route("/")
def index():
    return jsonify([getshlokaforday()[0], getshlokaforday()[1]])


app.run(host="0.0.0.0", port=81)
