import os, re, zipfile, xml.etree.ElementTree as ET
from pathlib import Path

docx_path = os.environ['DOCX_PATH']
out_path = Path(os.environ['OUT_MD'])
ns = {'w':'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}

SECTION_PREFIXES = (
    'M0:', '前置篇', '技术含金量分级', '引言', '目录', '全书阅读地图',
    '第一章', '第二章', '第三章', '第四章', '第五章', '第六章', '第七章',
    '第八章', '第九章', '第十章', '第十一章', '第十二章', '第十三章', '第十四章',
)

def get_text(p):
    return ''.join(t.text or '' for t in p.findall('.//w:t', ns)).replace('\xa0', ' ').strip()

def style_id(p):
    pPr = p.find('w:pPr', ns)
    if pPr is not None:
        pStyle = pPr.find('w:pStyle', ns)
        if pStyle is not None:
            return pStyle.attrib.get(f'{{{ns["w"]}}}val')
    return None

with zipfile.ZipFile(docx_path) as z:
    root = ET.fromstring(z.read('word/document.xml'))
body = root.find('w:body', ns)
blocks = []
for child in body:
    tag = child.tag.split('}')[-1]
    if tag == 'p':
        text = get_text(child)
        if text:
            blocks.append(('p', style_id(child), text))
    elif tag == 'tbl':
        rows = []
        for r in child.findall('w:tr', ns):
            cells = []
            for c in r.findall('w:tc', ns):
                cell_text = ''.join(t.text or '' for t in c.findall('.//w:t', ns)).strip()
                cells.append(cell_text)
            rows.append(cells)
        blocks.append(('tbl', None, rows))

out = []
out.extend([
    '---',
    'source: OneNote/游戏技术术语.docx',
    'format: converted-from-docx',
    'tags: [游戏术语, 游戏开发, Obsidian, 技术词典]',
    '---',
    '',
])

def add(text=''):
    out.append(text)

for idx, (kind, sid, content) in enumerate(blocks):
    if kind == 'p':
        text = content
        if text == '游戏技术术语':
            if '# 游戏技术术语' not in out:
                add('# 游戏技术术语')
                add('')
            continue
        if sid in {'164', '165'}:
            add(f'# {text}')
            add('')
            continue
        if sid in {'166', '167', '168'}:
            add(f'> {text}')
            add('')
            continue
        if any(text.startswith(prefix) for prefix in SECTION_PREFIXES):
            # keep existing section wording as second-level heading
            add(f'## {text}')
            add('')
            continue
        if re.match(r'^\d+(?:\.\d+)*\s+', text):
            level = min(max(text.count('.') + 3, 4), 6)
            add('#' * level + ' ' + text)
            add('')
            continue
        if re.match(r'^[一二三四五六七八九十]+、', text):
            add(f'### {text}')
            add('')
            continue
        if text.startswith(('▎', '❶', '❷', '❸', '❹')):
            add(f'- {text}')
            continue
        if text.startswith(('例子：', '一句话：', '一句话核心：', '一句话总表', '方向决定', '颜色只标')):
            add(f'> {text}')
            add('')
            continue
        if sid == '171' and text.endswith('：') and len(text) < 40:
            add(f'**{text}**')
            add('')
            continue
        if sid == '178':
            add(f'**{text}**')
            add('')
            continue
        if sid == '179':
            add(f'- {text}')
            continue
        if sid == '180':
            add(f'> {text}')
            add('')
            continue
        if sid == '181' and len(text) < 50:
            add(f'### {text}')
            add('')
            continue
        add(text)
        add('')
    else:
        rows = content
        if not rows:
            continue
        max_cols = max(len(r) for r in rows)
        if max_cols <= 1:
            if rows and rows[0] and rows[0][0]:
                add(f'> {rows[0][0]}')
                add('')
            continue
        normalized = [r + [''] * (max_cols - len(r)) for r in rows]
        header = normalized[0]
        add('| ' + ' | '.join(c.replace('|', '\\|').replace('\n', '<br>') for c in header) + ' |')
        add('| ' + ' | '.join(['---'] * max_cols) + ' |')
        for row in normalized[1:]:
            add('| ' + ' | '.join(c.replace('|', '\\|').replace('\n', '<br>') for c in row) + ' |')
        add('')

# collapse extra blanks
clean = []
prev_blank = False
for line in out:
    blank = (line.strip() == '')
    if blank and prev_blank:
        continue
    clean.append(line)
    prev_blank = blank

out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text('\n'.join(clean).rstrip() + '\n', encoding='utf-8')
print(f'wrote {out_path} with {len(clean)} lines')
