import numpy as np
import matplotlib.pyplot as plt
import csv
from collections import defaultdict

fs = 48000
data = defaultdict(lambda: {'hp': [], 'bp': [], 'lp': []})
IMPULSE_MAGNITUDE = 16000.0 

with open('bode_data_os.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        f_shift = int(row['f_shift'])
        data[f_shift]['hp'].append(float(row['hp']) / IMPULSE_MAGNITUDE)
        data[f_shift]['bp'].append(float(row['bp']) / IMPULSE_MAGNITUDE)
        data[f_shift]['lp'].append(float(row['lp']) / IMPULSE_MAGNITUDE)

fig, axs = plt.subplots(3, 1, figsize=(10, 10), sharex=True)
titles = ["Low-Pass Response", "Band-Pass Response", "High-Pass Response"]
keys = ['lp', 'bp', 'hp']

for f_shift, signals in data.items():
    N = len(signals['hp'])
    freqs = np.fft.rfftfreq(N, 1/fs)
    
    for idx, f_type in enumerate(keys):
        mag = 20 * np.log10(np.abs(np.fft.rfft(signals[f_type])) + 1e-12)
        axs[idx].semilogx(freqs[1:], mag[1:], label=f'f_shift = {f_shift}')

for i, ax in enumerate(axs):
    ax.set_title(titles[i])
    ax.set_ylabel("Magnitude (dB)")
    ax.grid(True, which="both", ls="--", alpha=0.7)
    ax.set_xlim(20, 24000)
    ax.set_ylim(-60, 20)
    ax.legend(loc="lower right")

axs[2].set_xlabel("Frequency (Hz)")
plt.tight_layout()
plt.savefig("bode_svf_os.png")
