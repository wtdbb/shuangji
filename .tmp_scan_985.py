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

targets = {
    "cv_yangyuji_zh_2026.pdf", "RC198391.pdf", "个人简历-亓泽鹏.pdf",
    "代金龙-Unity客户端.pdf", "客户端-马懿慧.pdf", "廖昀昊 5年.pdf",
    "李亚飞 10年 (1).pdf", "李志刚 10年以上.pdf", "李昭辉 10年以上.pdf",
    "李远 10年以上.pdf", "柳杜仕 ue客户端.pdf", "简历_通用版.pdf",
    "蒋丰 5年.pdf", "谭淇耀 7年.pdf", "钟胜汗简历.pdf",
}

for path in root.rglob("*.pdf"):
    if path.name not in targets:
        continue
    try:
        doc = fitz.open(path)
        text = "\n".join(page.get_text() for page in doc)
    except Exception:
        continue
    matched_unis = [u for u in universities if u in text]
    matched_client = [k for k in client_terms if k.lower() in text.lower()]
    if not matched_unis or not matched_client:
        continue
    flat = re.sub(r"\s+", " ", text)
    print(f"\n===== {path.name} | {'/'.join(matched_unis)} =====")
    print(flat[:2600])
