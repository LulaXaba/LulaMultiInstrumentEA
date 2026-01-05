//+------------------------------------------------------------------+
//|                                                 C_HTTPClient.mqh  |
//|                                  LulaMultiInstrumentEA - ML Core |
//|                                                                   |
//+------------------------------------------------------------------+
#property copyright "LulaMultiInstrumentEA"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| HTTP Client Wrapper for WebRequest                               |
//| Provides simplified HTTP GET/POST with error handling            |
//+------------------------------------------------------------------+
class C_HTTPClient
{
private:
    string            m_baseUrl;           // Base URL for API  
    int               m_timeout;           // Timeout in milliseconds
    int               m_lastHttpCode;      // Last HTTP response code
    string            m_lastError;         // Last error message
    int               m_retryCount;        // Number of retry attempts
    int               m_retryDelay;        // Delay between retries (ms)
    
public:
    //--- Constructor/Destructor
    C_HTTPClient();
    ~C_HTTPClient();
    
    //--- Initialization
    bool Initialize(string baseUrl, int timeout_ms = 1000, int retries = 3);
    
    //--- HTTP Methods
    string GET(string endpoint, string &headers[]);
    string POST(string endpoint, string jsonBody, string &headers[]);
    
    //--- Health Check
    bool IsHealthy();
    bool TestConnection();
    
