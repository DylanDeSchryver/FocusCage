#!/usr/bin/env python3
"""Generate recolored app icon variants for FocusCage themes.

Alternate app icons MUST be loose PNG files in the bundle (not .xcassets).
iPhone icons need @2x (120x120) and @3x (180x180) variants.
"""

from PIL import Image
import numpy as np
import os

BASE_ICON = "FocusCage/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
OUTPUT_DIR = "FocusCage"  # Loose files go in the project folder

THEMES = {
    "Ocean":   (10, 132, 255),
    "Emerald": (48, 209, 88),
    "Sunset":  (255, 107, 44),
    "Rose":    (255, 45, 85),
}

# Alternate icon sizes for iPhone
ALT_ICON_SIZES = {
    "@2x": 120,
    "@3x": 180,
}

# Splash screen image set sizes
SPLASH_SIZES = {
    "120": 120,
    "240": 240,
    "360": 360,
}


def recolor_icon_fast(img_array, new_bg_color):
    """Vectorized recolor: replace indigo background, keep white design."""
    result = img_array.copy().astype(np.float64)

    r, g, b = result[:, :, 0], result[:, :, 1], result[:, :, 2]
    whiteness = (r + g + b) / 3.0

    new_r, new_g, new_b = float(new_bg_color[0]), float(new_bg_color[1]), float(new_bg_color[2])
    orig_avg = (88.0 + 81.0 + 229.0) / 3.0

    bg_mask = whiteness < 200
    brightness_ratio = np.where(bg_mask, whiteness / orig_avg, 0)

    result[:, :, 0] = np.where(bg_mask, np.clip(new_r * brightness_ratio, 0, 255), result[:, :, 0])
    result[:, :, 1] = np.where(bg_mask, np.clip(new_g * brightness_ratio, 0, 255), result[:, :, 1])
    result[:, :, 2] = np.where(bg_mask, np.clip(new_b * brightness_ratio, 0, 255), result[:, :, 2])

    edge_mask = (whiteness >= 200) & (whiteness < 240)
    blend = np.where(edge_mask, (whiteness - 200) / 40.0, 0)

    result[:, :, 0] = np.where(edge_mask, np.clip(new_r * (1 - blend) + 255 * blend, 0, 255), result[:, :, 0])
    result[:, :, 1] = np.where(edge_mask, np.clip(new_g * (1 - blend) + 255 * blend, 0, 255), result[:, :, 1])
    result[:, :, 2] = np.where(edge_mask, np.clip(new_b * (1 - blend) + 255 * blend, 0, 255), result[:, :, 2])

    return result.astype(np.uint8)


def main():
    img = Image.open(BASE_ICON).convert("RGBA")
    img_array = np.array(img)

    for theme_name, color in THEMES.items():
        print(f"Generating {theme_name} icons...")
        recolored = recolor_icon_fast(img_array, color)
        recolored_img = Image.fromarray(recolored, "RGBA")

        # --- Loose alternate icon PNGs (for setAlternateIconName) ---
        for suffix, size in ALT_ICON_SIZES.items():
            resized = recolored_img.resize((size, size), Image.LANCZOS)
            filename = f"AppIcon-{theme_name}{suffix}.png"
            output_path = os.path.join(OUTPUT_DIR, filename)
            resized.save(output_path)
            print(f"  ✓ {filename} ({size}x{size})")

        # --- Splash screen image set (stays in xcassets) ---
        img_dir = f"FocusCage/Assets.xcassets/AppIconImage-{theme_name}.imageset"
        os.makedirs(img_dir, exist_ok=True)
        for size_name, size in SPLASH_SIZES.items():
            resized = recolored_img.resize((size, size), Image.LANCZOS)
            resized.save(os.path.join(img_dir, f"icon_{size_name}.png"))

        contents = f'''{{\n  "images" : [\n    {{\n      "filename" : "icon_120.png",\n      "idiom" : "universal",\n      "scale" : "1x"\n    }},\n    {{\n      "filename" : "icon_240.png",\n      "idiom" : "universal",\n      "scale" : "2x"\n    }},\n    {{\n      "filename" : "icon_360.png",\n      "idiom" : "universal",\n      "scale" : "3x"\n    }}\n  ],\n  "info" : {{\n    "author" : "xcode",\n    "version" : 1\n  }}\n}}'''
        with open(os.path.join(img_dir, "Contents.json"), "w") as f:
            f.write(contents)

        print(f"  ✓ {theme_name} splash imageset done")

    print("\nAll icon variants generated!")


if __name__ == "__main__":
    main()
