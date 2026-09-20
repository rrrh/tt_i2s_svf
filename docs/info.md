<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The core receives a stream of I2S data, processes it with a digital SVF and outputs the results via I2S.

## How to test

Feed I2S data into the filter, set the cutoff and resonance via SPI register writes, analyze the I2S output.

## External hardware

An I2S transmitter and an I2S receiver.
