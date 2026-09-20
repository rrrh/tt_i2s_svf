# Multiplierless SVF Audio Filter ASIC

## Overview
This project implements a digital Multiplierless State Variable Filter (SVF) designed for the Tiny Tapeout platform (targeting the IHP SG13G PDK). 

---

## Architecture

*   **`tt_um_audio_filter`**: The Tiny Tapeout top-level wrapper. It maps the standardized `ui_in` and `uo_out` pins to the internal I2S and SPI buses and connects the transceivers to the filter core.
*   **`audio_filter_core`**: The digital heart of the chip. It instantiates the DSP filter and the SPI register bank, linking the configuration registers directly to the filter's control inputs.
*   **`svf_multiplierless_os`**: The DSP engine. It divides the 50 MHz clock down to a 500 kHz internal tick. It utilizes a Zero-Order Hold (ZOH) on the incoming 48 kHz audio and performs Symplectic Euler integration to ensure unconditional stability and eliminate limit-cycle quantization noise, even at high frequencies and high resonance.
*   **`spi_reg_bank`**: A Mode 0 SPI Slave with 2-stage input synchronizers for safe clock-domain crossing. It handles parameter updates from an external microcontroller.
*   **`i2s_rx` & `i2s_tx`**: Bidirectional audio transceivers. They serialize and deserialize the standard 32-bit I2S frames (16-bit left channel, 16-bit right channel) into parallel data for the core.

---

## Pinout / I/O Mapping

### Input Pins (`ui_in`)
| Pin | Name | Description |
| :--- | :--- | :--- |
| `ui_in[0]` | `i2s_ws` | I2S Word Select (Frame Clock) |
| `ui_in[1]` | `i2s_sck` | I2S Serial Clock |
| `ui_in[2]` | `i2s_sd_in` | I2S Serial Data Input (Audio In) |
| `ui_in[3]` | `spi_cs_n` | SPI Chip Select (Active Low) |
| `ui_in[4]` | `spi_sck` | SPI Serial Clock |
| `ui_in[5]` | `spi_mosi` | SPI Master Out Slave In (Data In) |
| `ui_in[6]` | Unused | N/A |
| `ui_in[7]` | Unused | N/A |

### Output Pins (`uo_out`)
| Pin | Name | Description |
| :--- | :--- | :--- |
| `uo_out[0]` | `i2s_sd_thru` | Pass-through audio stream (Unfiltered) |
| `uo_out[1]` | `i2s_sd_lp` | Low-Pass filtered audio stream |
| `uo_out[2]` | `i2s_sd_bp` | Band-Pass filtered audio stream |
| `uo_out[3]` | `i2s_sd_hp` | High-Pass filtered audio stream |
| `uo_out[4]` | `spi_miso` | SPI Master In Slave Out (Data Out) |
| `uo_out[5:7]`| Unused | N/A |

---

## SPI Register Bank & Configuration

The filter's parameters can be modified dynamically at runtime via SPI. 

*   **Mode:** SPI Mode 0 (CPOL = 0, CPHA = 0)
*   **Transaction Length:** 16 bits (MSB first)
*   **Frame Structure:** `[15] W/R` | `[14:8] Address` | `[7:0] Data`

### Register Map

| Address | Name | Access | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `0x00` | Filter Control | R/W | `0x24` | Configures `q_shift` (resonance) and `f_shift` (cutoff frequency). |
| `0x01-0x7F` | Reserved | N/A | `0x00` | Unused addresses return zero. |

### Filter Control Details (Address `0x00`)

*   **`[7:4] q_shift` (Resonance):** Determines the damping factor. Higher values decrease damping (increase resonance). Default: `2`.
*   **`[3:0] f_shift` (Cutoff):** Determines the frequency tuning. Higher values exponentially lower the cutoff frequency (1 octave per step). Valid stable range at 500 kHz oversampling is `2` (highest cutoff, ~20 kHz) to `11` (lowest cutoff, ~3 Hz). Default: `4`.

### Write Example
To set `q_shift = 3` and `f_shift = 5` (Data payload `0x35`):
*   Header: Write (`1`), Address (`0x00`) -> `0x80`
*   Data: `0x35`
*   Full 16-bit Master TX: `16'h8035`