    //--- Getters
    int GetLastHTTPCode() const { return m_lastHttpCode; }
    string GetLastError() const { return m_lastError; }
    
private:
    //--- Internal helpers
    string BuildURL(string endpoint);
    bool ExecuteRequest(string url, string method, string data, string &headers[], string &result);
    void LogError(string functionName, int errorCode, string details);
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
C_HTTPClient::C_HTTPClient()
{
    m_baseUrl = "";
    m_timeout = 1000;
    m_lastHttpCode = 0;
    m_lastError = "";
    m_retryCount = 3;
    m_retryDelay = 100;
}

//+------------------------------------------------------------------+
//| Destructor                                                        |
//+------------------------------------------------------------------+
C_HTTPClient::~C_HTTPClient()
{
}

//+------------------------------------------------------------------+
//| Initialize HTTP client with base URL and timeout                 |
//+------------------------------------------------------------------+
bool C_HTTPClient::Initialize(string baseUrl, int timeout_ms = 1000, int retries = 3)
{
    m_baseUrl = baseUrl;
    m_timeout = MathMax(100, MathMin(timeout_ms, 5000)); // Clamp between 100-5000ms
    m_retryCount = MathMax(0, MathMin(retries, 5));     // Max 5 retries
    m_lastError = "";
    
    // Validate URL format
    if(StringFind(m_baseUrl, "http://") != 0 && StringFind(m_baseUrl, "https://") != 0)
    {
        m_lastError = "Invalid URL format. Must start with http:// or https://";
        Print("C_HTTPClient::Initialize() ERROR - ", m_lastError);
        return false;
    }
    
    Print("C_HTTPClient::Initialize() - Base URL: ", m_baseUrl, ", Timeout: ", m_timeout, "ms, Retries: ", m_retryCount);
    return true;
}

//+------------------------------------------------------------------+
//| Perform HTTP GET request                                         |
//+------------------------------------------------------------------+
string C_HTTPClient::GET(string endpoint, string &headers[])
{
    string url = BuildURL(endpoint);
    string result = "";
    
    if(!ExecuteRequest(url, "GET", "", headers, result))
    {
        return "";
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Perform HTTP POST request with JSON body                         |
//+------------------------------------------------------------------+
string C_HTTPClient::POST(string endpoint, string jsonBody, string &headers[])
{
    string url = BuildURL(endpoint);
    string result = "";
    
    if(!ExecuteRequest(url, "POST", jsonBody, headers, result))
    {
        return "";
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Test if API is reachable (health check)                          |
//+------------------------------------------------------------------+
bool C_HTTPClient::IsHealthy()
{
    string headers[];
    ArrayResize(headers, 1);
    headers[0] = "Content-Type: application/json";
    
    // Try to GET from base URL or health endpoint
    string result = GET("/health", headers);
    
    if(m_lastHttpCode == 200 || m_lastHttpCode == 404) // 404 is OK, means server is responding
    {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Test connection to base URL                                      |
//+------------------------------------------------------------------+
bool C_HTTPClient::TestConnection()
{
    string headers[];
    ArrayResize(headers, 1);
    headers[0] = "User-Agent: MQL5 HTTPClient/1.0";
    
    string result = GET("/", headers);
    
    if(m_lastHttpCode >= 200 && m_lastHttpCode < 500)
    {
        Print("C_HTTPClient::TestConnection() - SUCCESS - HTTP ", m_lastHttpCode);
        return true;
    }
    
    Print("C_HTTPClient::TestConnection() - FAILED - HTTP ", m_lastHttpCode, " Error: ", m_lastError);
    return false;
}

//+------------------------------------------------------------------+
//| Build full URL from base + endpoint                              |
//+------------------------------------------------------------------+
string C_HTTPClient::BuildURL(string endpoint)
{
    // Remove trailing slash from base URL
    string baseUrl = m_baseUrl;
    if(StringSubstr(baseUrl, StringLen(baseUrl) - 1, 1) == "/")
    {
        baseUrl = StringSubstr(baseUrl, 0, StringLen(baseUrl) - 1);
    }
    
    // Ensure endpoint starts with /
    if(StringSubstr(endpoint, 0, 1) != "/")
    {
        endpoint = "/" + endpoint;
    }
    
    return baseUrl + endpoint;
}

//+------------------------------------------------------------------+
//| Execute WebRequest with retry logic                              |
//+------------------------------------------------------------------+
bool C_HTTPClient::ExecuteRequest(string url, string method, string data, string &headers[], string &result)
{
    m_lastError = "";
    m_lastHttpCode = 0;
    result = "";
    
    int attempts = 0;
    int maxAttempts = m_retryCount + 1; // Initial attempt + retries
    
    while(attempts < maxAttempts)
    {
        attempts++;
        
        char postData[];
        char resultData[];
        string resultHeaders;
        
        // Convert data to char array for POST
        if(data != "")
        {
            StringToCharArray(data, postData, 0, StringLen(data));
        }
        
        // Execute WebRequest
        ResetLastError();
        
        // Build headers string
        string headerString = "";
        if(method == "POST" && data != "")
        {
            headerString = "Content-Type: application/json\r\n";
        }
        
        int httpCode = WebRequest(
            method,
            url,
            headerString,
            NULL,
            m_timeout,
            postData,
            ArraySize(postData),
            resultData,
            resultHeaders
        );
        
        int errorCode = GetLastError();
        m_lastHttpCode = httpCode;
        
        // Check for WebRequest errors
        if(errorCode != 0)
        {
            if(errorCode == 4060)
            {
                m_lastError = "WebRequest not allowed. Add URL to allowed list in Tools->Options->Expert Advisors";
                LogError("ExecuteRequest", errorCode, m_lastError);
                return false; // Don't retry this error
            }
            else if(errorCode == 5203)
            {
                m_lastError = "WebRequest timeout or network error";
                LogError("ExecuteRequest", errorCode, m_lastError);
                
                // Retry on timeout
                if(attempts < maxAttempts)
                {
                    Sleep(m_retryDelay);
                    continue;
                }
                return false;
            }
            else
            {
                m_lastError = "WebRequest error: " + IntegerToString(errorCode);
                LogError("ExecuteRequest", errorCode, m_lastError);
                
                if(attempts < maxAttempts)
                {
                    Sleep(m_retryDelay);
                    continue;
                }
                return false;
            }
        }
        
        // Convert result to string
        if(ArraySize(resultData) > 0)
        {
            result = CharArrayToString(resultData, 0, WHOLE_ARRAY, CP_UTF8);
        }
        
        // Check HTTP status code
        if(httpCode >= 200 && httpCode < 300)
        {
            // Success
            return true;
        }
        else if(httpCode >= 500)
        {
            // Server error - retry
            m_lastError = "Server error HTTP " + IntegerToString(httpCode);
            if(attempts < maxAttempts)
            {
                Sleep(m_retryDelay);
                continue;
            }
        }
        else if(httpCode >= 400 && httpCode < 500)
        {
            // Client error - don't retry
            m_lastError = "Client error HTTP " + IntegerToString(httpCode);
            LogError("ExecuteRequest", httpCode, m_lastError);
            return false;
        }
        else if(httpCode == -1)
        {
            // Network error
            m_lastError = "Network error or invalid URL";
            LogError("ExecuteRequest", -1, m_lastError);
            
            if(attempts < maxAttempts)
            {
                Sleep(m_retryDelay);
                continue;
            }
            return false;
        }
        
        break; // Exit retry loop
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Log error message                                                |
//+------------------------------------------------------------------+
void C_HTTPClient::LogError(string functionName, int errorCode, string details)
{
    Print("C_HTTPClient::", functionName, "() ERROR [", errorCode, "] - ", details);
}
//+------------------------------------------------------------------+
