import subprocess

res = subprocess.run(['python', 'repetitive_thoughts.py'], cwd='c:\\Mindgauge\\ml_backend\\training\\adult_training', capture_output=True, text=True)
with open('c:\\Mindgauge\\ml_backend\\training\\eval_rep.txt', 'w') as f:
    f.write(f"STDOUT: {res.stdout}\n")
