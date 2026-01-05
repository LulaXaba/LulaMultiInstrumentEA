//+------------------------------------------------------------------+
//|                                                 C_JSONHelper.mqh  |
//|                                  LulaMultiInstrumentEA - ML Core |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Simple JSON Helper for ML API Communication                      |
//| Note: MQL5 doesn't have native JSON library, using string format |
//+------------------------------------------------------------------+
class C_JSONHelper
{
public:
    //--- JSON Creation
    string CreateFeatureArray(double &features[], int count);
    string CreatePredictionRequest(string symbol, string timeframe, double &features[], int count);
    string CreateKeyValue(string key, string value, bool isNumeric = false);
    string CreateKeyValue(string key, double value);
    string CreateKeyValue(string key, int value);
    
    //--- JSON Parsing (simple)
    bool ParseDouble(string json, string key, double &output);
    bool ParseString(string json, string key, string &output);
    bool ParseInt(string json, string key, int &output);
    
    //--- Utilities
    string EscapeString(string inputStr);
    double ExtractNumber(string json, string key);
    
private:
    string DoubleArrayToString(double &arr[], int count);
};

//+------------------------------------------------------------------+
//| Create JSON array from feature array                             |
//+------------------------------------------------------------------+
string C_JSONHelper::CreateFeatureArray(double &features[], int count)
{
    string result = "[";
    
    for(int i = 0; i < count; i++)
    {
        result += StringFormat("%.6f", features[i]);
        if(i < count - 1)
        {
            result += ", ";
        }
    }
    
    result += "]";
    return result;
}

//+------------------------------------------------------------------+
//| Create complete prediction request JSON                          |
//+------------------------------------------------------------------+
string C_JSONHelper::CreatePredictionRequest(string symbol, string timeframe, double &features[], int count)
{
    string json = "{";
    json += "\"symbol\": \"" + symbol + "\",";
    json += "\"timeframe\": \"" + timeframe + "\",";
    json += "\"timestamp\": " + IntegerToString(TimeCurrent()) + ",";
    json += "\"features\": " + CreateFeatureArray(features, count);
    json += "}";
    
    return json;
}

//+------------------------------------------------------------------+
//| Create key-value pair (string)                                   |
//+------------------------------------------------------------------+
string C_JSONHelper::CreateKeyValue(string key, string value, bool isNumeric = false)
{
    if(isNumeric)
    {
        return "\"" + key + "\": " + value;
    }
    else
    {
        return "\"" + key + "\": \"" + EscapeString(value) + "\"";
    }
}

//+------------------------------------------------------------------+
//| Create key-value pair (double)                                   |
//+------------------------------------------------------------------+
string C_JSONHelper::CreateKeyValue(string key, double value)
{
    return "\"" + key + "\": " + StringFormat("%.6f", value);
}

//+------------------------------------------------------------------+
//| Create key-value pair (int)                                      |
//+------------------------------------------------------------------+
string C_JSONHelper::CreateKeyValue(string key, int value)
{
    return "\"" + key + "\": " + IntegerToString(value);
}

//+------------------------------------------------------------------+
//| Parse double value from JSON                                     |
//+------------------------------------------------------------------+
bool C_JSONHelper::ParseDouble(string json, string key, double &output)
{
    string searchKey = "\"" + key + "\":";
    int pos = StringFind(json, searchKey);
    
    if(pos == -1)
    {
        // Try without quotes around key
        searchKey = key + ":";
        pos = StringFind(json, searchKey);
        if(pos == -1) return false;
    }
    
    pos += StringLen(searchKey);
    
    // Skip whitespace
    while(pos < StringLen(json) && (StringGetCharacter(json, pos) == ' ' || StringGetCharacter(json, pos) == '\t'))
    {
        pos++;
    }
    
    // Extract number
    string numStr = "";
    while(pos < StringLen(json))
    {
        ushort ch = StringGetCharacter(json, pos);
        if((ch >= '0' && ch <= '9') || ch == '.' || ch == '-' || ch == '+' || ch == 'e' || ch == 'E')
        {
            numStr += ShortToString(ch);
            pos++;
        }
        else
        {
            break;
        }
    }
    
    if(numStr == "") return false;
    
    output = StringToDouble(numStr);
    return true;
}

//+------------------------------------------------------------------+
//| Parse string value from JSON                                     |
//+------------------------------------------------------------------+
bool C_JSONHelper::ParseString(string json, string key, string &output)
{
    string searchKey = "\"" + key + "\":";
    int pos = StringFind(json, searchKey);
    
    if(pos == -1) return false;
    
    pos += StringLen(searchKey);
    
    // Skip whitespace and opening quote
    while(pos < StringLen(json) && (StringGetCharacter(json, pos) == ' ' || StringGetCharacter(json, pos) == '\t'))
    {
        pos++;
    }
    
    if(StringGetCharacter(json, pos) != '"') return false;
    pos++; // Skip opening quote
    
    // Extract string until closing quote
    output = "";
    while(pos < StringLen(json))
    {
        ushort ch = StringGetCharacter(json, pos);
        if(ch == '"')
        {
            return true;
        }
        output += ShortToString(ch);
        pos++;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Parse int value from JSON                                        |
//+------------------------------------------------------------------+
bool C_JSONHelper::ParseInt(string json, string key, int &output)
{
    double dblValue;
    if(ParseDouble(json, key, dblValue))
    {
        output = (int)dblValue;
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Escape special characters in string                              |
//+------------------------------------------------------------------+
string C_JSONHelper::EscapeString(string inputStr)
{
    string output = inputStr;
    StringReplace(output, "\\", "\\\\");
    StringReplace(output, "\"", "\\\"");
    StringReplace(output, "\n", "\\n");
    StringReplace(output, "\r", "\\r");
    StringReplace(output, "\t", "\\t");
    return output;
}

//+------------------------------------------------------------------+
//| Extract number from JSON (simple helper)                         |
//+------------------------------------------------------------------+
double C_JSONHelper::ExtractNumber(string json, string key)
{
    double result = 0.0;
    ParseDouble(json, key, result);
    return result;
}

//+------------------------------------------------------------------+
//| Convert double array to string                                   |
//+------------------------------------------------------------------+
string C_JSONHelper::DoubleArrayToString(double &arr[], int count)
{
    string result = "";
    for(int i = 0; i < count; i++)
    {
        result += StringFormat("%.6f", arr[i]);
        if(i < count - 1) result += ", ";
    }
    return result;
}
//+------------------------------------------------------------------+
