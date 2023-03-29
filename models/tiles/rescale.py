import os
import pywavefront
import numpy as np


def scale_obj_file(file_path, scale_factor):
    with open(file_path) as f:
        lines = f.readlines()
    vertices = []
    for line in lines:
        if line.startswith('v '):
            vertex = list(map(float, line.split()[1:]))
            vertex = [round(vertex[0] * scale_factor, 6), round(vertex[1] * scale_factor, 6), round(vertex[2] * scale_factor, 6)]
            vertices.append(vertex)
        else:
            continue
    output_dir = os.path.join(os.path.dirname(file_path), 'output')
    os.makedirs(output_dir, exist_ok=True)
    output_file_path = os.path.join(output_dir, os.path.basename(file_path))
    with open(output_file_path, 'w') as f:
        for line in lines:
            if line.startswith('v '):
                vertex = vertices.pop(0)
                f.write(f"v {vertex[0]:.6f} {vertex[1]:.6f} {vertex[2]:.6f}\n")
            else:
                f.write(line)


# Create the output directory if it doesn't exist
if not os.path.exists('output'):
    os.makedirs('output')

# Loop through all .obj files in the current directory
for filename in os.listdir('.'):
    if filename.endswith('.obj'):
        print(f'Scaling {filename}...')
        # Load the model from the .obj file
        scale_obj_file(filename, 0.035)

print('Done scaling all .obj files!')


