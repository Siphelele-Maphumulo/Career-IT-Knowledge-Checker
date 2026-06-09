import os
paths=["src/resources/openrouter.properties.example","openrouter.properties.example"]
for path in paths:
    if os.path.exists(path):
        with open(path,"r",encoding="utf-8") as f:
            lines=f.readlines()
        with open(path,"w",encoding="utf-8") as f:
            for line in lines:
                if line.strip().startswith("openrouter.api.key="):
                    f.write("openrouter.api.key=your_openrouter_api_key_here\n")
                else:
                    f.write(line)
