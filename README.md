# Image Enhancement and Shadow Removal for Improved Text Visibility

## Overview

This project uses MATLAB and classical Digital Image Processing (DIP) techniques to improve text visibility in document images affected by shadows, uneven illumination, low contrast, and noise. The objective is to produce a clearer image with **black text on a white background**.

## Methodology

The input image is processed through the following stages:

1. **Grayscale Conversion:** Converts the input image into grayscale for intensity-based processing.
2. **Noise Reduction:** Uses a Wiener filter to reduce unwanted noise.
3. **Background Estimation:** Applies Gaussian filtering to estimate background illumination.
4. **Shadow Correction:** Reduces uneven illumination using background-based intensity correction.
5. **Contrast Enhancement:** Uses CLAHE and contrast stretching to improve text visibility.
6. **Sharpening:** Enhances the apparent clarity of character boundaries.
7. **Adaptive Thresholding:** Separates dark text from the background using locally calculated thresholds.
8. **Morphological Filtering:** Removes small unwanted foreground components to produce the final binary image.

## Tools and Technologies

* **Language:** MATLAB
* **Domain:** Digital Image Processing
* **Techniques:** Wiener filtering, Gaussian filtering, shadow correction, CLAHE, contrast stretching, sharpening, adaptive thresholding, and morphological filtering.

## Conclusion

The project demonstrates how classical image processing techniques can be combined to improve document visibility and generate a binary image suitable for reading and further analysis. The final quality depends on the input image and the selected processing parameters.
