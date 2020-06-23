from flask import Flask, send_file, render_template
from compiler import Compiler

app = Flask('designer', static_url_path='/static/', static_folder='.')
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0


@app.route('/')
def designer():
    return send_file("designer.html")


@app.route('/testbench/<code>')
def new_code(code):
    compiler = Compiler(code)
    game = compiler.compile()
    return render_template("index.html", game=game, code=code)
