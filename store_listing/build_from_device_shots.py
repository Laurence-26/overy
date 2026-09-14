"""Build Play store screenshots + feature graphic from REAL Android device captures."""
from pathlib import Path
import subprocess
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pillow', '-q'])
    from PIL import Image, ImageDraw, ImageFont

ASSETS = Path(r'C:\Users\PANDA\.cursor\projects\d-overy\assets')
SHOTS = Path(r'D:\overy\cyclus\store_listing\screenshots')
GFX = Path(r'D:\overy\cyclus\store_listing\graphics')
SHOTS.mkdir(parents=True, exist_ok=True)
GFX.mkdir(parents=True, exist_ok=True)

# Clear previous (including AI mockups)
for p in list(SHOTS.iterdir()):
    if p.is_file():
        try:
            p.unlink()
        except PermissionError:
            print('skip locked', p.name)

REAL = [
    ('01_today.png', 'WhatsApp_Image_2026-09-14_at_18.09.48-88b3f6f4-4d3e-4fac-8cca-6f190a566716.jpg'),
    ('02_today_alt.png', 'WhatsApp_Image_2026-09-14_at_17.52.12-5e292764-b16d-432b-adad-cbdcddc770d2.jpg'),
    ('03_today_photo_bg.png', 'WhatsApp_Image_2026-09-14_at_16.23.43-3e09ced6-468b-41f0-b50c-3051968557fd.jpg'),
    ('04_theme_studio.png', 'WhatsApp_Image_2026-09-14_at_14.04.56-2cb7ac99-469a-41bf-871e-c4ce6707c39a.jpg'),
    ('05_stats.png', 'WhatsApp_Image_2026-09-14_at_13.37.57-14f35801-d99e-4028-880b-5d9a8a2e6328.jpg'),
]


def find_src(name_part: str) -> Path:
    matches = list(ASSETS.glob(f'*{name_part}'))
    if not matches:
        raise FileNotFoundError(name_part)
    return matches[0]


def fit_phone(im: Image.Image, tw=1080, th=1920) -> Image.Image:
    im = im.convert('RGB')
    scale = tw / im.width
    nw, nh = tw, int(im.height * scale)
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new('RGB', (tw, th), (255, 248, 250))
    if nh >= th:
        top = max(0, (nh - th) // 5)  # bias toward top (keep header)
        im = im.crop((0, top, tw, top + th))
        canvas.paste(im, (0, 0))
    else:
        canvas.paste(im, (0, (th - nh) // 2))
    return canvas


phone_pngs = []
for out_name, src_part in REAL:
    src = find_src(src_part)
    out = SHOTS / out_name
    fit_phone(Image.open(src)).save(out, 'PNG', optimize=True)
    phone_pngs.append(out)
    print(f'wrote {out.name} from {src.name} ({out.stat().st_size} bytes)')


def phone_frame(src: Path, box_w=220, box_h=440) -> Image.Image:
    im = fit_phone(Image.open(src)).resize((box_w, box_h), Image.Resampling.LANCZOS)
    frame = Image.new('RGBA', (box_w + 18, box_h + 18), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((0, 0, box_w + 17, box_h + 17), radius=32, fill=(255, 255, 255, 235))
    frame.paste(im, (9, 9))
    return frame


# Feature graphic built from REAL screenshots (not invented UI)
W, H = 1024, 500
fg = Image.new('RGBA', (W, H), (0, 0, 0, 0))
for y in range(H):
    t = y / max(H - 1, 1)
    r = int(248 - 18 * t)
    g = int(124 + 35 * t)
    b = int(160 + 25 * t)
    for x in range(W):
        fg.putpixel((x, y), (r, g, b, 255))

od = ImageDraw.Draw(fg)
od.ellipse((-90, -70, 280, 300), fill=(255, 255, 255, 45))
od.ellipse((760, 180, 1140, 560), fill=(255, 200, 210, 55))

try:
    font_big = ImageFont.truetype('C:/Windows/Fonts/segoeuib.ttf', 74)
    font_small = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 26)
except Exception:
    font_big = ImageFont.load_default()
    font_small = font_big

od.text((46, 155), 'Cyclus', fill=(255, 255, 255, 255), font=font_big)
od.text((50, 245), 'Your cycle, beautifully offline', fill=(255, 245, 250, 255), font=font_small)

fg.alpha_composite(phone_frame(phone_pngs[0]), dest=(530, 28))
fg.alpha_composite(phone_frame(phone_pngs[1]), dest=(760, 48))

out_fg = GFX / 'feature_graphic.png'
fg.convert('RGB').save(out_fg, 'PNG')
print('feature graphic', out_fg, out_fg.stat().st_size)

# Prefer real composite over any AI graphic
ai = Path(r'C:\Users\PANDA\.cursor\projects\d-overy\assets\cyclus_feature_graphic_real.png')
if ai.exists():
    # Keep AI version as alternate only
    ai_out = GFX / 'feature_graphic_ai_alt.png'
    Image.open(ai).convert('RGB').resize((1024, 500), Image.Resampling.LANCZOS).save(ai_out)
    print('saved AI alt', ai_out)
