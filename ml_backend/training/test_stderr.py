import subprocess
import os

res = subprocess.run(['python', 'level1_diagnosis.py'], cwd='c:\\Mindgauge\\ml_backend\\training\\adult_training', capture_output=True, text=True)
with open('c:\\Mindgauge\\ml_backend\\training\\error_adult.txt', 'w') as f:
    f.write(f"RETURN CODE: {res.returncode}\n")
    f.write(f"STDOUT: {res.stdout}\n")
    f.write(f"STDERR: {res.stderr}\n")

res2 = subprocess.run(['python', 'level1_diagnosis.py'], cwd='c:\\Mindgauge\\ml_backend\\training\\children_training', capture_output=True, text=True)
with open('c:\\Mindgauge\\ml_backend\\training\\error_children.txt', 'w') as f:
    f.write(f"RETURN CODE: {res2.returncode}\n")
    f.write(f"STDOUT: {res2.stdout}\n")
    f.write(f"STDERR: {res2.stderr}\n")
