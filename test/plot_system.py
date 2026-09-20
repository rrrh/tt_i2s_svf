import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv('system_out.csv')
f_shifts = df['f_shift'].unique()

fig, axs = plt.subplots(len(f_shifts), 1, figsize=(10, 10), sharex=False)

for idx, f in enumerate(f_shifts):
    subset = df[df['f_shift'] == f].copy()
    subset['sample_idx'] = range(len(subset))
    
    plot_data = subset.tail(250)
    
    axs[idx].plot(plot_data['sample_idx'], plot_data['in'], label='Input (440Hz Sine)', color='black', linestyle='--', alpha=0.5)
    axs[idx].plot(plot_data['sample_idx'], plot_data['lp'], label='Low-Pass', color='blue')
    axs[idx].plot(plot_data['sample_idx'], plot_data['bp'], label='Band-Pass', color='green')
    axs[idx].plot(plot_data['sample_idx'], plot_data['hp'], label='High-Pass', color='red')
    
    cutoff = "75 Hz" if f == 10 else "313 Hz" if f == 8 else "1243 Hz"
    axs[idx].set_title(f"Full System I2S Data Stream: f_shift={f} (Cutoff ~{cutoff})")
    axs[idx].set_ylabel("Amplitude")
    axs[idx].legend(loc="upper right")
    axs[idx].grid(True)

plt.xlabel("Sample Index")
plt.tight_layout()
plt.savefig("system_test_plots.png")
