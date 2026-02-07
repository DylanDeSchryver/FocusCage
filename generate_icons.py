#!/usr/bin/env python3
"""Generate recolored app icon variants for FocusCage themes."""

from PIL import Image
import numpy as np
import os

BASE_ICON = "FocusCage/Assets.xcassets/AppIcon.appiconset/icon_1024.png"

# Theme colors (R, G, B) — background colors for each theme variant
THEMES = {
    "Ocean":   (10, 132, 255),    # #0A84FF — iOS system blue
    "Emerald": (48, 209, 88),     # #30D158 — iOS system green
    "Sunset":  (255, 107, 44),    # #FF6B2C — vibrant orange
    "Rose":    (255, 45, 85),     # #FF2D55 — iOS system pink
}

SIZES = {
    "1024": 1024,
    "120": 120,
    "240": 240,
    "360": 360,
}

def recolor_icon(img_array, new_bg_color):
    """Replace the indigo background with a new color, keeping white elements."""
    result = img_array.copy()
    
    # The icon has white elements on an indigo background
    # Detect non-white pixels (background) vs white pixels (cage/lock design)
    # White pixels have high R, G, B values
    if img_array.shape[2] == 4:  # RGBA
        r, g, b, a = result[:,:,0], result[:,:,1], result[:,:,2], result[:,:,3]
    else:  # RGB
        r, g, b = result[:,:,0], result[:,:,1], result[:,:,2]
    
    # Calculate "whiteness" — pixels close to white are the design
    whiteness = (r.astype(float) + g.astype(float) + b.astype(float)) / 3.0
    
    # Pixels that are clearly not white (< 200 avg) are background
    # Use a smooth blend for anti-aliased edges
    bg_mask = whiteness < 200
    edge_mask = (whiteness >= 200) & (whiteness < 240)
    
    # For clear background pixels, replace with new color
    new_r, new_g, new_b = new_bg_color
    
    # Get original background color for ratio-based recoloring
    # Original indigo is approximately (88, 81, 229) = #5851E5
    orig_r, orig_g, orig_b = 88.0, 81.0, 229.0
    
    for y in range(result.shape[0]):
        for x in range(result.shape[1]):
            pixel_whiteness = (float(result[y,x,0]) + float(result[y,x,1]) + float(result[y,x,2])) / 3.0
            if pixel_whiteness < 200:
                # Background pixel — map from original color space to new color
                # Preserve relative brightness
                orig_brightness = pixel_whiteness / ((orig_r + orig_g + orig_b) / 3.0)
                result[y,x,0] = min(255, int(new_r * orig_brightness))
                result[y,x,1] = min(255, int(new_g * orig_brightness))
                result[y,x,2] = min(255, int(new_b * orig_brightness))
            elif pixel_whiteness < 240:
                # Edge pixel — blend between new bg and white
                blend = (pixel_whiteness - 200) / 40.0
                result[y,x,0] = min(255, int(new_r * (1 - blend) + 255 * blend))
                result[y,x,1] = min(255, int(new_g * (1 - blend) + 255 * blend))
                result[y,x,2] = min(255, int(new_b * (1 - blend) + 255 * blend))
    
    return result

def recolor_icon_fast(img_array, new_bg_color):
    """Vectorized version for speed."""
    result = img_array.copy().astype(np.float64)
    
    r, g, b = result[:,:,0], result[:,:,1], result[:,:,2]
    whiteness = (r + g + b) / 3.0
    
    new_r, new_g, new_b = float(new_bg_color[0]), float(new_bg_color[1]), float(new_bg_color[2])
    orig_avg = (88.0 + 81.0 + 229.0) / 3.0
    
    # Background pixels (whiteness < 200)
    bg_mask = whiteness < 200
    brightness_ratio = np.where(bg_mask, whiteness / orig_avg, 0)
    
    result[:,:,0] = np.where(bg_mask, np.clip(new_r * brightness_ratio, 0, 255), result[:,:,0])
    result[:,:,1] = np.where(bg_mask, np.clip(new_g * brightness_ratio, 0, 255), result[:,:,1])
    result[:,:,2] = np.where(bg_mask, np.clip(new_b * brightness_ratio, 0, 255), result[:,:,2])
    
    # Edge pixels (200 <= whiteness < 240) — smooth blend
    edge_mask = (whiteness >= 200) & (whiteness < 240)
    blend = np.where(edge_mask, (whiteness - 200) / 40.0, 0)
    
    result[:,:,0] = np.where(edge_mask, np.clip(new_r * (1 - blend) + 255 * blend, 0, 255), result[:,:,0])
    result[:,:,1] = np.where(edge_mask, np.clip(new_g * (1 - blend) + 255 * blend, 0, 255), result[:,:,1])
    result[:,:,2] = np.where(edge_mask, np.clip(new_b * (1 - blend) + 255 * blend, 0, 255), result[:,:,2])
    
    return result.astype(np.uint8)


def main():
    img = Image.open(BASE_ICON).convert("RGBA")
    img_array = np.array(img)
    
    for theme_name, color in THEMES.items():
        print(f"Generating {theme_name} icons...")
        recolored = recolor_icon_fast(img_array, color)
        recolored_img = Image.fromarray(recolored, "RGBA")
        
        for size_name, size in SIZES.items():
            resized = recolored_img.resize((size, size), Image.LANCZOS)
            
            if size_name == "1024":
                # App icon asset
                icon_dir = f"FocusCage/Assets.xcassets/AppIcon-{theme_name}.appiconset"
                os.makedirs(icon_dir, exist_ok=True)
                output_path = os.path.join(icon_dir, f"icon_{size_name}.png")
                resized.save(output_path)
                
                # Write Contents.json
                contents = f'''{{\n  "images" : [\n    {{\n      "filename" : "icon_{size_name}.png",\n      "idiom" : "universal",\n      "platform" : "ios",\n      "size" : "1024x1024"\n    }}\n  ],\n  "info" : {{\n    "author" : "xcode",\n    "version" : 1\n  }}\n}}'''
                with open(os.path.join(icon_dir, "Contents.json"), "w") as f:
                    f.write(contents)
            else:
                # Image set for splash screen
                img_dir = f"FocusCage/Assets.xcassets/AppIconImage-{theme_name}.imageset"
                os.makedirs(img_dir, exist_ok=True)
                output_path = os.path.join(img_dir, f"icon_{size_name}.png")
                resized.save(output_path)
        
        # Write imageset Contents.json
        img_dir = f"FocusCage/Assets.xcassets/AppIconImage-{theme_name}.imageset"
        contents = f'''{{\n  "images" : [\n    {{\n      "filename" : "icon_120.png",\n      "idiom" : "universal",\n      "scale" : "1x"\n    }},\n    {{\n      "filename" : "icon_240.png",\n      "idiom" : "universal",\n      "scale" : "2x"\n    }},\n    {{\n      "filename" : "icon_360.png",\n      "idiom" : "universal",\n      "scale" : "3x"\n    }}\n  ],\n  "info" : {{\n    "author" : "xcode",\n    "version" : 1\n  }}\n}}'''
        with open(os.path.join(img_dir, "Contents.json"), "w") as f:
            f.write(contents)
        
        print(f"  ✓ {theme_name} done")
    
    print("\nAll icon variants generated!")

if __name__ == "__main__":
    main()
