import os
import glob
from PIL import Image, ImageDraw, ImageFont

# Define source directory containing the 12 downloaded WebP files
src_dir = '/Users/doaaalkasaby/Library/Caches/Google/AndroidStudio2026.2.1/projects/e-commerce.2f5afbd7/.artifacts/b87cc819-2f6c-4bc2-874b-26d025652dd3/contact_sheet'
output_project_path = '/Users/doaaalkasaby/Desktop/FlutterProjects/e-commerce/assets/images/contact_sheet_preview.png'
output_artifact_path = '/Users/doaaalkasaby/Library/Caches/Google/AndroidStudio2026.2.1/projects/e-commerce.2f5afbd7/.artifacts/b87cc819-2f6c-4bc2-874b-26d025652dd3/contact_sheet_preview.png'

items = [
    {"filename": "01_luma_cotton_tshirt.webp", "store": "Luma | Fashion", "title": "Cotton T-shirt"},
    {"filename": "02_luma_straight_denim.webp", "store": "Luma | Fashion", "title": "Straight Denim Jeans"},
    {"filename": "03_luma_cream_sneakers.webp", "store": "Luma | Fashion", "title": "Everyday Cream Sneakers"},
    {"filename": "04_luma_evening_gown.webp", "store": "Luma | Fashion", "title": "Satin Evening Gown"},

    {"filename": "05_noura_soy_candle.webp", "store": "Noura | Gifts", "title": "Aromatherapy Soy Candle"},
    {"filename": "06_noura_ceramic_vase.webp", "store": "Noura | Gifts", "title": "Artisan Ceramic Vase"},

    {"filename": "07_toota_wooden_rainbow.webp", "store": "Toota | Kids", "title": "Wooden Rainbow Stacker"},
    {"filename": "08_toota_teddy_bear.webp", "store": "Toota | Kids", "title": "Plush Cuddle Teddy Bear"},

    {"filename": "09_dar_nordic_chair.webp", "store": "Dar | Home", "title": "Nordic Lounge Chair"},
    {"filename": "10_dar_brass_lamp.webp", "store": "Dar | Home", "title": "Brass Table Lamp"},

    {"filename": "11_velo_runner_shoe.webp", "store": "Velo | Sports", "title": "Ultra-Light Runner Shoe"},
    {"filename": "12_sera_radiant_serum.webp", "store": "Sera | Beauty", "title": "Radiant Serum Dropper"},
]

# Card layout configurations
tile_img_size = 340
tile_padding = 15
label_height = 65
card_w = tile_img_size + (tile_padding * 2)  # 370 px
card_h = tile_img_size + (tile_padding * 2) + label_height  # 435 px

grid_cols = 3
grid_rows = 4
grid_gap_x = 20
grid_gap_y = 20
margin_x = 30
header_height = 100
footer_height = 40

canvas_w = (margin_x * 2) + (grid_cols * card_w) + ((grid_cols - 1) * grid_gap_x)
canvas_h = header_height + (grid_rows * card_h) + ((grid_rows - 1) * grid_gap_y) + footer_height

# Colors
bg_color = (252, 241, 227)        # #FCF1E3 (App light background)
card_bg_color = (255, 255, 255)   # Pure White card
card_border_color = (225, 215, 202) # Soft warm border
header_bg = (107, 27, 47)         # #6B1B2F Primary Maroon
header_text_color = (255, 255, 255)
store_text_color = (107, 27, 47)   # Primary Maroon
title_text_color = (30, 30, 30)    # Dark Charcoal

canvas = Image.new('RGB', (canvas_w, canvas_h), bg_color)
draw = ImageDraw.Draw(canvas)

# Fonts
try:
    font_header = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    font_sub = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
    font_store = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 13)
    font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 15)
except Exception:
    font_header = ImageFont.load_default()
    font_sub = ImageFont.load_default()
    font_store = ImageFont.load_default()
    font_title = ImageFont.load_default()

# Header
draw.rectangle([0, 0, canvas_w, header_height], fill=header_bg)
draw.text((margin_x, 22), "STAGE A — PROPOSED PRODUCT PHOTOGRAPHY CONTACT SHEET", fill=header_text_color, font=font_header)
draw.text((margin_x, 62), "Clean studio product photography on white/off-white backgrounds (1200x1200 WebP)", fill=(230, 210, 215), font=font_sub)

# Composite 12 cards
for idx, item in enumerate(items):
    col = idx % grid_cols
    row = idx // grid_cols

    x0 = margin_x + col * (card_w + grid_gap_x)
    y0 = header_height + 20 + row * (card_h + grid_gap_y)
    x1 = x0 + card_w
    y1 = y0 + card_h

    # Card background & rounded border approximation
    draw.rectangle([x0, y0, x1, y1], fill=card_bg_color, outline=card_border_color, width=2)

    # Load image
    img_path = os.path.join(src_dir, item["filename"])
    if os.path.exists(img_path):
        img = Image.open(img_path).convert('RGB')
        img_resized = img.resize((tile_img_size, tile_img_size), Image.Resampling.LANCZOS)
        canvas.paste(img_resized, (x0 + tile_padding, y0 + tile_padding))

    # Divider line above labels
    div_y = y0 + tile_padding * 2 + tile_img_size
    draw.line([x0 + 10, div_y, x1 - 10, div_y], fill=(240, 235, 225), width=1)

    # Text Labels
    draw.text((x0 + tile_padding, div_y + 8), item["store"].upper(), fill=store_text_color, font=font_store)
    draw.text((x0 + tile_padding, div_y + 28), item["title"], fill=title_text_color, font=font_title)

# Save
os.makedirs(os.path.dirname(output_project_path), exist_ok=True)
os.makedirs(os.path.dirname(output_artifact_path), exist_ok=True)

canvas.save(output_project_path, 'PNG', quality=95)
canvas.save(output_artifact_path, 'PNG', quality=95)

print(f"✅ Contact sheet PNG generated successfully at:\n  - {output_project_path}\n  - {output_artifact_path}")
