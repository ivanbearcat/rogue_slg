import openpyxl
import json


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
        row_data = dict(zip(headers, row))
        data.append(row_data)

    # 转换为 JSON
    json_data = json.dumps(data, ensure_ascii=False, indent=4)  # ensure_ascii=False 支持中文
    return json_data


if __name__ == '__main__':
    excel_file = "config_table.xlsx"
    sheet_name_list = ["card_level_up", "stage_info", "coin_skill", "debuff", "boss_debuff"]

    for sheet_name in sheet_name_list:
        json_output = excel_to_json(excel_file, sheet_name=sheet_name)  # 可选 sheet_name
        print(json_output)

        # 保存到文件
        with open(f"{sheet_name}.json", "w", encoding="utf-8") as f:
            f.write(json_output)
