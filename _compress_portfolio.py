import zipfile, io, hashlib, os, sys
from PIL import Image, PngImagePlugin

SRC = '_tmp_portfolio_original.zip'
DST = '_tmp_portfolio_compressed.zip'

def fix_outer_name(name):
    try:
        return name.encode('cp437').decode('gbk')
    except (UnicodeEncodeError, UnicodeDecodeError):
        return name

def clone_info(info, filename=None, compress_type=None):
    z = zipfile.ZipInfo(filename if filename is not None else info.filename, date_time=info.date_time)
    z.comment = info.comment
    z.extra = info.extra
    z.internal_attr = info.internal_attr
    z.external_attr = info.external_attr
    z.create_system = info.create_system
    z.create_version = info.create_version
    z.extract_version = info.extract_version
    z.volume = info.volume
    z.compress_type = info.compress_type if compress_type is None else compress_type
    return z

def optimize_png(data):
    with Image.open(io.BytesIO(data)) as im:
        im.load()
        before_size = im.size
        before_mode = im.mode
        before_hash = hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest()
        out = io.BytesIO()
        kwargs = {'optimize': True, 'compress_level': 9}
        if im.info.get('icc_profile'):
            kwargs['icc_profile'] = im.info['icc_profile']
        if im.info.get('dpi'):
            kwargs['dpi'] = im.info['dpi']
        if im.info.get('exif'):
            kwargs['exif'] = im.info['exif']
        if getattr(im, 'text', None):
            pi = PngImagePlugin.PngInfo()
            for k, v in im.text.items():
                try:
                    pi.add_text(str(k), str(v))
                except Exception:
                    pass
            kwargs['pnginfo'] = pi
        im.save(out, format='PNG', **kwargs)
    result = out.getvalue()
    with Image.open(io.BytesIO(result)) as check:
        check.load()
        after_hash = hashlib.sha256(check.convert('RGBA').tobytes()).hexdigest()
        if check.size != before_size or check.mode != before_mode or after_hash != before_hash:
            raise RuntimeError('PNG pixel verification failed')
    return result

def optimize_xlsx(data):
    src = zipfile.ZipFile(io.BytesIO(data), 'r')
    outbuf = io.BytesIO()
    img_count = 0
    img_before = 0
    img_after = 0
    with src, zipfile.ZipFile(outbuf, 'w', allowZip64=True) as dst:
        for info in src.infolist():
            payload = src.read(info) if not info.is_dir() else b''
            if info.filename.startswith('xl/media/') and info.filename.lower().endswith('.png'):
                img_count += 1
                img_before += len(payload)
                optimized = optimize_png(payload)
                if len(optimized) < len(payload):
                    payload = optimized
                img_after += len(payload)
            ctype = zipfile.ZIP_STORED if info.is_dir() else zipfile.ZIP_DEFLATED
            zi = clone_info(info, compress_type=ctype)
            dst.writestr(zi, payload, compresslevel=9)
    result = outbuf.getvalue()
    with zipfile.ZipFile(io.BytesIO(result), 'r') as test:
        bad = test.testzip()
        if bad:
            raise RuntimeError(f'Nested XLSX CRC failure: {bad}')
    return result, img_count, img_before, img_after

with zipfile.ZipFile(SRC, 'r') as zin:
    infos = zin.infolist()
    xlsx_infos = [i for i in infos if i.filename.lower().endswith('.xlsx')]
    main = max(xlsx_infos, key=lambda i: i.file_size)
    source_payloads = {fix_outer_name(i.filename): (zin.read(i) if not i.is_dir() else b'') for i in infos}

    with zipfile.ZipFile(DST, 'w', allowZip64=True) as zout:
        for info in infos:
            fixed = fix_outer_name(info.filename)
            payload = b'' if info.is_dir() else zin.read(info)
            if info == main:
                original_size = len(payload)
                payload, img_count, img_before, img_after = optimize_xlsx(payload)
                compressed_main_size = len(payload)
            ctype = zipfile.ZIP_STORED if info.is_dir() else zipfile.ZIP_DEFLATED
            zi = clone_info(info, filename=fixed, compress_type=ctype)
            zout.writestr(zi, payload, compresslevel=9)

with zipfile.ZipFile(DST, 'r') as z:
    bad = z.testzip()
    if bad:
        raise RuntimeError(f'Outer ZIP CRC failure: {bad}')
    output_infos = z.infolist()
    output_names = [i.filename for i in output_infos]
    if len(output_infos) != len(infos):
        raise RuntimeError('Outer member count changed')
    if len(set(output_names)) != len(output_names):
        raise RuntimeError('Duplicate output names')
    for info in output_infos:
        if info.is_dir():
            continue
        if info.filename == fix_outer_name(main.filename):
            continue
        out_hash = hashlib.sha256(z.read(info)).hexdigest()
        src_hash = hashlib.sha256(source_payloads[info.filename]).hexdigest()
        if out_hash != src_hash:
            raise RuntimeError(f'Non-target file changed: {info.filename}')

size = os.path.getsize(DST)
if size >= 50 * 1024 * 1024:
    raise RuntimeError(f'Output is not under 50 MiB: {size/2**20:.2f} MiB')

print(f'Outer files: {len(infos)} -> {len(output_infos)}')
print(f'Optimized XLSX: {fix_outer_name(main.filename)}')
print(f'XLSX size: {original_size/2**20:.2f} MiB -> {compressed_main_size/2**20:.2f} MiB')
print(f'PNG files losslessly optimized: {img_count}')
print(f'PNG payload: {img_before/2**20:.2f} MiB -> {img_after/2**20:.2f} MiB')
print(f'Final ZIP: {size/2**20:.2f} MiB')
print('CRC and unchanged-file SHA-256 verification: PASS')
