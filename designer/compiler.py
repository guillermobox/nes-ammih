import shutil
import subprocess


class CodeWrong(Exception):
    pass

class Compiler:
    def __init__(self, code):
        try:
            self.code = code
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
        if len(self.code['start_positions'][0]) != 1:
            raise CodeWrong(
                "A single starting location for player A is required")
        if len(self.code['start_positions'][1]) != 1:
            raise CodeWrong(
                "A single starting location for player B is required")
        if len(self.code['exits']) != 2:
            raise CodeWrong("Two exit locations required")

    def dump(self, fh):
        def dump_cells(cells, length=True):
            if length:
                fh.write(f'.byte ${len(cells):02x}\n')
            if len(cells):
                coordinates = ", ".join([f'${c[0]+3:1x}{c[1]+1:1x}' for c in cells])
                fh.write(f'.byte {coordinates}\n')

        fh.write('map:\n')
        dump_cells(self.code['walkable'] + self.code['exits'] + self.code['water'])
        dump_cells(self.code['water'])
        dump_cells(self.code['start_positions'][0], length=False)
        dump_cells(self.code['start_positions'][1], length=False)
        dump_cells(self.code['exits'], length=False)
        fh.write(f".byte {self.code.get('steps', 0):02x}\n")
