import csv
import numpy as np
import matplotlib.pyplot as plt
from collections import defaultdict

data = defaultdict(lambda: {'bp': []})
with open('sweep_data.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        data[int(row['f_shift'])]['bp'].append(float(row['bp']))

f_shifts = sorted(list(data.keys()), reverse=True)
fig, axs = plt.subplots(len(f_shifts), 1, figsize=(10, 10), sharex=True)
IMPULSE_MAG = 16000.0

target_map = {9: "152 Hz", 8: "313 Hz", 6: "1243 Hz", 5: "2495 Hz"}

for idx, f in enumerate(f_shifts):
    freqs = np.linspace(20, 5000, len(data[f]['bp']))
    bp_db = 20 * np.log10(np.abs(data[f]['bp']) / IMPULSE_MAG + 1e-12)
    
    axs[idx].semilogx(freqs, bp_db, label='Band-Pass', color='green', alpha=0.7)
    axs[idx].set_title(f"Configured: f_shift={f} (~{target_map.get(f, 'Unknown')})")
    axs[idx].set_ylabel("Magnitude (dB)")
    axs[idx].set_xlim(20, 5000)
    axs[idx].set_ylim(-60, 10)
    axs[idx].grid(True, which="both", ls="--", alpha=0.5)

axs[-1].set_xlabel("Frequency (Hz)")
plt.tight_layout()
plt.savefig("sine_sweep_bode.png")
