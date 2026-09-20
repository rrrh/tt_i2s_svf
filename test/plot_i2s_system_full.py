import csv
import matplotlib.pyplot as plt
from collections import defaultdict

data = defaultdict(lambda: {'sample': [], 'bp': []})

with open('i2s_system_data.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        config = row['config']
        data[config]['sample'].append(int(row['sample']))
        data[config]['bp'].append(int(row['bp']))

configs = ['29', '28', '25']
titles = {
    '29': "Low Cutoff (~150 Hz) - 440 Hz Input Attenuated",
    '28': "Mid Cutoff (~313 Hz) - 440 Hz Input Passes",
    '25': "High Cutoff (~2495 Hz) - 440 Hz Input Passes"
}

fig, axs = plt.subplots(len(configs), 1, figsize=(10, 8), sharex=True)

for idx, cfg in enumerate(configs):
    if cfg not in data: continue
    
    axs[idx].plot(data[cfg]['sample'], data[cfg]['bp'], label='Band-Pass TX', color='green')
    axs[idx].set_title(f"Configuration 0x{cfg}: {titles.get(cfg, '')}")
    axs[idx].set_ylabel("Amplitude")
    axs[idx].grid(True, linestyle=':', alpha=0.7)
    axs[idx].set_xlim(200, 700) 
    axs[idx].set_ylim(-32768, 32767)
    axs[idx].legend(loc="upper right")

axs[-1].set_xlabel("Sample Index")
plt.tight_layout()
plt.savefig("i2s_system_full_plot.png")
