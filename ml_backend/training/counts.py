import pandas as pd

try:
    df1 = pd.read_csv('c:\\Mindgauge\\ml_backend\\data\\adult_scores\\level1_adult_scores.csv')
    df2 = pd.read_csv('c:\\Mindgauge\\ml_backend\\data\\children_scores\\level1_children_scores.csv')

    with open('c:\\Mindgauge\\ml_backend\\training\\counts.txt', 'w') as f:
        f.write("Adult counts:\n")
        f.write(df1['Clinical_Diagnosis'].value_counts().to_string())
        f.write("\n\nChildren counts:\n")
        f.write(df2['Clinical_Diagnosis'].value_counts().to_string())
        
except Exception as e:
    with open('c:\\Mindgauge\\ml_backend\\training\\counts.txt', 'w') as f:
        f.write(f"Error: {e}")
