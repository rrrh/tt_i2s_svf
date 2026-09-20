import numpy as np
import matplotlib.pyplot as plt
import csv
from collections import defaultdict

fs = 48000
data = defaultdict(list)
IMPULSE_MAG = 16000.0 

with open('bode_data_os.csv', 'r') as f:
    reader = csv.DictReader(f)
    for row in reader:
        data[int(row['f_shift'])].append(float(row['bp']) / IMPULSE_MAG)

fig, ax = plt.subplots(figsize=(10, 6))

for f_shift, signals in data.items():
    freqs = np.fft.rfftfreq(len(signals), 1/fs)
    mag = 20 * np.log10(np.abs(np.fft.rfft(signals)) + 1e-12)
    ax.semilogx(freqs[1:], mag[1:], label=f'f_shift = {f_shift}')

ax.set_title("Band-Pass Response (Optimized 1x2 Core)")
ax.set_ylabel("Magnitude (dB)")
ax.set_xlabel("Frequency (Hz)")
ax.grid(True, which="both", ls="--", alpha=0.7)
ax.set_xlim(20, 24000)
ax.set_ylim(-60, 20)
ax.legend(loc="lower right")

plt.tight_layout()
plt.savefig("bode_svf_os.png")
