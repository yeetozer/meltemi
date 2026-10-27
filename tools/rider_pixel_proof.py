#!/usr/bin/env python3
"""Measure captured board pixels using the engine's projected sprite transform.

Run after editor --capture snapshots. No art or gameplay pixels are synthesized.
Alpha masks project the original board texture; statistics sample final screenshots,
including occlusion. Cream/nose counts additionally require screenshot colour matches.
"""
import json
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'art/qa/rider-v4'
OUT.mkdir(parents=True, exist_ok=True)
MODES = {'returning': 'menu', 'riding': 'gameplay_straight', 'left_carve': 'gameplay_left_carve', 'right_carve': 'gameplay_right_carve', 'airborne_flip': 'gameplay_flip', 'airborne_grab': 'gameplay_grab'}
texture = np.asarray(Image.open(ROOT / 'game/assets/sprites/board_classic.png').convert('RGBA'))
proof = {}
crops = {}
for mode, name in MODES.items():
    image = Image.open(ROOT / f'build/qa/{mode}.png').convert('RGB')
    image.save(OUT / f'{name}.png')
    meta = json.loads((ROOT / f'build/qa/{mode}.json').read_text())
    a, b, c, d, ox, oy = meta['board_transform']
    inverse = np.linalg.inv(np.array([[a, c], [b, d]]))
    yy, xx = np.indices((image.height, image.width))
    local = inverse @ np.stack([xx.ravel() + .5 - ox, yy.ravel() + .5 - oy])
    tx = np.floor(local[0] + texture.shape[1] / 2).astype(int)
    ty = np.floor(local[1] + texture.shape[0] / 2).astype(int)
    valid = (tx >= 0) & (tx < texture.shape[1]) & (ty >= 0) & (ty < texture.shape[0])
    source = np.zeros((tx.size, 4), dtype=np.uint8)
    source[valid] = texture[ty[valid], tx[valid]]
    mask = source[:, 3] > 220
    pixels = np.asarray(image).reshape(-1, 3)
    mx, my = xx.ravel()[mask], yy.ravel()[mask]
    box = [int(mx.min()), int(my.min()), int(mx.max()) + 1, int(my.max()) + 1]
    cream = mask & (np.max(np.abs(pixels.astype(int) - [244, 235, 221]), axis=1) < 18)
    nose = mask & (np.max(np.abs(pixels.astype(int) - [200, 100, 59]), axis=1) < 20)
    proof[name] = {'board_bbox_xyxy': box, 'mean_rgb_board_footprint': pixels[mask].mean(axis=0).round(2).tolist(), 'footprint_pixels': int(mask.sum()), 'visible_cream_pixels': int(cream.sum()), 'visible_cream_mean_rgb': pixels[cream].mean(axis=0).round(2).tolist(), 'visible_terracotta_pixels': int(nose.sum())}
    assert cream.sum() > 40 and nose.sum() > 5, (name, proof[name])
    if mode in ('left_carve', 'riding', 'right_carve'):
        # Broad enough for both wing tips, every line, rider, board and tail spray.
        crop_box = (0, 1150, 1179, 1930)
        crop = image.crop(crop_box).resize((3537, 2340), Image.Resampling.NEAREST)
        crops[mode] = crop
        proof[name]['crop_bbox_in_full_frame'] = crop_box
        proof[name]['board_bbox_in_3x_crop'] = [(box[i] - crop_box[i % 2]) * 3 for i in range(4)]
        if mode == 'riding':
            crop.save(OUT / 'rider_crop_3x.png')

reference = Image.open(ROOT / 'art/qa/claude/layers/directions_layered.png').convert('RGB')
width = 3 * 3537
sheet = Image.new('RGB', (width, 80 + 2340 + 80 + reference.height), '#f4ebdd')
draw = ImageDraw.Draw(sheet)
for index, mode in enumerate(('left_carve', 'riding', 'right_carve')):
    draw.text((index * 3537 + 30, 25), 'IN-ENGINE ' + mode + ' / actual pixels enlarged 3x', fill='#22384a')
    sheet.paste(crops[mode], (index * 3537, 80))
draw.text((30, 80 + 2340 + 25), 'APPROVED REFERENCE / original pixels unchanged', fill='#22384a')
sheet.paste(reference, ((width - reference.width) // 2, 80 + 2340 + 80))
sheet.save(OUT / 'compare_vs_approved.png')
(OUT / 'board_pixel_proof.json').write_text(json.dumps(proof, indent=2) + '\n')
print(json.dumps(proof, indent=2))
