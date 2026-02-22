import joblib
import os

results = []
for group in ["adult_model", "children_model"]:
    if not os.path.exists(group): continue
    for file in os.listdir(group):
        if file.endswith("_model.pkl"):
            path = os.path.join(group, file)
            try:
                model = joblib.load(path)
                if hasattr(model, 'n_features_in_'):
                    features = model.n_features_in_
                elif hasattr(model, 'num_feature'):
                    features = model.num_feature()
                else:
                    features = "Unknown"
                results.append(f"{group}/{file}: {features}")
            except Exception as e:
                results.append(f"{group}/{file}: Error {e}")

with open("model_info.txt", "w") as f:
    f.write("\n".join(results))
print("Done")
