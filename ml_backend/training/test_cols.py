import pandas as pd

data = pd.read_csv('c:\\Mindgauge\\ml_backend\\data\\adult_scores\\repetitive_thoughts_scores.csv', header=0)
data.columns = [str(col).strip() for col in data.columns]
all_cols = data.columns.tolist()
feature_cols = [
    col for col in all_cols 
    if col != all_cols[0] 
    and col != data.columns[-1]
    and "Total" not in col
    and "Prorated" not in col
    and "T_Score" not in col
]

with open('c:\\Mindgauge\\ml_backend\\training\\cols.txt', 'w') as f:
    f.write(str(feature_cols))
