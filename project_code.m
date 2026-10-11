
clc;
clear;
close all;

%% 1. SELECT ORIGINAL SCRIPTURE IMAGE

[fileName, folderName] = uigetfile( ...
    {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', 'Image Files'}, ...
    'Select Old Scripture Image');

if isequal(fileName, 0)
    disp('No image selected. Program stopped.');
    return;
end

[Iraw, colorMap] = imread(fullfile(folderName, fileName));

% Convert indexed image to RGB if required.
if ~isempty(colorMap)
    I = ind2rgb(Iraw, colorMap);
else
    I = Iraw;
end

% Handle RGB or RGBA images.
if ndims(I) == 3
    I = I(:,:,1:min(size(I,3),3));
    grayImage = rgb2gray(I);
else
    grayImage = I;
end

% Convert grayscale image to double precision [0,1].
G = im2double(grayImage);

%% 2. DISPLAY ORIGINAL IMAGE

figure('Name', '1. Original Image', 'Color', 'w');
imshow(I, 'InitialMagnification', 'fit');
title('Original Scripture Image');

%% 3. GRAYSCALE CONVERSION

figure('Name', '2. Grayscale Image', 'Color', 'w');
imshow(G, [], 'InitialMagnification', 'fit');
title('Grayscale Image');

%% 4. NOISE REDUCTION

Gden = wiener2(G, [3 3]);

figure('Name', '3. Noise Reduction', 'Color', 'w');
imshow(Gden, [], 'InitialMagnification', 'fit');
title('Image After Noise Reduction');

%% 5. ESTIMATE BACKGROUND ILLUMINATION

sigma = max(15, round(min(size(Gden)) / 30));

background = imgaussfilt(Gden, sigma);

% Prevent division by very small values.
background = max(background, 0.05);

figure('Name', '4. Estimated Background', 'Color', 'w');
imshow(background, [], 'InitialMagnification', 'fit');
title('Estimated Background Illumination');

%% 6. SHADOW CORRECTION

shadowCorrected = Gden ./ background;
shadowCorrected = min(max(shadowCorrected, 0), 1);

figure('Name', '5. Shadow Correction', 'Color', 'w');
imshow(shadowCorrected, [], 'InitialMagnification', 'fit');
title('Shadow-Corrected Image');

%% 7. LOCAL CONTRAST ENHANCEMENT USING CLAHE

contrastEnhanced = adapthisteq(shadowCorrected, ...
    'NumTiles', [8 8], ...
    'ClipLimit', 0.01);

figure('Name', '6. CLAHE Enhancement', 'Color', 'w');
imshow(contrastEnhanced, [], 'InitialMagnification', 'fit');
title('Local Contrast Enhancement Using CLAHE');

%% 8. BRIGHTNESS AND CONTRAST STRETCHING

limits = stretchlim(contrastEnhanced, [0.01 0.99]);

contrastStretched = imadjust(contrastEnhanced, limits, [0 1]);

figure('Name', '7. Brightness Enhancement', 'Color', 'w');
imshow(contrastStretched, [], 'InitialMagnification', 'fit');
title('Brightness and Contrast Enhanced Image');

%% 9. IMAGE SHARPENING

sharpened = imsharpen(contrastStretched, ...
    'Radius', 1, ...
    'Amount', 0.5, ...
    'Threshold', 0.02);

sharpened = min(max(sharpened, 0), 1);

figure('Name', '8. Sharpened Image', 'Color', 'w');
imshow(sharpened, [], 'InitialMagnification', 'fit');
title('Final Enhanced Grayscale Image');

%% 10. ADAPTIVE THRESHOLDING (WHITE BACKGROUND, BLACK TEXT)

sensitivity = 0.48;

% Local threshold: pixels BELOW this value are ink (dark foreground).
T = adaptthresh(sharpened, sensitivity, ...
    'ForegroundPolarity', 'dark', ...
    'NeighborhoodSize', 2*floor(size(sharpened)/16) + 1);

% Paper (brighter than threshold) = 1 = white, ink = 0 = black.
finalBinary = sharpened > T;

% Safety check: paper must be the majority of the page.
% If most pixels came out black, the polarity is reversed, so flip it.
if mean(finalBinary(:)) < 0.5
    finalBinary = ~finalBinary;
end

% Remove tiny black specks (increase 15 to remove more noise).
finalBinary = ~bwareaopen(~finalBinary, 15);

figure('Name', '9. Final Readable Image', 'Color', 'w');
imshow(finalBinary, 'InitialMagnification', 'fit');
title('Final Output: White Background and Black Text');


%% GRAPH 1: AVERAGE INTENSITY PROFILE

% Select the middle row of the image.
% This allows brightness variations to be compared along one scan line.

rowIndex = round(size(G, 1) / 2);

fig1 = figure('Name', 'Research Graph 1 - Intensity Profile', ...
    'Color', 'w');

plot(G(rowIndex, :), 'LineWidth', 1);
hold on;

plot(shadowCorrected(rowIndex, :), 'LineWidth', 1);
plot(sharpened(rowIndex, :), 'LineWidth', 1);

xlabel('Horizontal Pixel Position');
ylabel('Normalized Intensity');
title('Intensity Profile Along the Middle Image Row');

legend('Original', 'Shadow Corrected', 'Enhanced Grayscale');
ylim([0 1]);
grid on;
hold off;

%% GRAPH 2: FINAL TEXT AND BACKGROUND INTENSITY

% The final binary image contains:
% 0 = black text
% 1 = white background

blackPixelRatio = sum(finalBinary(:) == 0) / numel(finalBinary);
whitePixelRatio = sum(finalBinary(:) == 1) / numel(finalBinary);

fig2 = figure('Name', 'Research Graph 2 - Pixel Distribution', ...
    'Color', 'w');

bar([blackPixelRatio, whitePixelRatio]);

set(gca, 'XTick', 1:2, ...
    'XTickLabel', {'Black Text', 'White Background'});

ylabel('Fraction of Total Pixels');
title('Foreground and Background Pixel Distribution');
ylim([0 1]);
grid on;

%% GRAPH 3: ROW-WISE AVERAGE BRIGHTNESS

% Calculate average brightness for each row.
% This can help inspect large-scale brightness variation.

originalRowMean = mean(G, 2);
correctedRowMean = mean(shadowCorrected, 2);
enhancedRowMean = mean(sharpened, 2);

fig3 = figure('Name', 'Research Graph 3 - Row Brightness', ...
    'Color', 'w');

plot(originalRowMean, 'LineWidth', 1.2);
hold on;

plot(correctedRowMean, 'LineWidth', 1.2);
plot(enhancedRowMean, 'LineWidth', 1.2);

xlabel('Vertical Pixel Position');
ylabel('Mean Intensity');
title('Row-Wise Average Brightness Comparison');

legend('Original', 'Shadow Corrected', 'Enhanced Grayscale');
ylim([0 1]);
grid on;
hold off;

%% 11. SAVE ALL OUTPUT IMAGES

[~, baseName, ~] = fileparts(fileName);

outputFolder = fullfile(folderName, ...
    [baseName '_restoration_results']);

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

imwrite(G, fullfile(outputFolder, [baseName '_grayscale.png']));
imwrite(Gden, fullfile(outputFolder, [baseName '_denoised.png']));
imwrite(background, fullfile(outputFolder, [baseName '_estimated_background.png']));
imwrite(shadowCorrected, fullfile(outputFolder, [baseName '_shadow_corrected.png']));
imwrite(contrastEnhanced, fullfile(outputFolder, [baseName '_CLAHE_enhanced.png']));
imwrite(contrastStretched, fullfile(outputFolder, [baseName '_contrast_stretched.png']));
imwrite(sharpened, fullfile(outputFolder, [baseName '_enhanced_grayscale.png']));
imwrite(finalBinary, fullfile(outputFolder, [baseName '_final_binary.png']));
saveas(fig1, fullfile(outputFolder, ...
    [baseName '_graph1_intensity_profile.png']));

saveas(fig2, fullfile(outputFolder, ...
    [baseName '_graph2_pixel_distribution.png']));

saveas(fig3, fullfile(outputFolder, ...
    [baseName '_graph3_row_brightness.png']));
