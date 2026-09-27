#!/usr/bin/env python3
"""
Generate a lightweight, high-contrast DerpFest boot animation (<= 150 KiB).
Resolution: 1200x1920 (SM-P205 portrait).
Format: ZIP_STORED (compression method 0, required by Android BootAnimation).
"""

import os
import sys
import shutil
import subprocess
import zipfile
from PIL import Image, ImageDraw, ImageFont

def generate(output_zip_path):
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../.."))
    owl_path = os.path.join(root_dir, "packages/apps/Launcher3/res/drawable/ic_derpowl.png")
    font_path = os.path.join(root_dir, "vendor/fontage/prebuilt/product/fonts/Circular-Std-Bold.ttf")

    if not os.path.exists(owl_path):
        raise FileNotFoundError(f"Owl icon not found at {owl_path}")

    # Small canvas (480x480) for lightweight asset and minimal memory footprint.
    # SurfaceFlinger automatically centers the animation on the display and clears the rest to black.
    W, H = 480, 480
    owl_raw = Image.open(owl_path)
    alpha = owl_raw.split()[3]

    # Derp owl is an alpha mask; tint to crisp white
    owl_white = Image.new("RGBA", owl_raw.size, (255, 255, 255, 0))
    owl_white.putalpha(alpha)

    # Scale owl to width 260 (keep aspect ratio)
    target_w = 260
    target_h = int(owl_raw.height * (target_w / owl_raw.width))
    owl_scaled = owl_white.resize((target_w, target_h), Image.Resampling.LANCZOS)

    # Setup typography
    if os.path.exists(font_path):
        font = ImageFont.truetype(font_path, 34)
    else:
        font = ImageFont.load_default()
    text = "D E R P F E S T"

    work_dir = "/tmp/derpfest_bootanim_gen"
    part0_dir = os.path.join(work_dir, "part0")
    if os.path.exists(work_dir):
        shutil.rmtree(work_dir)
    os.makedirs(part0_dir, exist_ok=True)

    # 4 breathing frames (factors from 0.70 to 1.00 at 4 fps = 1 second loop)
    factors = [0.70, 0.85, 1.00, 0.85]
    for idx, f in enumerate(factors):
        bg = Image.new("RGBA", (W, H), (0, 0, 0, 255))

        # Scale alpha
        r, g, b, a = owl_scaled.split()
        a_scaled = a.point(lambda p: int(p * f))
        frame_owl = Image.merge("RGBA", (r, g, b, a_scaled))

        owl_x = (W - target_w) // 2
        owl_y = 60
        bg.alpha_composite(frame_owl, (owl_x, owl_y))

        # Draw typography
        draw = ImageDraw.Draw(bg)
        bbox = font.getbbox(text)
        text_w = bbox[2] - bbox[0]
        text_x = (W - text_w) // 2
        text_y = owl_y + target_h + 30
        text_val = int(240 * f)
        draw.text((text_x, text_y), text, font=font, fill=(text_val, text_val, text_val, 255))

        # Flatten to RGB on black
        final_rgb = Image.new("RGB", (W, H), (0, 0, 0))
        final_rgb.paste(bg, mask=bg.split()[3])

        # Quantize to 64 indexed colors for small footprint (< 25KB/frame).
        # Explicitly use Quantize enum (LIBIMAGEQUANT if available in Pillow, otherwise MEDIANCUT).
        try:
            quant_method = getattr(Image.Quantize, "LIBIMAGEQUANT", Image.Quantize.MEDIANCUT)
            final_indexed = final_rgb.quantize(colors=64, method=quant_method)
        except Exception:
            final_indexed = final_rgb.quantize(colors=64, method=Image.Quantize.MEDIANCUT)

        frame_path = os.path.join(part0_dir, f"{idx:04d}.png")
        final_indexed.save(frame_path, optimize=True)

    # Write desc.txt (must have trailing newline)
    desc_path = os.path.join(work_dir, "desc.txt")
    with open(desc_path, "wb") as f:
        f.write(b"480 480 4\np 0 0 part0\n")

    # Package as uncompressed ZIP (ZIP_STORED)
    os.makedirs(os.path.dirname(os.path.abspath(output_zip_path)), exist_ok=True)
    if os.path.exists(output_zip_path):
        os.remove(output_zip_path)

    with zipfile.ZipFile(output_zip_path, "w", compression=zipfile.ZIP_STORED) as zf:
        zf.write(desc_path, arcname="desc.txt")
        for f in sorted(os.listdir(part0_dir)):
            fp = os.path.join(part0_dir, f)
            zf.write(fp, arcname=f"part0/{f}")

    sz = os.path.getsize(output_zip_path)
    print(f"Generated {output_zip_path}: {sz} bytes ({sz / 1024:.2f} KiB)")
    assert sz <= 150 * 1024, f"Bootanimation exceeded 150 KiB limit: {sz} bytes"

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "bootanimation.zip"
    generate(out)
