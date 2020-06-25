
import subprocess
import shutil


class CodeWrong(Exception):
    pass


def decode_type(code):
    len = int(code[0:2], 16)
    cells = [code[2+2*i:4+2*i] for i in range(len)]
    return cells, code[2*(len+1):]


class Compiler:
    def __init__(self, code):
        try:
            self.walkable, code = decode_type(code)
            self.water, code = decode_type(code)
            self.p1, code = decode_type(code)
            self.p2, code = decode_type(code)
            self.terminal, code = decode_type(code)
        except:
            raise CodeWrong("Input code is not properly formatted")
        self.validate()

    def compile(self):
        with open("../compiled.s", "w") as fh:
            self.dump(fh)
        subprocess.check_call(["make"], cwd="..")
        shutil.copy("../ammih.nes", "./ammih.nes")
        return "/static/ammih.nes"

    def validate(self):
        if len(self.p1) != 1:
            raise CodeWrong(
                "A single starting location for player A is required")
        if len(self.p2) != 1:
            raise CodeWrong(
                "A single starting location for player B is required")
        if len(self.terminal) != 2:
            raise CodeWrong("Two exit locations required")

    def dump(self, fh):
        def dump_cells(cells, length=True):
            if length:
                fh.write(f'.byte ${len(cells):02x}\n')
            if len(cells):
                hexadecimal = ", ".join(['$'+c for c in cells])
                fh.write(f'.byte {hexadecimal}\n')

        fh.write('map:\n')
        dump_cells(self.walkable)
        dump_cells(self.water)
        dump_cells(self.p1, length=False)
        dump_cells(self.p2, length=False)
        dump_cells(self.terminal, length=False)
        fh.write('.byte $10\n')
