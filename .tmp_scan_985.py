from pathlib import Path
import fitz
import re

root = Path("简历库")
universities = [
    "北京大学", "清华大学", "中国人民大学", "北京航空航天大学", "北京理工大学",
    "中国农业大学", "北京师范大学", "中央民族大学", "南开大学", "天津大学",
    "大连理工大学", "东北大学", "吉林大学", "哈尔滨工业大学", "哈工大",
    "复旦大学", "同济大学", "上海交通大学", "华东师范大学", "南京大学",
    "东南大学", "浙江大学", "中国科学技术大学", "中科大", "厦门大学",
    "山东大学", "中国海洋大学", "武汉大学", "华中科技大学", "湖南大学",
    "中南大学", "中山大学", "华南理工大学", "四川大学", "重庆大学",
    "电子科技大学", "西安交通大学", "西北工业大学", "西北农林科技大学",
    "兰州大学", "国防科技大学", "国防科学技术大学",
]
client_terms = ["客户端", "Unity", "UE4", "UE5", "Unreal", "游戏开发", "Gameplay"]

for path in root.rglob("*.pdf"):
    try:
        doc = fitz.open(path)
        text = "\n".join(page.get_text() for page in doc)
    except Exception:
        continue
    if len(text.strip()) < 200:
        print(f"{path}\tpages={len(doc)}\tchars={len(text.strip())}")
