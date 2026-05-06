import sys
import traceback

def main():
    try:
        sys.path.append('c:\\Mindgauge\\ml_backend\\training\\adult_training')
        import level1_diagnosis
        level1_diagnosis.train_model()
    except Exception as e:
        with open('trace.txt', 'w') as f:
            f.write(traceback.format_exc())

if __name__ == '__main__':
    main()
