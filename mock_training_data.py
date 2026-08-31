import pandas as pd
import numpy as np

def generate_spoiled_data(filename="mock_food_spoilage_data.csv", samples=300):
    data = []
    
    for i in range(samples):
        # Determine state based on index to simulate time passing
        if i < samples // 3:
            label = "fresh"
            temp = np.random.uniform(20, 24)
            hum = np.random.uniform(40, 50)
            gas = np.random.uniform(100, 250)
            load = np.random.uniform(99.5, 100.0) # % of original weight
        elif i < (2 * samples // 3):
            label = "medium"
            temp = np.random.uniform(23, 26)
            hum = np.random.uniform(50, 65)
            gas = np.random.uniform(350, 550)
            load = np.random.uniform(94, 98)
        else:
            label = "spoilt"
            temp = np.random.uniform(25, 30)
            hum = np.random.uniform(65, 80)
            gas = np.random.uniform(750, 1100)
            load = np.random.uniform(85, 92)
            
        data.append([i, temp, hum, gas, load, label])

    df = pd.DataFrame(data, columns=['timestamp', 'temp', 'hum', 'gas', 'load', 'label'])
    df.to_csv(filename, index=False)
    print(f"✅ Dataset generated: {filename}")

generate_spoiled_data()