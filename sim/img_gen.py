from PIL import Image
import numpy as np
import matplotlib.pyplot as plt

def display_ycbcr_channels(image_path):
    # Open the image
    image = Image.open(image_path)
    
    # Convert to RGB if not already
    # image = image.convert('YCbCr')
    
    # Convert the image to a numpy array
    img_array = np.array(image)
    
    # Convert to YCbCr
    ycbcr_image = image.convert('YCbCr')
    ycbcr_array = np.array(ycbcr_image)
    y, cb, cr = ycbcr_image.split()
    x   = cb.convert('RGB')
    z = cr.convert('RGB')
    # fig, axs = plt.subplots(1, 4, figsize=(20, 5))

# Display each channel
    # axs[0].imshow(img_array)
    # axs[0].set_title("Original Image")
    # axs[0].axis('off')
    
    y.show(title="Y Channel")
    z.show(title="Cb Channel")
    x.show(title="Cr Channel")
        
    # Plotting the original image and the Y, Cb, Cr channels
    
    # Original Image

# Example usage
image_path = 'sim/kitty.jpg'  # Replace with your image path
display_ycbcr_channels(image_path)
