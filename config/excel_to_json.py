import openpyxl
import json
import sys

# Windows 控制台默认 GBK，强制 UTF-8 输出避免 ⚠ 等字符报 UnicodeEncodeError
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")


def parse_cell(v):
    """单元格里的 JSON 文本（如 card_effects 列的数组）还原成真正的数组/对象，
    保证 excel→json 往返后类型不退化"""
    if isinstance(v, str):
        s = v.strip()
        if s[:1] in ("[", "{"):
            try:
                return json.loads(s)
            except ValueError:
                return v
    return v


def excel_to_json(excel_file, sheet_name=None):
    # 加载 Excel 文件
    wb = openpyxl.load_workbook(excel_file)

    # 如果未指定 sheet_name，默认读取第一个 sheet
    if sheet_name is None:
        sheet = wb.active
    else:
        sheet = wb[sheet_name]

    # 获取表头（第一行）
    headers = [cell.value for cell in sheet[2]]


    # 读取数据行
    data = []
    for row in sheet.iter_rows(min_row=3, values_only=True):  # 从第 3 行开始（跳过表头）
        row_data = {k: parse_cell(v) for k, v in zip(headers, row)}
        row_data = {k: v for k, v in row_data.items() if v is not None}  # 空单元格=字段缺失，保持原 JSON 的参差键结构
        if not row_data:  # 整行为空（如被清空但未删除的尾部行）不导出
            continue
        data.append(row_data)

    # 转换为 JSON
    json_data = json.dumps(data, ensure_ascii=False, indent=4)  # ensure_ascii=False 支持中文
    return json_data


if __name__ == '__main__':
    excel_file = "config_table.xlsx"
    sheet_name_list = [
        "card_level_up",
        "stage_info",
        "coin_skill",
        "buff", "debuff",
        "boss_debuff",
        "dice_multiplier"
        ]

    for sheet_name in sheet_name_list:
        json_output = excel_to_json(excel_file, sheet_name=sheet_name)  # 可选 sheet_name
        print(json_output)

        # 保存到文件
        with open(f"{sheet_name}.json", "w", encoding="utf-8") as f:
            f.write(json_output)
