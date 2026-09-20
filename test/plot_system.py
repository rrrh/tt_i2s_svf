import pandas as pd
import matplotlib.pyplot as plt

# Load the simulation data
df = pd.read_csv('system_out.csv')

# Create the plot
plt.figure(figsize=(12, 6))

# Plot the internal mathematical signals (dashed lines)
plt.plot(df['time'], df['lp'], label='Internal Low-Pass', linestyle='--', alpha=0.6)
plt.plot(df['time'], df['bp'], label='Internal Band-Pass', linestyle='--', alpha=0.6)
plt.plot(df['time'], df['hp'], label='Internal High-Pass', linestyle='--', alpha=0.6)

# Plot the actual physical output from the I2S transmitter (solid black line)
plt.plot(df['time'], df['out_tx'], label='Physical Output (Muxed)', color='black', linewidth=2)

plt.title('SVF Filter Output Multiplexer Verification')
plt.xlabel('Simulation Time (ps)')
plt.ylabel('Audio Amplitude')
plt.legend(loc='upper right')
plt.grid(True, linestyle=':', alpha=0.7)
plt.tight_layout()

# Save the generated graph
plt.savefig('system_out.png')
print("Plot successfully generated: system_out.png")
