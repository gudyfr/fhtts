import os
import json
import re

def firstCharToUpper(str):
    return str[0].upper() + str[1:]

def trimPrecision(num):
    return float(f"{num:.3f}")

def dumpJsonAsLua(json,indent="", noIndent=False):
    carriageReturn = '' if noIndent else '\n'
    space = '' if noIndent else ' '
    if isinstance(json, dict):
        indent = '' if noIndent else indent + "   "
        f.write(f"{{{carriageReturn}{indent}")
        for key, value in json.items():            
            if re.match('^[a-zA-Z_][\d\w_]*$', key) is None:
                f.write(f"[\"{key}\"]{space}={space}")
            else:
                f.write(f"{key}{space}={space}")
            dumpJsonAsLua(value, indent, noIndent)
            f.write(f",{carriageReturn}{indent}")
        f.write("}")
    elif isinstance(json, list):
        indent = '' if noIndent else indent + "   "
        f.write(f"{{{carriageReturn}{indent}")
        for value in json:
            dumpJsonAsLua(value, indent, noIndent)
            f.write(f",{carriageReturn}{indent}")
        f.write("}")
    elif isinstance(json, str):
        f.write(f"\"{json}\"")
    elif isinstance(json, int):
        f.write(f"{json}")
    elif isinstance(json, float):
        f.write(f"{trimPrecision(json)}")
    elif isinstance(json, bool):
        f.write(f"{json}")
    elif isinstance(json, type(None)):
        f.write("nil")
    else:
        raise Exception(f"Unknown type {type(json)}")

for filename in os.listdir("../docs/"):
    if filename.endswith('.json'):
        with open(f"../docs/{filename}", 'r') as f:
            filename = filename[:-5]
            data = json.load(f)
            with open(f"../scripts/data/{filename}.human.lua", 'w') as f:
                f.write(firstCharToUpper(filename) + " = ")
                try :
                    dumpJsonAsLua(data)
                    pass
                except Exception as e:
                    print(f"Error while parsing {filename}: {e}")
                    f.write("nil")
                f.write("\n")
            with open(f"../scripts/data/{filename}.lua", 'w') as f:
                f.write(firstCharToUpper(filename) + "=")
                try :
                    dumpJsonAsLua(data,"",True)
                    pass
                except Exception as e:
                    print(f"Error while parsing {filename}: {e}")
                    f.write("nil")