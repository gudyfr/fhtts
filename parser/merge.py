import os
import json

merged_data = []
for filename in os.listdir("out"):
    if filename.endswith('.json') and not filename in ['scenarioData.json','processedScenarios.json','processedScenarios.human.json'] :
        with open(f"out/{filename}", 'r') as f:
            data = json.load(f)
            merged_data.append(data)

with open('out/scenarioData.json', 'w') as f:
    json.dump(merged_data, f,indent=2)