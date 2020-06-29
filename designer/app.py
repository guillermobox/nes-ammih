from flask import Flask, send_file, render_template, request
from compiler import Compiler

app = Flask('designer', static_url_path='/static/', static_folder='.')
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0


@app.route('/')
def designer():
    return send_file("designer.html")


@app.route('/compile/', methods=["POST"])
def compile():
    try:
        code = request.get_json()
        compiler = Compiler(code).compile()
        return "success"
    except Exception as e:
        return str(e)


@app.route('/play/<id>')
def play(id):
    return render_template("index.html", game=id)