import re

# Read the file
with open('C_SignalScorer.mqh', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace iMA calls
content = re.sub(r'iMA\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*MODE_EMA,\s*PRICE_CLOSE,\s*(\d+)\)',
                 r'GetMA(\1, \2, \3, \4, 1, 1, \5)', content)
content = re.sub(r'iMA\(([^,]+),\s*([^,]+),\s*([^,]+),\s*([^,]+),\s*MODE_SMA,\s*PRICE_CLOSE,\s*(\d+)\)',
                 r'GetMA(\1, \2, \3, \4, 0, 1, \5)', content)

# Replace iADX calls  
content = re.sub(r'iADX\(([^,]+),\s*([^,]+),\s*(\d+),\s*PRICE_CLOSE,\s*MODE_MAIN,\s*(\d+)\)',
                 r'GetADX(\1, \2, \3, \4)', content)

# Replace iRSI calls
content = re.sub(r'iRSI\(([^,]+),\s*([^,]+),\s*(\d+),\s*PRICE_CLOSE,\s*(\d+)\)',
                 r'GetRSI(\1, \2, \3, 1, \4)', content)

# Replace iMACD calls
content = re.sub(r'iMACD\(([^,]+),\s*([^,]+),\s*(\d+),\s*(\d+),\s*(\d+),\s*PRICE_CLOSE,\s*MODE_MAIN,\s*(\d+)\)',
                 r'GetMACD(\1, \2, \3, \4, \5, 1, 0, \6)', content)
content = re.sub(r'iMACD\(([^,]+),\s*([^,]+),\s*(\d+),\s*(\d+),\s*(\d+),\s*PRICE_CLOSE,\s*MODE_SIGNAL,\s*(\d+)\)',
                 r'GetMACD(\1, \2, \3, \4, \5, 1, 1, \6)', content)

# Replace iATR calls
content = re.sub(r'iATR\(([^,]+),\s*([^,]+),\s*(\d+),\s*(\d+)\)',
                 r'GetATR(\1, \2, \3, \4)', content)

# Replace iBands calls
content = re.sub(r'iBands\(([^,]+),\s*([^,]+),\s*(\d+),\s*(\d+),\s*(\d+),\s*PRICE_CLOSE,\s*MODE_UPPER,\s*(\d+)\)',
                 r'GetBands(\1, \2, \3, \4, \5, 1, 1, \6)', content)
content = re.sub(r'iBands\(([^,]+),\s*([^,]+),\s*(\d+),\s*(\d+),\s*(\d+),\s*PRICE_CLOSE,\s*MODE_LOWER,\s*(\d+)\)',
                 r'GetBands(\1, \2, \3, \4, \5, 1, 2, \6)', content)
content = re.sub(r'iBands\(([^,]+),\s*([^,]+),\s*(\d+),\s*(\d+),\s*(\d+),\s*PRICE_CLOSE,\s*MODE_MAIN,\s*(\d+)\)',
                 r'GetBands(\1, \2, \3, \4, \5, 1, 0, \6)', content)

# Write back
with open('C_SignalScorer.mqh', 'w', encoding='utf-8') as f:
    f.write(content)

print("Conversion complete!")
