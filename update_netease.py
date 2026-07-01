import os

for root, dirs, files in os.walk('岗位mapping'):
    for f in files:
        if '网易.md' == f:
            target_path = os.path.join(root, f)
            print("Found:", target_path)
            with open(target_path, 'r', encoding='utf-8') as file:
                content = file.read()

            new_project = """
### ✅ 《世界之外》 — 已上线
- 类型：女性向/无限流言情手游
- 简介：网易“无限流”乙女游戏，玩家在无限轮回的副本中攻略男主。
- 数据/报道：2024年1月18日不删档开测，1月26日正式公测。开服首周流水破亿，属于近年来现象级女性向爆款。
"""
            if '世界之外' not in content:
                if '## 旗下游戏' in content:
                    content = content.replace('## 旗下游戏', '## 旗下游戏' + new_project)
                else:
                    content += '\n## 旗下游戏\n' + new_project
                
                with open(target_path, 'w', encoding='utf-8') as file:
                    file.write(content)
                print('Updated', target_path)
