from pynq import Overlay, allocate
import cv2
import numpy as np
import matplotlib.pyplot as plt
import time
import sys

sys.modules.pop('pynq.overlay', None)

overlay = Overlay("blur.bit", download=True)
dma = overlay.axi_dma_0
blur_ip = overlay.blurFilter_0 

img_bgr = cv2.imread("poza.jpg") 
img_bgra = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2BGRA)

height, width, channels = img_bgra.shape

kernel_size_val = 3

in_buffer = allocate(shape=(height, width, 4), dtype=np.uint8)
out_buffer = allocate(shape=(height, width, 4), dtype=np.uint8)

in_buffer[:] = img_bgra

blur_ip.write(0x00, height)           # 0x00 -> slv_reg0 -> height
blur_ip.write(0x04, width)            # 0x04 -> slv_reg1 -> width
blur_ip.write(0x08, channels)         # 0x08 -> slv_reg2 -> channels
blur_ip.write(0x0C, kernel_size_val)  # 0x0C -> slv_reg3 -> kernel_size

start_time = time.perf_counter()

dma.recvchannel.transfer(out_buffer)
dma.sendchannel.transfer(in_buffer)

dma.sendchannel.wait()
dma.recvchannel.wait()

end_time = time.perf_counter()

execution_time = end_time - start_time
print(f"Processing time (DMA + FPGA): {execution_time:.5f} seconds")



img_rezultat_rgb = cv2.cvtColor(out_buffer, cv2.COLOR_BGRA2RGB)
img_original_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

fig, axe = plt.subplots(1, 2, figsize=(16, 6)) 

axe[0].imshow(img_original_rgb)
axe[0].set_title("Original image")
axe[0].axis('off') 

axe[1].imshow(img_rezultat_rgb)
axe[1].set_title(f"FPGA Gaussian Blur Result - {execution_time:.5f} seconds")
axe[1].axis('off')

plt.tight_layout() 
plt.show()

in_buffer.freebuffer()
out_buffer.freebuffer()