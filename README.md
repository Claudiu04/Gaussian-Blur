
# FPGA Hardware Gaussian Blur Accelerator (Separable 2D Filter)

**[English](#english-version) | [Română](#versiunea-în-română)**

---

## <a name="english-version"></a>English

This repository contains a hardware IP (Intellectual Property) developed in SystemVerilog for applying a **Gaussian Blur** filter on RGB or Grayscale images. The project is highly optimized for Xilinx Zynq SoCs, utilizing a separable 2D convolution architecture to drastically reduce DSP slice and multiplier usage. It is designed for seamless integration with Xilinx AXI DMA.

### Key Features
* **Separable Filter Architecture:** Implements a 2-pass approach (1D Horizontal followed by 1D Vertical) instead of a direct 2D convolution. This breaks down complex spatial processing into efficient pipelined stages, maximizing high-frequency operation (>=100 MHz) without *Timing Violations*.
* **Configurable Kernel Size:** Hardware supports dynamic switching between **3x3, 5x5, 7x7, and 9x9** Gaussian kernels.
* **Optimized BRAM Utilization:** Explicitly utilizes `ram_style = "block"` pragmas for Vivado synthesis to map vertical line buffers efficiently to Block RAMs, preserving logic resources.
* **Dynamic Edge Padding:** The module automatically replicates edge pixels to correctly calculate the convolution window on the image boundaries, completely eliminating boundary bypass artifacts.
* **Auto-Flush & Reset:** Internal logic recognizes the DMA's `TLAST` signal, forcing a complete flush of the data pipeline and automatic counter reset to process consecutive images without software intervention.
* **Flexible Resolution & Channels:** Supports images with a width of up to **3840 pixels** (4K UHD) and operates on either 1 channel (Grayscale) or 3 channels (RGB).

### System Architecture

The module utilizes two standard AMBA AXI interfaces:
1. **AXI4-Stream (S_AXIS & M_AXIS):** For high-speed video stream transfer (32-bit pixels). Connects to an AXI DMA (MM2S and S2MM).
2. **AXI4-Lite (S_AXI_LITE):** For configuring control registers by the processor (PS) prior to starting the video transfer.

### Suggested Register Map (AXI4-Lite Memory Map)

| Offset | Register Name | Type | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | `HEIGHT` | R/W | Image height in pixels. |
| `0x04` | `WIDTH` | R/W | Image width in pixels. |
| `0x08` | `CHANNELS` | R/W | Number of channels (1 for Grayscale, 3/4 for RGB/RGBA). |
| `0x0C` | `KERNEL_SIZE` | R/W | Gaussian kernel size (0 = 3x3, 1 = 5x5, 2 = 7x7, 3 = 9x9). |

---

## <a name="versiunea-în-română"></a> Română

Acest repository conține un IP (Intellectual Property) hardware dezvoltat în SystemVerilog pentru aplicarea unui filtru **Gaussian Blur** pe imagini RGB sau Grayscale. Proiectul este puternic optimizat pentru SoC-uri Xilinx Zynq, utilizând o arhitectură de convoluție 2D separabilă pentru a reduce drastic utilizarea slice-urilor DSP și a multiplicatoarelor. Este conceput pentru o integrare directă cu Xilinx AXI DMA.

### Caracteristici Principale
* **Arhitectură de Filtru Separabil:** Implementează o abordare în 2 pași (1D Orizontal urmat de 1D Vertical) în loc de o convoluție 2D directă. Aceasta sparge procesarea spațială complexă în etaje de pipeline eficiente, maximizând frecvența de operare (>=100 MHz) fără *Timing Violations*.
* **Dimensiune Kernel Configurabilă:** Hardware-ul suportă comutarea dinamică între kernel-uri Gaussiene de **3x3, 5x5, 7x7 și 9x9**.
* **Utilizare Optimizată BRAM:** Folosește explicit directive de tip `ram_style = "block"` pentru sinteza în Vivado, mapând eficient line-buffer-ele verticale în Block RAM pentru a conserva resursele logice.
* **Edge Padding Dinamic:** Modulul replică automat pixelii de pe margini pentru a calcula corect fereastra de convoluție pe extremele imaginii, eliminând complet "efectul de ramă" (boundary bypass artifacts).
* **Auto-Flush & Reset:** Logica internă recunoaște semnalul `TLAST` de la DMA, forțând golirea completă a conductei de date și resetarea automată a contoarelor pentru a procesa imagini consecutive fără intervenție software.
* **Rezoluție și Canale Flexibile:** Suportă imagini cu lățimea de până la **3840 pixeli** (4K UHD) și operează fie pe 1 canal (Grayscale), fie pe 3 canale (RGB).

### Arhitectura Sistemului

Modulul utilizează două interfețe standard AMBA AXI:
1. **AXI4-Stream (S_AXIS & M_AXIS):** Pentru transferul de mare viteză al fluxului video (pixeli pe 32 de biți). Se conectează la un AXI DMA (MM2S și S2MM).
2. **AXI4-Lite (S_AXI_LITE):** Pentru configurarea registrelor de control de către procesor (PS) înainte de începerea transferului video.

### Harta Registrelor Sugerată (AXI4-Lite Memory Map)

| Offset | Nume Registru | Tip | Descriere |
| :--- | :--- | :--- | :--- |
| `0x00` | `HEIGHT` | R/W | Înălțimea imaginii în pixeli. |
| `0x04` | `WIDTH` | R/W | Lățimea imaginii în pixeli. |
| `0x08` | `CHANNELS` | R/W | Numărul de canale (1 pentru Grayscale, 3/4 pentru RGB/RGBA). |
| `0x0C` | `KERNEL_SIZE` | R/W | Dimensiunea kernel-ului Gaussian (0 = 3x3, 1 = 5x5, 2 = 7x7, 3 = 9x9). |