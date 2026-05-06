import os
import subprocess
import re

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    
    categories = ['adult_training', 'children_training']
    
    overall_metrics = []
    
    print("="*60)
    print("🧠 Starting Overall Mental Health Disorders Model Evaluation")
    print("="*60)
    
    for category in categories:
        category_dir = os.path.join(base_dir, category)
        print(f"\nEvaluating models in {category.upper()}...")
        
        # Discover all python scripts in the directory
        scripts = [f for f in os.listdir(category_dir) if f.endswith('.py') and f != '__init__.py']
        
        # Optional: You may want to exclude level1_diagnosis.py if it's considered outside of the specific mental health disorders 
        # (since level1_diagnosis.py is the multi-class classifier)
        # However, we will just parse whatever gives us Accuracy and F1 Score.
        
        category_accuracies = []
        category_f1s = []

        for script in scripts:
            script_path = os.path.join(category_dir, script)
            disorder_name = script.replace('.py', '').replace('_', ' ').title()
            print(f"\n  -> Training and Evaluating: {disorder_name} model")
            
            # Run the training script and capture output
            result = subprocess.run(['python', script], cwd=category_dir, capture_output=True, text=True, encoding='utf-8')
            output = result.stdout
            
            if result.returncode != 0:
                print(f"     [ERROR] Script {script} failed. Stderr:\n{result.stderr}")
                continue
                
            # Regex to find Accuracy and F1
            acc_match = re.search(r"Accuracy:\s*([0-9.]+)", output)
            f1_match = re.search(r"F1 Score \(Weighted\):\s*([0-9.]+)", output)
            
            if not acc_match and not f1_match:
                # E.g level1_diagnosis.py uses accuracy_score but prints it formatted differently
                acc_match_alt = re.search(r"Model Accuracy:\s*([0-9.]+)", output) # from children's level1
                if acc_match_alt:
                    # It's a percentage, convert back to decimal
                    acc_val = float(acc_match_alt.group(1)) / 100.0
                    print(f"     ✅ Accuracy: {acc_val:.4f}")
                    category_accuracies.append(acc_val)
                else:
                    print(f"     [INFO] Could not find specific metric output for {disorder_name}.")
                continue
                
            acc_val = float(acc_match.group(1)) if acc_match else None
            f1_val = float(f1_match.group(1)) if f1_match else None
            
            print(f"     ✅ Accuracy: {acc_val:.4f} | F1 Score: {f1_val:.4f}")
            
            if acc_val is not None:
                category_accuracies.append(acc_val)
            if f1_val is not None:
                category_f1s.append(f1_val)
                
        # Calculate Category Averages
        if category_accuracies:
            avg_acc = sum(category_accuracies) / len(category_accuracies)
            avg_f1 = sum(category_f1s) / len(category_f1s) if category_f1s else 0.0
            overall_metrics.append({'type': category, 'acc': avg_acc, 'f1': avg_f1})
            print(f"  ================================================")
            print(f"  📊 {category.upper()} AVERAGE Accuracy: {avg_acc:.4f} | F1 Score: {avg_f1:.4f}")
            print(f"  ================================================\n")
            
    # Calculate System Overall Average
    print("="*60)
    print("🌟 SYSTEM OVERALL PERFORMANCE (All Disorders Combined) 🌟")
    print("="*60)
    
    if overall_metrics:
        total_acc = sum([m['acc'] for m in overall_metrics]) / len(overall_metrics)
        total_f1 = sum([m['f1'] for m in overall_metrics]) / len(overall_metrics)
        print(f"OVERALL SYSTEM ACCURACY : {total_acc:.4f}")
        print(f"OVERALL SYSTEM F1 SCORE : {total_f1:.4f}")
    else:
        print("No metrics collected.")
    print("="*60)
    
if __name__ == '__main__':
    main()
