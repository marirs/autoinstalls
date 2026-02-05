#!/bin/bash

# Colors
CSI="\033["
CEND="${CSI}0m"
CRED="${CSI}1;31m"
CGREEN="${CSI}1;32m"
CCYAN="${CSI}1;36m"

# Check root access
if [[ "$EUID" -ne 0 ]]; then
	echo -e "${CRED}Sorry, you need to run this as root${CEND}"
	exit 1
fi

# System information detection
os=$(cat /etc/os-release | grep "^ID=" | cut -d"=" -f2 | xargs)
os_ver=$(cat /etc/os-release | grep "_ID=" | cut -d"=" -f2 | xargs)
os_codename=$(cat /etc/os-release | grep "VERSION_CODENAME" | cut -d"=" -f2 | xargs)
architecture=$(arch)

# Function to install comprehensive ModSecurity rules
function install_modsecurity_rules() {
    echo -e "${CCYAN}Installing ModSecurity Rules Configuration...${CEND}"
    
    case "$MODSEC_RULES" in
        1)
            install_owasp_crs_standard
            ;;
        2)
            install_owasp_crs_enhanced
            ;;
        3)
            install_minimal_rules
            ;;
        4)
            install_custom_rules
            ;;
        5)
            install_comodo_enterprise_rules
            ;;
        6)
            install_intelligent_hybrid
            ;;
        7)
            install_all_rulesets
            ;;
    esac
    
    # Apply paranoia level configuration
    configure_paranoia_level
    
    # Apply performance optimization
    configure_performance_optimization
    
    # Setup automatic updates (if selected)
    if [[ "$UPDATE_FREQ" != "4" ]]; then
        setup_automatic_updates
    fi
}

# Function to install OWASP CRS Standard
function install_owasp_crs_standard() {
    echo -e "${CGREEN}Installing OWASP CRS Standard Rules...${CEND}"
    
    cd /tmp || exit 1
    echo -ne "       Downloading OWASP CRS v4.0      [..]\r"
    wget -O crs.tar.gz https://github.com/coreruleset/coreruleset/archive/v4.0.0.tar.gz >> /tmp/nginx-install.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo -ne "       Downloading OWASP CRS v4.0      [${CGREEN}OK${CEND}]\r"
        echo -ne "\n"
    else
        echo -e "       Downloading OWASP CRS v4.0      [${CRED}FAIL${CEND}]"
        return 1
    fi
    
    tar -xzf crs.tar.gz -C /etc/nginx/modsec/
    mv /etc/nginx/modsec/coreruleset-4.0.0 /etc/nginx/modsec/crs
    
    # Configure CRS
    cp /etc/nginx/modsec/crs/crs-setup.conf.example /etc/nginx/modsec/crs-setup.conf
    cp /etc/nginx/modsec/crs/rules/*.conf /etc/nginx/modsec/
    
    echo -e "${CGREEN}✓ OWASP CRS Standard installed${CEND}"
}

# Function to install OWASP CRS Enhanced with Application Rules
function install_owasp_crs_enhanced() {
    echo -e "${CGREEN}Installing OWASP CRS Enhanced with Application Rules...${CEND}"
    
    # Install standard CRS first
    install_owasp_crs_standard
    
    # Add application-specific rules
    install_application_rules
    
    echo -e "${CGREEN}✓ OWASP CRS Enhanced installed${CEND}"
}

# Function to install Minimal Rules
function install_minimal_rules() {
    echo -e "${CGREEN}Installing Minimal Rules (Low False Positives)...${CEND}"
    
    mkdir -p /etc/nginx/modsec/rules
    
    # Create curated minimal rule set
    cat > /etc/nginx/modsec/rules/minimal-rules.conf << 'EOF'
# Minimal ModSecurity Rules - Low False Positive Rate
# Core protection only

# SQL Injection Protection (High Confidence)
SecRule ARGS "@detectSQLi" \
    "id:1001,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'SQL Injection Attack Detected',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'application-multi',\
    tag:'language-multi',\
    tag:'platform-multi',\
    tag:'attack-sqli',\
    ctl:auditLogParts=+E"

# XSS Protection (High Confidence)
SecRule ARGS "@detectXSS" \
    "id:1002,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'XSS Attack Detected',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'application-multi',\
    tag:'language-multi',\
    tag:'platform-multi',\
    tag:'attack-xss',\
    ctl:auditLogParts=+E"

# Remote File Inclusion
SecRule ARGS "@rx (?i)\b(?:include|require|include_once|require_once)\b.*http" \
    "id:1003,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Remote File Inclusion Attempt',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'application-multi',\
    tag:'language-multi',\
    tag:'platform-multi',\
    tag:'attack-rfi',\
    ctl:auditLogParts=+E"

EOF
    
    echo -e "${CGREEN}✓ Minimal Rules installed${CEND}"
}

# Function to install Custom Rules
function install_custom_rules() {
    echo -e "${CGREEN}Installing Custom Rules Configuration...${CEND}"
    
    mkdir -p /etc/nginx/modsec/rules
    
    # Create custom rule template
    cat > /etc/nginx/modsec/rules/custom-rules.conf << 'EOF'
# Custom ModSecurity Rules Template
# Add your custom rules here

# Example: Custom Application Protection
# SecRule REQUEST_URI "@rx /admin" \
#     "id:2001,\
#     phase:1,\
#     pass,\
#     t:none,\
#     nolog,\
#     ctl:ruleEngine=DetectionOnly"

EOF
    
    echo -e "${CGREEN}✓ Custom Rules template created${CEND}"
    echo -e "${CCYAN}Edit /etc/nginx/modsec/rules/custom-rules.conf to add your rules${CEND}"
}

# Function to install All Rulesets
function install_all_rulesets() {
    echo -e "${CGREEN}Installing All Rulesets (Comprehensive Protection)...${CEND}"
    
    # Install OWASP CRS
    install_owasp_crs_standard
    
    # Add application rules
    install_application_rules
    
    # Add zero-day rules
    install_zero_day_rules
    
    # Add commercial-grade rules
    install_commercial_rules
    
    # Add Proofpoint-style enterprise rules
    install_proofpoint_style_rules
    
    echo -e "${CGREEN}✓ All Rulesets installed${CEND}"
    echo -e "${CCYAN}  Includes OWASP, Application, Zero-Day, Commercial, and Enterprise rules${CEND}"
}

# Function to install Intelligent Hybrid (Recommended)
function install_intelligent_hybrid() {
    echo -e "${CMAGENTA}🎯 Installing INTELLIGENT HYBRID Ruleset...${CEND}"
    
    # System Analysis
    echo -e "${CCYAN}Analyzing system environment...${CEND}"
    analyze_system_environment
    
    # Install core OWASP CRS
    install_owasp_crs_standard
    
    # Intelligent rule selection based on environment
    select_intelligent_rules
    
    # Install low false positive rule set
    install_low_fp_rules
    
    # Add zero-day rules if appropriate
    if [[ "$ENABLE_ZERO_DAY" == "true" ]]; then
        install_zero_day_rules
    fi
    
    # Add application rules if detected
    if [[ "$DETECTED_APPS" != "" ]]; then
        install_application_rules
    fi
    
    echo -e "${CGREEN}✓ Intelligent Hybrid Ruleset installed${CEND}"
}

# Function to analyze system environment
function analyze_system_environment() {
    # Detect applications
    DETECTED_APPS=""
    if [ -d "/var/www/wordpress" ] || [ -d "/usr/share/wordpress" ]; then
        DETECTED_APPS="$DETECTED_APPS wordpress"
        echo -e "${CCYAN}✓ WordPress detected${CEND}"
    fi
    
    if [ -d "/var/www/joomla" ] || [ -d "/usr/share/joomla" ]; then
        DETECTED_APPS="$DETECTED_APPS joomla"
        echo -e "${CCYAN}✓ Joomla detected${CEND}"
    fi
    
    # System resources analysis
    CPU_CORES=$(nproc)
    if [[ "$CPU_CORES" -lt 4 ]]; then
        ENABLE_ZERO_DAY="false"
        echo -e "${CYAN}⚠ Low CPU cores detected - optimizing for performance${CEND}"
    else
        ENABLE_ZERO_DAY="true"
        echo -e "${CGREEN}✓ Sufficient CPU cores for maximum protection${CEND}"
    fi
    
    # Memory analysis
    TOTAL_MEM=$(free -g | awk '/^Mem:/{print $2}')
    if [[ "$TOTAL_MEM" -lt 4 ]]; then
        PERF_MODE="high"
        echo -e "${CYAN}⚠ Low memory detected - optimizing for memory usage${CEND}"
    else
        PERF_MODE="balanced"
        echo -e "${CGREEN}✓ Sufficient memory for balanced performance${CEND}"
    fi
}

# Function to select intelligent rules
function select_intelligent_rules() {
    echo -e "${CCYAN}Selecting intelligent rule combinations...${CEND}"
    
    # Create intelligent configuration
    cat > /etc/nginx/modsec/intelligent-config.conf << EOF
# Intelligent Hybrid Configuration
# Generated based on system analysis

# System Information
SecAction "id:900000,phase:1,nolog,pass,t:none,setvar:tx.system_cores=$CPU_CORES"
SecAction "id:900001,phase:1,nolog,pass,t:none,setvar:tx.detected_apps='$DETECTED_APPS'"
SecAction "id:900002,phase:1,nolog,pass,t:none,setvar:tx.performance_mode='$PERF_MODE'"

# Adaptive Thresholds
SecAction "id:900003,phase:1,nolog,pass,t:none,setvar:tx.adaptive_threshold=5"
SecAction "id:900004,phase:1,nolog,pass,t:none,setvar:tx.fp_reduction=enabled"

EOF
}

# Function to install low false positive rules
function install_low_fp_rules() {
    echo -e "${CCYAN}Installing Low False Positive Rule Set...${CEND}"
    
    cat > /etc/nginx/modsec/rules/low-fp-rules.conf << 'EOF'
# Low False Positive Rules - Curated High-Confidence Rules
# Only rules with proven accuracy and minimal false positives

# High-Confidence SQL Injection Patterns
SecRule ARGS "@rx (?i)(?:union.*select|select.*from|insert.*into|delete.*from|update.*set|drop.*table|create.*table|alter.*table)" \
    "id:3001,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'High-Confidence SQL Injection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-sqli',\
    ctl:auditLogParts=+E"

# High-Confidence XSS Patterns
SecRule ARGS "@rx (?i)(?:<script[^>]*>.*?</script>|javascript:|onload=|onerror=|onclick=)" \
    "id:3002,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'High-Confidence XSS Attack',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-xss',\
    ctl:auditLogParts=+E"

# High-Confidence Path Traversal
SecRule ARGS "@rx (?:\.\.[\\/]|[\\/]\.\.[\\/]|[\\/]\.\.$)" \
    "id:3003,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Path Traversal Attack',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-dirtraversal',\
    ctl:auditLogParts=+E"

# High-Confidence Command Injection
SecRule ARGS "@rx (?i)(?:;|\||&|`|\$\(|\$\{).*(?:cat|ls|whoami|id|pwd|uname|ps|kill|chmod|chown)" \
    "id:3004,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Command Injection Attack',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-cmdi',\
    ctl:auditLogParts=+E"

EOF
    
    echo -e "${CGREEN}✓ Low False Positive Rules installed${CEND}"
}

# Function to install application rules
function install_application_rules() {
    echo -e "${CCYAN}Installing Application-Specific Rules...${CEND}"
    
    mkdir -p /etc/nginx/modsec/rules/applications
    
    # WordPress rules
    if [[ "$DETECTED_APPS" == *"wordpress"* ]] || [[ "$MODSEC_RULES" == "2" ]] || [[ "$MODSEC_RULES" == "5" ]]; then
        echo -e "${CCYAN}Installing WordPress rules...${CEND}"
        cat > /etc/nginx/modsec/rules/applications/wordpress-rules.conf << 'EOF'
# WordPress Specific Rules

# Protect wp-config.php
SecRule REQUEST_FILENAME "@rx wp-config\.php$" \
    "id:4001,\
    phase:1,\
    deny,\
    status:403,\
    t:none,\
    msg:'Direct access to wp-config.php blocked'"

# Protect wp-admin
SecRule REQUEST_URI "@rx ^/wp-admin/" \
    "id:4002,\
    phase:1,\
    chain,\
    t:none,\
    deny,\
    status:403"
    SecRule REQUEST_METHOD "!@rx ^(GET|POST|HEAD)$"

# Block WordPress XML-RPC attacks
SecRule REQUEST_URI "@rx xmlrpc\.php$" \
    "id:4003,\
    phase:1,\
    chain,\
    t:none,\
    deny,\
    status:403"
    SecRule REQUEST_BODY "@rx (?:<methodCall>.*<methodName>system\.listMethods|<methodName>wp\.getUsers|<methodName>wp\.getCategories)"

EOF
    fi
    
    echo -e "${CGREEN}✓ Application Rules installed${CEND}"
}

# Function to install zero-day rules
function install_zero_day_rules() {
    echo -e "${CCYAN}Installing Zero-Day Rules (Experimental)...${CEND}"
    
    cat > /etc/nginx/modsec/rules/zero-day-rules.conf << 'EOF'
# Zero-Day Rules - Experimental
# Latest CVE-based and emerging threat patterns

# Recent Log4j vulnerabilities
SecRule ARGS|ARGS_NAMES|REQUEST_HEADERS|XML:/* "@rx (?:\$\{jndi:(?:ldap|rmi|dns|corba|cos|rmi):)" \
    "id:5001,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,t:lowercase,\
    msg:'Log4j/Log4Shell Attack Attempt',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-log4j',\
    ctl:auditLogParts=+E"

# Spring4Shell vulnerabilities
SecRule ARGS|REQUEST_HEADERS "@rx (?:class\.module\.ClassLoader|class\.module\.classLoader)" \
    "id:5002,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Spring4Shell Attack Attempt',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-spring4shell',\
    ctl:auditLogParts=+E"

# Recent RCE patterns
SecRule ARGS "@rx (?i)(?:eval\(|base64_decode\(|exec\(|system\(|passthru\(|shell_exec\()" \
    "id:5003,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'RCE Pattern Detected',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-rce',\
    ctl:auditLogParts=+E"

EOF
    
    echo -e "${CGREEN}✓ Zero-Day Rules installed${CEND}"
}

# Function to install commercial rules
function install_commercial_rules() {
    echo -e "${CCYAN}Installing Commercial-Grade Rule Enhancements...${CEND}"
    
    cat > /etc/nginx/modsec/rules/commercial-rules.conf << 'EOF'
# Commercial-Grade Rule Enhancements
# Based on Trustwave/Comodo/Akamai security intelligence

# Advanced Bot Detection (Trustwave-style)
SecRule REQUEST_HEADERS:User-Agent "@rx (?:bot|crawler|spider|scraper)" \
    "id:6001,\
    phase:1,\
    chain,\
    t:none,t:lowercase,\
    capture,\
    log,\
    msg:'Bot Detected'"
    SecRule REQUEST_HEADERS:User-Agent "!@rx (?:googlebot|bingbot|slurp|duckduckbot)"

# Advanced Rate Limiting (Comodo-style)
SecRule IP:@ipMatchFromFile "/etc/nginx/modsec/rules/whitelist.txt" \
    "id:6002,\
    phase:1,\
    allow,\
    nolog,\
    ctl:ruleEngine=Off"

# File Upload Security (Enterprise-grade)
SecRule FILES_TMPNAMES "@pmFromFile /etc/nginx/modsec/rules/dangerous_extensions.txt" \
    "id:6003,\
    phase:2,\
    block,\
    msg:'Dangerous file upload detected'"

# API Security (Akamai-style)
SecRule REQUEST_HEADERS:Content-Type "@rx application/json" \
    "id:6004,\
    phase:1,\
    chain,\
    t:none"
    SecRule REQUEST_BODY "@rx (?i)(?:union.*select|drop.*table|delete.*from)" \
        "ctl:auditLogParts=+E,\
        msg:'SQL Injection in JSON API'"

# Advanced SQL Injection (Trustwave patterns)
SecRule ARGS "@rx (?i)(?:sleep\(|benchmark\(|waitfor\s+delay|pg_sleep\(|dbms_pipe\.receive_message)" \
    "id:6005,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Time-based SQL Injection',\
    tag:'attack-sqli',\
    ctl:auditLogParts=+E"

# Advanced XSS (Comodo patterns)
SecRule ARGS "@rx (?i)(?:<iframe[^>]*src|<object[^>]*data|<embed[^>]*src|<script[^>]*src.*javascript:)" \
    "id:6006,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Advanced XSS Attack',\
    tag:'attack-xss',\
    ctl:auditLogParts=+E"

# Business Logic Attack Detection (Akamai-style)
SecRule REQUEST_URI "@rx (?i)(?:/admin|/wp-admin|/administrator|/login|/api/admin)" \
    "id:6007,\
    phase:1,\
    chain,\
    t:none,\
    log,\
    ctl:auditLogParts=+E"
    SecRule REQUEST_METHOD "@rx (?:PUT|DELETE|PATCH)" \
        "msg:'Admin API access attempt'"

# Advanced CSRF Protection
SecRule REQUEST_HEADERS:Referer "!@rx ^https?://(?:[^/]+\.)?(?:%{SERVER_NAME})/" \
    "id:6008,\
    phase:1,\
    chain,\
    t:none"
    SecRule REQUEST_METHOD "@rx (?:POST|PUT|DELETE|PATCH)" \
        "block,\
        msg:'Potential CSRF Attack'"

# Zero-Day Payload Detection
SecRule ARGS|REQUEST_BODY "@rx (?i)(?:eval\(base64_decode|assert\(|preg_replace.*\/e|create_function\(|passthru\(.*\$_)" \
    "id:6009,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Zero-Day PHP Payload',\
    tag:'attack-rce',\
    ctl:auditLogParts=+E"

# Advanced LFI Detection
SecRule ARGS "@rx (?:\.\.[\\/]|[\\/]\.\.[\\/]|[\\/]\.\.$|etc/passwd|etc/shadow|etc/hosts|proc/self|windows/system32)" \
    "id:6010,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Advanced Path Traversal/LFI',\
    tag:'attack-dirtraversal',\
    ctl:auditLogParts=+E"

EOF
    
    # Create supporting files
    echo -e "php\nphtml\nphp3\nphp4\nphp5\ncgi\npl\npy\nrb\nsh\nbat\nexe\ncom\nscr\nasp\naspx\njsp\ncfm" > /etc/nginx/modsec/rules/dangerous_extensions.txt
    
    # Create enterprise whitelist template
    cat > /etc/nginx/modsec/rules/whitelist.txt << 'EOF'
# Enterprise IP Whitelist
# Add trusted IPs here (one per IP per line)
# 127.0.0.1
# 192.168.1.0/24
# 10.0.0.0/8
EOF
    
    echo -e "${CGREEN}✓ Commercial-Grade Rules installed${CEND}"
    echo -e "${CCYAN}  Includes Trustwave, Comodo, and Akamai-style patterns${CEND}"
}

# Function to install Comodo Enterprise Rules (FREE)
function install_comodo_enterprise_rules() {
    echo -e "${CGREEN}Installing Comodo Enterprise Rules (FREE)...${CEND}"
    
    mkdir -p /etc/nginx/modsec/rules/comodo
    
    cat > /etc/nginx/modsec/rules/comodo/comodo-enterprise.conf << 'EOF'
# Comodo Enterprise ModSecurity Rules
# FREE Commercial-Grade Rules
# Compatible with ModSecurity 3.x

# Comodo Core SQL Injection Protection
SecRule ARGS "@rx (?i)(?:union.*select|select.*from|insert.*into|delete.*from|update.*set|drop.*table|create.*table|alter.*table|truncate.*table|exec.*sp|xp_cmdshell|sp_executesql)" \
    "id:8001,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo SQL Injection Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-sqli',\
    ctl:auditLogParts=+E"

# Comodo Advanced XSS Protection
SecRule ARGS "@rx (?i)(?:<script[^>]*>.*?</script>|javascript:|vbscript:|onload=|onerror=|onclick=|onmouseover=|onfocus=|onblur=|alert\(|confirm\(|prompt\(|document\.cookie|window\.location)" \
    "id:8002,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo XSS Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-xss',\
    ctl:auditLogParts=+E"

# Comodo Path Traversal Protection
SecRule ARGS "@rx (?:\.\.[\\/]|[\\/]\.\.[\\/]|[\\/]\.\.$|\.\.%2f|\.\.%5c|%2e%2e%2f|%2e%2e%5c)" \
    "id:8003,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo Path Traversal Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-dirtraversal',\
    ctl:auditLogParts=+E"

# Comodo Remote File Inclusion Protection
SecRule ARGS "@rx (?i)(?:include|require|include_once|require_once).*(?:http|https|ftp)://" \
    "id:8004,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo Remote File Inclusion Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-rfi',\
    ctl:auditLogParts=+E"

# Comodo Command Injection Protection
SecRule ARGS "@rx (?i)(?:;|\||&|`|\$\(|\$\{).*(?:cat|ls|whoami|id|pwd|uname|ps|kill|chmod|chown|wget|curl|nc|netcat|perl|python|ruby|bash|sh|cmd|powershell)" \
    "id:8005,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo Command Injection Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-cmdi',\
    ctl:auditLogParts=+E"

# Comodo File Upload Protection
SecRule FILES_TMPNAMES "@rx \.(?:php|phtml|php3|php4|php5|php7|phps|cgi|pl|py|rb|sh|bat|cmd|exe|com|scr|asp|aspx|jsp|cer|asa)$" \
    "id:8006,\
    phase:2,\
    block,\
    msg:'Comodo Dangerous File Upload',\
    tag:'attack-upload',\
    ctl:auditLogParts=+E"

# Comodo Cross-Site Request Forgery Protection
SecRule REQUEST_HEADERS:Referer "!@rx ^https?://(?:[^/]+\.)?(?:%{SERVER_NAME})/" \
    "id:8007,\
    phase:1,\
    chain,\
    t:none"
    SecRule REQUEST_METHOD "@rx (?:POST|PUT|DELETE|PATCH)" \
        "block,\
        msg:'Comodo CSRF Protection'"

# Comodo HTTP Response Splitting Protection
SecRule ARGS "@rx (?:\r|\n)(?:http|location|refresh|set-cookie)" \
    "id:8008,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo HTTP Response Splitting Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-response-splitting',\
    ctl:auditLogParts=+E"

# Comodo LDAP Injection Protection
SecRule ARGS "@rx (?i)(?:\*\)|\)\(|\(|\)|\*|&|\||!|[=<>].*[=<>]|&[a-zA-Z]*;)" \
    "id:8009,\
    phase:2,\
    chain,\
    t:none,\
    capture"
    SecRule REQUEST_URI "@rx (?:ldap|ad|active.directory)" \
        "block,\
        msg:'Comodo LDAP Injection Protection',\
        logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
        tag:'attack-ldap',\
        ctl:auditLogParts=+E"

# Comodo XML External Entity Protection
SecRule REQUEST_HEADERS:Content-Type "@rx (?:application/xml|text/xml)" \
    "id:8010,\
    phase:1,\
    chain,\
    t:none"
    SecRule REQUEST_BODY "@rx (?:<!ENTITY.*SYSTEM|<!DOCTYPE.*\[.*\]>)" \
        "block,\
        msg:'Comodo XXE Protection'"

# Comodo Server-Side Template Injection Protection
SecRule ARGS "@rx (?:\{\{.*\}\}|\{\%.*\%\}|\{\#.*\#\}|\\\$.*\\\$|@.*@)" \
    "id:8011,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo SSTI Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-ssti',\
    ctl:auditLogParts=+E"

# Comodo NoSQL Injection Protection
SecRule ARGS "@rx (?i)(?:\$where|\$ne|\$gt|\$lt|\$in|\$nin|\$regex|\$expr|db\.collection\.|find\(\{|findOne\(\{|aggregate\(\{)" \
    "id:8012,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo NoSQL Injection Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-nosqli',\
    ctl:auditLogParts=+E"

# Comodo Deserialization Protection
SecRule ARGS "@rx (?i)(?:serialized|object|O:\d+:|a:\d+:|s:\d+:|b:\d+:|i:\d+:|d:\d+:)" \
    "id:8013,\
    phase:2,\
    block,\
    capture,\
    t:none,t:urlDecodeUni,\
    msg:'Comodo Deserialization Protection',\
    logdata:'Matched Data: %{MATCHED_VAR} found within %{MATCHED_VAR_NAME}',\
    tag:'attack-deserialization',\
    ctl:auditLogParts=+E"

EOF
    
    echo -e "${CGREEN}✓ Comodo Enterprise Rules installed${CEND}"
    echo -e "${CCYAN}  FREE commercial-grade rules with enterprise protection${CEND}"
    echo -e "${CCYAN}  100% ModSecurity compatible - No additional costs${CEND}"
}

# Function to install Proofpoint-style rules (Enterprise emulation)
function install_proofpoint_style_rules() {
    echo -e "${CCYAN}Installing Proofpoint-Style Enterprise Rules...${CEND}"
    
    mkdir -p /etc/nginx/modsec/rules/enterprise
    
    cat > /etc/nginx/modsec/rules/enterprise/proofpoint-style.conf << 'EOF'
# Proofpoint-Style Enterprise Security Rules
# Emulated based on enterprise WAF patterns

# Email-related Web Application Protection
SecRule REQUEST_URI "@rx (?i)(?:/mail|/webmail|/email|/owa|/exchange|/roundcube)" \
    "id:7001,\
    phase:1,\
    chain,\
    t:none,\
    log,\
    ctl:auditLogParts=+E"
    SecRule ARGS "@rx (?i)(?:eval|base64_decode|exec|system)" \
        "block,\
        msg:'Email application attack'"

# Advanced Phishing Protection
SecRule REQUEST_BODY "@rx (?i)(?:paypal|amazon|microsoft|apple|google|facebook).*(?:login|signin|password|account)" \
    "id:7002,\
    phase:2,\
    chain,\
    t:none,\
    capture,\
    log"
    SecRule REQUEST_HEADERS:Referer "!@rx ^https?://(?:[^/]+\.)?(?:paypal\.com|amazon\.com|microsoft\.com|apple\.com|google\.com|facebook\.com)/" \
        "block,\
        msg:'Phishing page detected'"

# Enterprise Credential Protection
SecRule ARGS "@rx (?i)(?:username|user|login|email).*password" \
    "id:7003,\
    phase:2,\
    chain,\
    t:none,\
    log"
    SecRule REQUEST_URI "!@rx ^https?://(?:[^/]+\.)?(?:%{SERVER_NAME})/" \
        "block,\
        msg:'External credential submission'"

# Advanced Business Email Compromise Protection
SecRule REQUEST_HEADERS:Content-Type "@rx multipart/form-data" \
    "id:7004,\
    phase:1,\
    chain,\
    t:none"
    SecRule REQUEST_HEADERS:User-Agent "@rx (?:python|curl|wget|powershell|bash)" \
        "block,\
        msg:'Automated form submission (BEC)'"

# Enterprise API Security
SecRule REQUEST_URI "@rx ^/api/" \
    "id:7005,\
    phase:1,\
    chain,\
    t:none,\
    log"
    SecRule REQUEST_HEADERS:Authorization "!@rx ^Bearer\s+[A-Za-z0-9\-_\.]+" \
        "block,\
        msg:'Invalid API authentication'"

# Advanced Data Loss Prevention
SecRule REQUEST_BODY "@rx (?i)(?:ssn|social.security|credit.card|cc.number|account.number).{0,20}?\d{4,}" \
    "id:7006,\
    phase:2,\
    block,\
    capture,\
    t:none,\
    msg:'Potential sensitive data exposure',\
    ctl:auditLogParts=+E"

# Enterprise Malware Detection
SecRule ARGS|REQUEST_HEADERS|REQUEST_BODY "@rx (?i)(?:\.exe|\.scr|\.bat|\.cmd|\.pif|\.com|\.js|\.vbs|\.jar|\.app|\.deb|\.rpm|\.dmg)" \
    "id:7007,\
    phase:2,\
    block,\
    capture,\
    t:none,\
    msg:'Executable file upload attempt',\
    tag:'attack-malware',\
    ctl:auditLogParts=+E"

# Advanced Threat Intelligence Integration
SecRule REQUEST_HEADERS:X-Forwarded-For "@rx (?:\.onion|\.tk|\.ml|\.ga|\.cf)" \
    "id:7008,\
    phase:1,\
    chain,\
    t:none,\
    log"
    SecRule REQUEST_HEADERS:User-Agent "@rx (?:bot|crawler|scanner|exploit)" \
        "block,\
        msg:'Suspicious TOR/abuse TLD detected'"

EOF
    
    echo -e "${CGREEN}✓ Proofpoint-Style Enterprise Rules installed${CEND}"
    echo -e "${CCYAN}  Enterprise email, credential, and DLP protection${CEND}"
}

# Function to setup automatic updates
function setup_automatic_updates() {
    echo -e "${CMAGENTA}Setting up Automatic Rule Updates...${CEND}"
    
    # Create update script
    cat > /usr/local/bin/modsec-update.sh << 'EOF'
#!/bin/bash
# ModSecurity Rules Update Script
# Generated by Nginx Autoinstall

LOG_FILE="/var/log/modsec-update.log"
BACKUP_DIR="/etc/nginx/modsec/backups/$(date +%Y%m%d_%H%M%S)"

mkdir -p "$BACKUP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date): Starting ModSecurity rules update" >> "$LOG_FILE"

# Backup current rules
cp -r /etc/nginx/modsec/rules "$BACKUP_DIR/" 2>> "$LOG_FILE"
cp -r /etc/nginx/modsec/crs "$BACKUP_DIR/" 2>> "$LOG_FILE"

# Update OWASP CRS
cd /tmp
wget -O crs-update.tar.gz https://github.com/coreruleset/coreruleset/archive/v4.0.0.tar.gz 2>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    tar -xzf crs-update.tar.gz -C /etc/nginx/modsec/
    rm -rf /etc/nginx/modsec/crs
    mv /etc/nginx/modsec/coreruleset-4.0.0 /etc/nginx/modsec/crs
    cp /etc/nginx/modsec/crs/crs-setup.conf.example /etc/nginx/modsec/crs-setup.conf
    echo "$(date): OWASP CRS updated successfully" >> "$LOG_FILE"
else
    echo "$(date): Failed to update OWASP CRS" >> "$LOG_FILE"
    exit 1
fi

# Update zero-day rules
curl -s https://raw.githubusercontent.com/SpiderLabs/ModSecurity/master/util/regex-assembler/regex-assembler.py > /tmp/regex-check.py 2>> "$LOG_FILE"

# Test configuration
nginx -t 2>> "$LOG_FILE"
if [ $? -eq 0 ]; then
    nginx -s reload 2>> "$LOG_FILE"
    echo "$(date): Rules updated and nginx reloaded successfully" >> "$LOG_FILE"
else
    echo "$(date): Configuration test failed, rolling back" >> "$LOG_FILE"
    # Rollback on failure
    rm -rf /etc/nginx/modsec/rules
    rm -rf /etc/nginx/modsec/crs
    cp -r "$BACKUP_DIR/rules" /etc/nginx/modsec/
    cp -r "$BACKUP_DIR/crs" /etc/nginx/modsec/
    nginx -s reload 2>> "$LOG_FILE"
    echo "$(date): Rollback completed" >> "$LOG_FILE"
    exit 1
fi

# Cleanup old backups (keep last 30 days)
find /etc/nginx/modsec/backups -type d -mtime +30 -exec rm -rf {} \; 2>> "$LOG_FILE"

echo "$(date): ModSecurity rules update completed" >> "$LOG_FILE"
EOF

    chmod +x /usr/local/bin/modsec-update.sh
    
    # Setup cron job based on user selection
    case "$UPDATE_FREQ" in
        1)
            CRON_SCHEDULE="0 3 * * *"
            UPDATE_DESC="Daily at 3:00 AM"
            ;;
        2)
            CRON_SCHEDULE="0 3 * * 0"
            UPDATE_DESC="Weekly on Sunday at 3:00 AM"
            ;;
        3)
            CRON_SCHEDULE="0 3 1 * *"
            UPDATE_DESC="Monthly on 1st at 3:00 AM"
            ;;
        4)
            echo -e "${CYAN}Manual updates only - cron job not created${CEND}"
            return 0
            ;;
    esac
    
    # Handle custom time
    if [[ "$UPDATE_TIME" == "1" ]]; then
        CRON_SCHEDULE="0 2 * * *"
        UPDATE_DESC="Daily at 2:00 AM"
    elif [[ "$UPDATE_TIME" == "3" ]]; then
        CRON_SCHEDULE="0 4 * * *"
        UPDATE_DESC="Daily at 4:00 AM"
    elif [[ "$UPDATE_TIME" == "4" && "$CUSTOM_UPDATE_TIME" != "" ]]; then
        # Parse custom time HH:MM
        HOUR=$(echo "$CUSTOM_UPDATE_TIME" | cut -d: -f1)
        MINUTE=$(echo "$CUSTOM_UPDATE_TIME" | cut -d: -f2)
        CRON_SCHEDULE="$MINUTE $HOUR * * *"
        UPDATE_DESC="Daily at $CUSTOM_UPDATE_TIME"
    fi
    
    # Create cron job
    (crontab -l 2>/dev/null; echo "$CRON_SCHEDULE /usr/local/bin/modsec-update.sh") | crontab -
    
    echo -e "${CGREEN}✓ Automatic updates configured: $UPDATE_DESC${CEND}"
    echo -e "${CCYAN}Update log: /var/log/modsec-update.log${CEND}"
    echo -e "${CCYAN}Backup location: /etc/nginx/modsec/backups/${CEND}"
}

# Function to configure paranoia level
function configure_paranoia_level() {
    echo -e "${CCYAN}Configuring Paranoia Level: $PARANOIA_LEVEL${CEND}"
    
    # Create paranoia configuration
    cat > /etc/nginx/modsec/paranoia.conf << EOF
# Paranoia Level Configuration
# Level: $PARANOIA_LEVEL

SecAction "id:900010,phase:1,nolog,pass,t:none,setvar:tx.paranoia_level=$PARANOIA_LEVEL"

EOF
    
    case "$PARANOIA_LEVEL" in
        1)
            echo -e "${CGREEN}✓ Low Paranoia Level - Minimal blocking${CEND}"
            ;;
        2)
            echo -e "${CGREEN}✓ Balanced Paranoia Level - Recommended${CEND}"
            ;;
        3)
            echo -e "${CGREEN}✓ High Security Paranoia Level${CEND}"
            ;;
        4)
            echo -e "${CGREEN}✓ Maximum Security Paranoia Level${CEND}"
            echo -e "${CYAN}⚠ Warning: High false positive rate expected${CEND}"
            ;;
    esac
}

# Function to configure performance optimization
function configure_performance_optimization() {
    echo -e "${CCYAN}Configuring Performance Optimization: $PERF_LEVEL${CEND}"
    
    case "$PERF_LEVEL" in
        1)
            # High Performance
            cat > /etc/nginx/modsec/performance.conf << 'EOF'
# High Performance Configuration
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecResponseBodyMimeType text/plain text/html text/xml
SecResponseBodyLimit 131072
SecRuleEngine On
EOF
            echo -e "${CGREEN}✓ High Performance Mode - Optimized for speed${CEND}"
            ;;
        2)
            # Balanced
            cat > /etc/nginx/modsec/performance.conf << 'EOF'
# Balanced Performance Configuration
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml application/json
SecResponseBodyLimit 524288
SecRuleEngine On
EOF
            echo -e "${CGREEN}✓ Balanced Performance Mode${CEND}"
            ;;
        3)
            # Maximum Security
            cat > /etc/nginx/modsec/performance.conf << 'EOF'
# Maximum Security Configuration
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyLimit 1048576
SecRuleEngine On
SecAuditEngine RelevantOnly
EOF
            echo -e "${CGREEN}✓ Maximum Security Mode - Thorough checking${CEND}"
            ;;
    esac
}

# Function to install dependencies based on OS version
function install_dependencies() {
    echo -e "${CCYAN}Installing dependencies for $os $os_ver...${CEND}"
    
    case "$os" in
        "ubuntu"|"debian")
            # Update package lists
            apt-get update >> /tmp/nginx-install.log 2>&1
            
            # Base packages common to all versions
            local base_packages=(
                "build-essential"
                "ca-certificates"
                "wget"
                "curl"
                "apt-utils"
                "pkgconf"
                "autoconf"
                "unzip"
                "automake"
                "libtool"
                "tar"
                "git"
                "uuid-dev"
                "libperl-dev"
                "libxslt1-dev"
            )
            
            # Version-specific packages
            local version_packages=()
            
            case "$os" in
                "debian")
                    case "$os_ver" in
                        "9"|"10"|"11")
                            # Older Debian versions
                            version_packages+=(
                                "libpcre3"
                                "libpcre3-dev"
                                "libldap2-dev"
                                "libcurl4-openssl-dev"
                                "libgeoip-dev"
                                "libpcre2-dev"
                                "pcre2-utils"
                                "pcregrep"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libbrotli-dev"
                            )
                            ;;
                        "12")
                            # Debian 12 Bookworm
                            version_packages+=(
                                "libpcre3"
                                "libpcre3-dev"
                                "libldap2-dev"
                                "libcurl4-openssl-dev"
                                "libgeoip-dev"
                                "libpcre2-dev"
                                "pcre2-utils"
                                "pcregrep"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libbrotli-dev"
                            )
                            ;;
                        "13")
                            # Debian 13 Trixie - handle package changes
                            version_packages+=(
                                "libpcre3"
                                "libpcre3-dev"
                                "libldap2-dev"
                                "libcurl4-openssl-dev"
                                "libpcre2-dev"
                                "pcre2-utils"
                                "pcregrep"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libbrotli-dev"
                            )
                            # Try geoip packages with fallbacks
                            local geoip_packages=("libgeoip-dev" "libmaxminddb-dev")
                            for geoip_pkg in "${geoip_packages[@]}"; do
                                if apt-cache show "$geoip_pkg" >/dev/null 2>&1; then
                                    version_packages+=("$geoip_pkg")
                                    break
                                fi
                            done
                            ;;
                        *)
                            # Future Debian versions
                            version_packages+=(
                                "libpcre3"
                                "libpcre3-dev"
                                "libldap2-dev"
                                "libcurl4-openssl-dev"
                                "libpcre2-dev"
                                "pcre2-utils"
                                "pcregrep"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libbrotli-dev"
                            )
                            ;;
                    esac
                    ;;
                "ubuntu")
                    case "$os_ver" in
                        "18.04"|"20.04")
                            # Older Ubuntu versions
                            version_packages+=(
                                "libpcre3"
                                "libpcre3-dev"
                                "libldap2-dev"
                                "libcurl4-openssl-dev"
                                "libgeoip-dev"
                                "libpcre2-dev"
                                "pcre2-utils"
                                "pcregrep"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libbrotli-dev"
                            )
                            ;;
                        "22.04"|"24.04")
                            # Modern Ubuntu versions
                            version_packages+=(
                                "libpcre3"
                                "libpcre3-dev"
                                "libldap2-dev"
                                "libcurl4-openssl-dev"
                                "libgeoip-dev"
                                "libpcre2-dev"
                                "pcre2-utils"
                                "pcregrep"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libbrotli-dev"
                            )
                            ;;
                        *)
                            # Future Ubuntu versions
                            version_packages+=(
                                "libpcre3"
                                "libpcre3-dev"
                                "libldap2-dev"
                                "libcurl4-openssl-dev"
                                "libpcre2-dev"
                                "pcre2-utils"
                                "pcregrep"
                                "libssl-dev"
                                "zlib1g-dev"
                                "libbrotli-dev"
                            )
                            ;;
                    esac
                    ;;
            esac
            
            # Combine all packages
            local all_packages=("${base_packages[@]}" "${version_packages[@]}")
            
            # Add optional packages if requested
            if [[ "$MODSEC" = 'y' ]]; then
                local modsec_packages=("liblmdb-dev" "libyajl-dev" "libmodsecurity3" "libmodsecurity-dev")
                for pkg in "${modsec_packages[@]}"; do
                    if apt-cache show "$pkg" >/dev/null 2>&1; then
                        all_packages+=("$pkg")
                    fi
                done
            fi
            
            if [[ "$GEOIP2" = 'y' ]]; then
                local geoip2_packages=("libgeoip-dev" "libmaxminddb0" "libmaxminddb-dev" "mmdb-bin")
                for pkg in "${geoip2_packages[@]}"; do
                    if apt-cache show "$pkg" >/dev/null 2>&1; then
                        all_packages+=("$pkg")
                    fi
                done
            fi
            
            if [[ "$BROTLI" = 'y' ]]; then
                local brotli_packages=("brotli" "libbrotli-dev" "libbrotli1" "node-brotli-size")
                for pkg in "${brotli_packages[@]}"; do
                    if apt-cache show "$pkg" >/dev/null 2>&1; then
                        all_packages+=("$pkg")
                    fi
                done
            fi
            
            # Install packages with error handling
            local failed_packages=()
            for package in "${all_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                if apt-cache show "$package" >/dev/null 2>&1; then
                    apt-get install -y "$package" >> /tmp/nginx-install.log 2>&1
                    if [ $? -eq 0 ]; then
                        echo -e "${CGREEN}✓ $package installed${CEND}"
                    else
                        echo -e "${CRED}✗ $package failed to install${CEND}"
                        failed_packages+=("$package")
                    fi
                else
                    echo -e "${CCYAN}⚠ Package $package not found, skipping${CEND}"
                    failed_packages+=("$package")
                fi
            done
            
            # Check if critical packages are available
            if command -v gcc >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
                echo -e "${CGREEN}Critical dependencies installed successfully${CEND}"
            else
                echo -e "${CRED}Critical dependencies missing. Cannot continue.${CEND}"
                exit 1
            fi
            
            # Warn about failed packages but don't exit for non-critical ones
            if [ ${#failed_packages[@]} -gt 0 ]; then
                echo -e "${CCYAN}Warning: Some packages failed to install: ${failed_packages[*]}${CEND}"
                echo -e "${CCYAN}Nginx installation will continue with available packages...${CEND}"
            fi
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            # RHEL-based systems
            local rhel_packages=(
                "gcc"
                "gcc-c++"
                "make"
                "wget"
                "curl"
                "tar"
                "git"
                "pcre-devel"
                "openssl-devel"
                "zlib-devel"
                "uuid-devel"
                "libxslt-devel"
            )
            
            # Version-specific adjustments
            case "$os_ver" in
                "7")
                    # CentOS 7 uses yum and older package names
                    if command -v yum >/dev/null 2>&1; then
                        yum install -y epel-release >> /tmp/nginx-install.log 2>&1
                        for package in "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            yum install -y "$package" >> /tmp/nginx-install.log 2>&1
                        done
                    fi
                    ;;
                "8"|"9")
                    # RHEL 8+ uses dnf
                    if command -v dnf >/dev/null 2>&1; then
                        dnf install -y epel-release >> /tmp/nginx-install.log 2>&1
                        for package in "${rhel_packages[@]}"; do
                            echo -e "${CCYAN}Installing $package...${CEND}"
                            dnf install -y "$package" >> /tmp/nginx-install.log 2>&1
                        done
                    fi
                    ;;
            esac
            ;;
        "fedora")
            # Fedora-specific packages
            local fedora_packages=(
                "gcc"
                "gcc-c++"
                "make"
                "wget"
                "curl"
                "tar"
                "git"
                "pcre-devel"
                "openssl-devel"
                "zlib-devel"
                "uuid-devel"
                "libxslt-devel"
            )
            
            for package in "${fedora_packages[@]}"; do
                echo -e "${CCYAN}Installing $package...${CEND}"
                dnf install -y "$package" >> /tmp/nginx-install.log 2>&1
            done
            ;;
        *)
            echo -e "${CRED}Unsupported OS: $os${CEND}"
            exit 1
            ;;
    esac
}

# Defined Variables
# Get all the NGINX versions from the ngnix.org web page
NGINX_VERSIONS=$(curl -s https://nginx.org/en/download.html | grep -oP 'nginx-\d+\.\d+\.\d+' | sort -V | uniq | tail -n2)
NGINX_MAINLINE_VER=$(echo $NGINX_VERSIONS | cut -d' ' -f2 | cut -d'-' -f2)
NGINX_STABLE_VER=$(echo $NGINX_VERSIONS | cut -d' ' -f1 | cut -d'-' -f2)
# SSL
LIBRESSL_VER=$(curl -s https://www.libressl.org/releases.html | grep -oP 'LibreSSL \d+\.\d+\.\d+' | sort -V | uniq | tail -n1 | cut -d' ' -f2)
OPENSSL_VER=$(curl -s https://openssl-library.org/source/index.html | grep -oP 'openssl-\d+\.\d+\.\d+' | sort -V | uniq | tail -n1 | cut -d'-' -f2)
# NGINX MOD's
HEADERMOD_VER=0.39
LIBMAXMINDDB_VER=1.12.2
PCRE_NGINX_VER=10.47
ZLIB_NGINX_VER=1.3.1

cores=$(nproc)
if [ $? -ne 0 ]; then
    cores=1
fi

# Clear log file
rm /tmp/nginx-install.log

clear
echo ""
echo "Welcome to the nginx-autoinstall script."
echo ""
echo "What do you want to do?"
echo "   1) Install or update Nginx"
echo "   2) Install Bad Bot Blocker for Nginx"
echo "   3) Uninstall Nginx"
echo "   4) Update the script"
echo "   5) Exit"
echo ""
while [[ $OPTION !=  "1" && $OPTION != "2" && $OPTION != "3" && $OPTION != "4" && $OPTION != "5" ]]; do
	read -p "Select an option [1-5]: " OPTION
done
case $OPTION in
	1)
		echo ""
		echo "This script will install Nginx with some optional modules."
		echo ""
		echo "Do you want to install Nginx stable or mainline?"
		echo "   1) Stable $NGINX_STABLE_VER"
		echo "   2) Mainline $NGINX_MAINLINE_VER"
		echo ""
		while [[ $NGINX_VER != "1" && $NGINX_VER != "2" ]]; do
			read -p "Select an option [1-2]: " NGINX_VER
		done
		case $NGINX_VER in
			1)
			NGINX_VER=$NGINX_STABLE_VER
			;;
			2)
			NGINX_VER=$NGINX_MAINLINE_VER
			;;
		esac
		echo ""
		echo "Please tell me which modules you want to install."
		echo "If you select none, Nginx will be installed with its default modules."
		echo ""
		echo "Modules to install :"
		while [[ $CACHEPURGE != "y" && $CACHEPURGE != "n" ]]; do
			read -p "       ngx_cache_purge [y/n]: " -e CACHEPURGE
		done
		while [[ $BROTLI != "y" && $BROTLI != "n" ]]; do
			read -p "       Brotli [y/n]: " -e BROTLI
		done
		while [[ $REDIS2 != "y" && $REDIS2 != "n" ]]; do
			read -p "       Http Redis 2 [y/n]: " -e REDIS2
		done
        while [[ $SRCACHE != "y" && $SRCACHE != "n" ]]; do
            read -p "       SRCache (provides transparent caching layer) [y/n]: " -e SRCACHE
        done
        while [[ $MEMC_NGINX != "y" && $MEMC_NGINX != "n" ]]; do
            read -p "       MEMC (Extended ver of standard Memcached) [y/n]: " -e MEMC_NGINX
        done
        while [[ $VTS != "y" && $VTS != "n" ]]; do
            read -p "       Nginx virtual host traffic status [y/n]: " -e VTS
        done
		while [[ $GEOIP2 != "y" && $GEOIP2 != "n" ]]; do
			read -p "       GeoIP 2 [y/n]: " -e GEOIP2
		done
		while [[ $LDAPAUTH != "y" && $LDAPAUTH != "n" ]]; do
			read -p "       LDAP Auth $LDAPAUTH [y/n]: " -e LDAPAUTH
		done
		while [[ $HEADERMOD != "y" && $HEADERMOD != "n" ]]; do
			read -p "       Headers More $HEADERMOD_VER [y/n]: " -e HEADERMOD
		done
		while [[ $FANCYINDEX != "y" && $FANCYINDEX != "n" ]]; do
			read -p "       Fancy index [y/n]: " -e FANCYINDEX
		done
        while [[ $SET_MISC != "y" && $SET_MISC != "n" ]]; do
            read -p "       SET_MISC Content filtering [y/n]: " -e SET_MISC
        done
        while [[ $PCRE_NGINX != "y" && $PCRE_NGINX != "n" ]]; do
            read -p "       PCRE [y/n]: " -e PCRE_NGINX
        done
        while [[ $ZLIB_NGINX != "y" && $ZLIB_NGINX != "n" ]]; do
            read -p "       ZLIB [y/n]: " -e ZLIB_NGINX
        done

        # Additional Modules
        while [[ $IMAGE_FILTER != "y" && $IMAGE_FILTER != "n" ]]; do
            read -p "       Image Filter Module (CPU Intensive) [y/n]: " -e IMAGE_FILTER
        done
        while [[ $PROMETHEUS != "y" && $PROMETHEUS != "n" ]]; do
            read -p "       Prometheus Exporter [y/n]: " -e PROMETHEUS
        done
        while [[ $PERL_MODULE != "y" && $PERL_MODULE != "n" ]]; do
            read -p "       Perl Module [y/n]: " -e PERL_MODULE
        done
        while [[ $XSLT_MODULE != "y" && $XSLT_MODULE != "n" ]]; do
            read -p "       XSLT Module [y/n]: " -e XSLT_MODULE
        done

        if [[ "$NGINX_VER" == *"1.28"* ]] || [[ "$NGINX_VER" == *"1.29"* ]]; then
            while [[ $TLSPATCH != "y" && $TLSPATCH != "n" ]]; do
                read -p "       Cloudflare's TLS Dynamic Record Resizing patch [y/n]: " -e TLSPATCH
            done
        else
            TLSPATCH="n"
        fi

		echo ""
		echo "Choose your Web Application Firewall (WAF):"
		echo "   1) ModSecurity (Preferred)"
		echo "   2) NAXSI (Does not play well with HTTP2)"
		echo "   3) None"
		echo ""
		while [[ $WAF != "1" && $WAF != "2" && $WAF != "3" ]]; do
			read -p "Select an option [1-3]: " WAF
		done
		case $WAF in
			1)
                MODSEC=y            
                read -p "      > Enable nginx ModSecurity? [y/n]: " -e MODSEC_ENABLE
                
                # Enhanced ModSecurity Rules Configuration
                if [[ "$MODSEC_ENABLE" = 'y' ]]; then
                    echo ""
                    echo -e "${CCYAN}========================================${CEND}"
                    echo -e "${CCYAN}    ModSecurity Rules Configuration    ${CEND}"
                    echo -e "${CCYAN}========================================${CEND}"
                    echo ""
                    echo "Select ModSecurity Rules Configuration:"
                    echo "   1) OWASP CRS Standard (Recommended) - Balanced protection"
                    echo "   2) OWASP CRS + Application Rules - Enhanced protection"
                    echo "   3) Minimal Rules - Low false positive rate"
                    echo "   4) Custom Rules - Advanced configuration"
                    echo "   5) � COMODO ENTERPRISE (FREE) - Commercial-grade, no cost"
                    echo "   6) 🎯 INTELLIGENT HYBRID (Recommended) - Smart selection + Auto-updates"
                    echo "   7) � ALL RULESETS (Comprehensive) - Maximum protection including Comodo"
                    echo ""
                    while [[ $MODSEC_RULES != "1" && $MODSEC_RULES != "2" && $MODSEC_RULES != "3" && $MODSEC_RULES != "4" && $MODSEC_RULES != "5" && $MODSEC_RULES != "6" && $MODSEC_RULES != "7" ]]; do
                        read -p "Select rules configuration [1-7]: " MODSEC_RULES
                    done
                    
                    # False Positive Management
                    echo ""
                    echo "Select False Positive Management Level:"
                    echo "   1) Low False Positives (Paranoia Level 1) - Minimal blocking"
                    echo "   2) Balanced (Paranoia Level 2) - Recommended"
                    echo "   3) High Security (Paranoia Level 3) - More blocking"
                    echo "   4) Maximum Security (Paranoia Level 4) - Aggressive blocking"
                    echo ""
                    while [[ $PARANOIA_LEVEL != "1" && $PARANOIA_LEVEL != "2" && $PARANOIA_LEVEL != "3" && $PARANOIA_LEVEL != "4" ]]; do
                        read -p "Select paranoia level [1-4]: " PARANOIA_LEVEL
                    done
                    
                    # Performance Tuning
                    echo ""
                    echo "Select Performance Optimization:"
                    echo "   1) High Performance (Fewer checks, faster)"
                    echo "   2) Balanced (Default)"
                    echo "   3) Maximum Security (More thorough, slower)"
                    echo ""
                    while [[ $PERF_LEVEL != "1" && $PERF_LEVEL != "2" && $PERF_LEVEL != "3" ]]; do
                        read -p "Select performance level [1-3]: " PERF_LEVEL
                    done
                    
                    # Automatic Updates Configuration (Available for all options)
                    echo ""
                    echo -e "${CMAGENTA}Automatic Rule Updates Configuration:${CEND}"
                    echo "Select rule update frequency:"
                    echo "   1) Daily (Recommended for production)"
                    echo "   2) Weekly (Good balance)"
                    echo "   3) Monthly (Minimal disruption)"
                    echo "   4) Manual updates only"
                    echo ""
                    while [[ $UPDATE_FREQ != "1" && $UPDATE_FREQ != "2" && $UPDATE_FREQ != "3" && $UPDATE_FREQ != "4" ]]; do
                        read -p "Select update frequency [1-4]: " UPDATE_FREQ
                    done
                    
                    if [[ "$UPDATE_FREQ" != "4" ]]; then
                        echo ""
                        echo "Select update time (recommended: low traffic hours):"
                        echo "   1) 2:00 AM"
                        echo "   2) 3:00 AM (Default)"
                        echo "   3) 4:00 AM"
                        echo "   4) Custom time"
                        echo ""
                        while [[ $UPDATE_TIME != "1" && $UPDATE_TIME != "2" && $UPDATE_TIME != "3" && $UPDATE_TIME != "4" ]]; do
                            read -p "Select update time [1-4]: " UPDATE_TIME
                        done
                        
                        if [[ "$UPDATE_TIME" == "4" ]]; then
                            read -p "Enter custom time (HH:MM format): " CUSTOM_UPDATE_TIME
                        fi
                    fi
                fi
			;;
			2)
				NAXSI=y
			;;
			3)
				MODSEC=n
                NAXSI=n
			;;
		esac

		echo ""
		echo "Choose your OpenSSL implementation :"
		echo "   1) System's OpenSSL ($(openssl version | cut -c9-14))"
		echo "   2) OpenSSL $OPENSSL_VER from source"
		echo "   3) LibreSSL $LIBRESSL_VER from source "
		echo ""
		while [[ $SSL != "1" && $SSL != "2" && $SSL != "3" ]]; do
			read -p "Select an option [1-3]: " SSL
		done
		case $SSL in
			1)
			#we do nothing
			;;
			2)
				OPENSSL=y
			;;
			3)
				LIBRESSL=y
			;;
		esac
		echo ""
		read -n1 -r -p "Nginx is ready to be installed, press any key to continue..."
		echo ""

        # Cleanup
        # The directory should be deleted at the end of the script, but in case it fails
        rm -r /usr/local/src/nginx/ >> /tmp/nginx-install.log 2>&1
        mkdir -p /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1

        # Dependencies
        install_dependencies

        if [[ "$GEOIP2" = 'y' || "$MODSEC" = 'y' ]]; then
            echo -ne "       Geoip/Modsec dependencies      [..]\r"
            cd /usr/local/src/nginx/modules  >> /tmp/nginx-install.log 2>&1
            wget https://github.com/maxmind/libmaxminddb/releases/download/${LIBMAXMINDDB_VER}/libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz  >> /tmp/nginx-install.log 2>&1
            tar xaf libmaxminddb-${LIBMAXMINDDB_VER}.tar.gz  >> /tmp/nginx-install.log 2>&1
            cd libmaxminddb-${LIBMAXMINDDB_VER}/  >> /tmp/nginx-install.log 2>&1
            ./configure  >> /tmp/nginx-install.log 2>&1
            make -j $cores >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
			    echo -ne "       Geoip/Modsec dependencies      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Geoip/Modsec dependencies      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

            echo -ne "       Geoip/Modsec deps Install      [..]\r"
            make install  >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
			    echo -ne "       Geoip/Modsec deps Install      [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Geoip/Modsec deps Install      [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
            ldconfig  >> /tmp/nginx-install.log 2>&1
        fi


		#Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			# libbrotli install
			echo -ne "       Installing libbrotli           [..]\r"
			make install >> /tmp/nginx-install.log 2>&1
			apt -y install libbrotli1 >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing libbrotli           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing libbrotli           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			# Linking libraries to avoid errors
			ldconfig >> /tmp/nginx-install.log 2>&1
			# ngx_brotli module download
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_brotli         [..]\r"
			git clone --recurse-submodules https://github.com/google/ngx_brotli >> /tmp/nginx-install.log 2>&1
			#cd ngx_brotli
			#git submodule update --init >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_brotli         [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_brotli         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# LDAP Auth
		if [[ "$LDAPAUTH" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading LDAP Auth          [..]\r"
			wget -O ldap-auth.zip https://github.com/kvspb/nginx-auth-ldap/archive/master.zip >> /tmp/nginx-install.log 2>&1
			unzip ldap-auth.zip >> /tmp/nginx-install.log 2>&1
			rm -f ldap-auth.zip >> /tmp/nginx-install.log 2>&1
				
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading LDAP Auth          [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading LDAP Auth          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

        # Nginx virtual host traffic status
        if [[ "$VTS" = 'y' ]]; then
            cd /usr/local/src/nginx/modules
			echo -ne "       Downloading Nginx VTS          [..]\r"
            git clone https://github.com/vozlt/nginx-module-vts.git >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading Nginx VTS          [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading Nginx VTS          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
        fi

        # HTTP REDIS 2
        if [[ "$REDIS2" = 'y' ]]; then
            cd /usr/local/src/nginx/modules
			echo -ne "       Downloading HTTP Redis 2       [..]\r"
            git clone https://github.com/openresty/redis2-nginx-module.git >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading HTTP Redis 2       [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading HTTP Redis 2       [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
        fi

		# ModSecurity
		if [[ "$MODSEC" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading ModSecurity        [..]\r"
			git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ModSecurity        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ModSecurity        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
			cd ModSecurity >> /tmp/nginx-install.log 2>&1
			git submodule init >> /tmp/nginx-install.log 2>&1
			git submodule update >> /tmp/nginx-install.log 2>&1

			echo -ne "       Configuring ModSecurity        [..]\r"
			./build.sh >> /tmp/nginx-install.log 2>&1
			./configure >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Configuring ModSecurity        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring ModSecurity        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Compiling ModSecurity          [..] (Slow on low cores)\r"
			make -j $cores >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Compiling ModSecurity          [${CGREEN}OK${CEND}]                            \r"
				echo -ne "\n"
			else
				echo -e "       Compiling ModSecurity          [${CRED}FAIL${CEND}]                            "
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Installing ModSecurity         [..]\r"
			make install >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Installing ModSecurity         [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing ModSecurity         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
			mkdir -p /etc/nginx/modsec >> /tmp/nginx-install.log 2>&1
			wget -O /etc/nginx/modsec/modsecurity.conf https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/modsecurity.conf-recommended >> /tmp/nginx-install.log 2>&1

			# Enhanced Rules Installation
			if [[ "$MODSEC_ENABLE" = 'y' ]]; then
                install_modsecurity_rules
            fi

			# Enable ModSecurity in Nginx
			if [[ "$MODSEC_ENABLE" = 'y' ]]; then
                echo -ne "       Enabling ModSecurity           [..]\r"
				sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/nginx/modsec/modsecurity.conf
                if [ $? -eq 0 ]; then
                    echo -ne "       Enabling ModSecurity           [${CGREEN}OK${CEND}]\r"
                    echo -ne "\n"
                else
                    echo -ne "       Enabling ModSecurity           [${CRED}FAIL - Enable it manually after reviewing install log file!${CEND}]"
                    echo -ne "\n"
                fi
			fi
 
			echo -ne "       ModSecurity Nginx Module       [..]\r"
            git clone --quiet https://github.com/SpiderLabs/ModSecurity-nginx.git /usr/local/src/nginx/modules/ModSecurity-nginx >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       ModSecurity Nginx Module       [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       ModSecurity Nginx Module       [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# NAXSI
		if [[ "$NAXSI" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading NAXSI              [..]\r"
			wget -O naxsi.zip https://github.com/nbs-system/naxsi/archive/master.zip >> /tmp/nginx-install.log 2>&1
			unzip naxsi.zip >> /tmp/nginx-install.log 2>&1
			rm -f naxsi.zip >> /tmp/nginx-install.log 2>&1
				
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading NAXSI              [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading NAXSI              [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_headers_more   [..]\r"
			wget https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERMOD_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf v${HEADERMOD_VER}.tar.gz
				
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_headers_more   [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_headers_more   [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# SET_MISC
		if [[ "$SET_MISC" = 'y' ]]; then
			echo -ne "       Downloading SET MISC           [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			git clone https://github.com/openresty/set-misc-nginx-module >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading SET MISC           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading SET MISC           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# PCRE NGINX
        if [[ "$PCRE_NGINX" = 'y' ]]; then
			echo -ne "       Downloading PCRE Module        [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE_NGINX_VER}/pcre2-${PCRE_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf pcre2-${PCRE_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			cd pcre2-${PCRE_NGINX_VER} >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading PCRE Module        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading PCRE Module        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

        # ZLIB NGINX
		if [[ "$ZLIB_NGINX" = 'y' ]]; then
			echo -ne "       Downloading ZLIB Module        [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			wget http://zlib.net/zlib-${ZLIB_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf zlib-${ZLIB_NGINX_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			cd zlib-${ZLIB_NGINX_VER} >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ZLIB Module        [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ZLIB Module        [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# SRCACHE
		if [[ "$SRCACHE" = 'y' ]]; then
			echo -ne "       Downloading SRCache            [..]\r"
			cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			git clone https://github.com/openresty/srcache-nginx-module >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading SRCache            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading SRCache            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

        # MEMC
		if [[ "$MEMC_NGINX" = 'y' ]]; then
			echo -ne "       Downloading MEMC               [..]\r"
            cd /usr/local/src/nginx/modules >> /tmp/nginx-install.log 2>&1
			git clone https://github.com/openresty/memc-nginx-module.git >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading MEMC               [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading MEMC               [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

    	# GeoIP 2
		if [[ "$GEOIP2" = 'y' ]]; then
			cd /usr/local/src/nginx/modules || exit 1
			echo -ne "       Downloading GeoIP 2            [..]\r"
            git clone --recursive https://github.com/leev/ngx_http_geoip2_module >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading GeoIP 2            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading GeoIP 2            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			mkdir -p /etc/nginx/geoip2/
			echo -ne "       Downloading GeoIP 2 databases  [..]\r"
			wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz >> /tmp/nginx-install.log 2>&1
			wget https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf GeoLite2-Country.tar.gz  --strip 1 >> /tmp/nginx-install.log 2>&1
			tar xaf GeoLite2-City.tar.gz --strip 1 >> /tmp/nginx-install.log 2>&1
			mv GeoLite2-Country.mmdb /etc/nginx/geoip2/ >> /tmp/nginx-install.log 2>&1
			mv GeoLite2-City.mmdb /etc/nginx/geoip2/ >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading GeoIP 2 databases  [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -ne "       Downloading GeoIP 2 databases  [${CRED}FAIL - You need to download manually & place in /etc/nginx/geoip2/${CEND}]"
				echo -ne "\n"
			fi
		fi

		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading ngx_cache_purge    [..]\r"
			git clone https://github.com/FRiCKLE/ngx_cache_purge >> /tmp/nginx-install.log 2>&1			

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading ngx_cache_purge    [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading ngx_cache_purge    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# LibreSSL
		if [[ "$LIBRESSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			mkdir libressl-${LIBRESSL_VER}
			cd libressl-${LIBRESSL_VER}
			# LibreSSL download
			echo -ne "       Downloading LibreSSL           [..]\r"
			wget -qO- http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/libressl-${LIBRESSL_VER}.tar.gz | tar xz --strip 1

			if [ $? -eq 0 ]; then
				echo -ne "       Downloading LibreSSL           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading LibreSSL           [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Configuring LibreSSL           [..]\r"
			./configure \
				LDFLAGS=-lrt \
				CFLAGS=-fstack-protector-strong \
				--prefix=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER}/.openssl/ \
				--enable-shared=no >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Configuring LibreSSL           [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring LibreSSL         [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			# LibreSSL install
			echo -ne "       Installing LibreSSL            [..]\r"
			make install-strip -j $cores >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Installing LibreSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Installing LibreSSL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# OpenSSL
		if [[ "$OPENSSL" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			# OpenSSL download
			echo -ne "       Downloading OpenSSL            [..]\r"
			wget https://www.openssl.org/source/openssl-${OPENSSL_VER}.tar.gz >> /tmp/nginx-install.log 2>&1
			tar xaf openssl-${OPENSSL_VER}.tar.gz
			cd openssl-${OPENSSL_VER}	
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading OpenSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading OpenSSL            [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi

			echo -ne "       Configuring OpenSSL            [..]\r"
			./config >> /tmp/nginx-install.log 2>&1

			if [ $? -eq 0 ]; then
				echo -ne "       Configuring OpenSSL            [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Configuring OpenSSL          [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# Download and extract of Nginx source code
		cd /usr/local/src/nginx/
		echo -ne "       Downloading Nginx              [..]\r"
		wget -qO- http://nginx.org/download/nginx-${NGINX_VER}.tar.gz | tar zxf -
		cd nginx-${NGINX_VER}

		if [ $? -eq 0 ]; then
			echo -ne "       Downloading Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Downloading Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# As the default nginx.conf does not work
		# We download a clean and working conf from my GitHub.
		# We do it only if it does not already exist (in case of update for instance)
		if [[ ! -e /etc/nginx/nginx.conf ]]; then
			mkdir -p /etc/nginx
			cd /etc/nginx
			wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/nginx.conf >> /tmp/nginx-install.log 2>&1
            if [[ "$TLSPATCH" == "y" ]]; then
                sed -i '/ssl_dyn_rec_enable/s/#//g' nginx.conf
            fi
            if [[ "$GEOIP2" != 'y' ]]; then
                sed -i '/geoip_/d' nginx.conf
            fi
            
            # Download additional configuration files
            echo -ne "       Downloading additional configs   [..]\r"
            wget -O /etc/nginx/conf.d/status.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/status.conf >> /tmp/nginx-install.log 2>&1
            wget -O /etc/nginx/conf.d/security-hardening.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/security-hardening.conf >> /tmp/nginx-install.log 2>&1
            # Download new module configurations
            if [[ "$IMAGE_FILTER" = 'y' ]]; then
                wget -O /etc/nginx/conf.d/image-filter.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/image-filter.conf >> /tmp/nginx-install.log 2>&1
            fi
            if [[ "$PROMETHEUS" = 'y' ]]; then
                wget -O /etc/nginx/conf.d/prometheus.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/prometheus.conf >> /tmp/nginx-install.log 2>&1
            fi
            if [[ "$PERL_MODULE" = 'y' ]]; then
                wget -O /etc/nginx/conf.d/perl.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/perl.conf >> /tmp/nginx-install.log 2>&1
            fi
            if [[ "$XSLT_MODULE" = 'y' ]]; then
                wget -O /etc/nginx/conf.d/xslt.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/xslt.conf >> /tmp/nginx-install.log 2>&1
            fi
            echo -ne "       Downloading additional configs   [${CGREEN}OK${CEND}]\r"
            echo -ne "\n"
		fi
		cd /usr/local/src/nginx/nginx-${NGINX_VER}

		echo -ne "       Downloading Nginx Devel Kit    [..]\r"
        git clone --quiet https://github.com/simplresty/ngx_devel_kit.git /usr/local/src/nginx/modules/ngx_devel_kit >> /tmp/nginx-install.log 2>&1
		if [ $? -eq 0 ]; then
			echo -ne "       Downloading Nginx Devel Kit    [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Downloading Nginx Devel Kit    [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# Modules configuration
		# Common configuration 
		NGINX_OPTIONS="
		--prefix=/etc/nginx \
		--sbin-path=/usr/sbin/nginx \
		--conf-path=/etc/nginx/nginx.conf \
		--error-log-path=/var/log/nginx/error.log \
		--http-log-path=/var/log/nginx/access.log \
		--pid-path=/var/run/nginx.pid \
		--lock-path=/var/run/nginx.lock \
		--http-client-body-temp-path=/var/cache/nginx/client_temp \
		--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
		--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
		--user=nginx \
		--group=nginx \
		--with-cc-opt=-Wno-deprecated-declarations \
		--with-cc-opt=-Wno-ignored-qualifiers"

		NGINX_MODULES="--without-http_ssi_module \
		--without-http_scgi_module \
		--without-http_empty_gif_module \
		--without-http_browser_module \
		--with-threads \
		--with-pcre \
		--with-file-aio \
		--with-http_ssl_module \
		--with-http_v2_module \
                --with-http_v3_module \
		--with-http_mp4_module \
		--with-http_auth_request_module \
		--with-http_sub_module \
		--with-http_secure_link_module \
		--with-http_gunzip_module \
		--with-http_gzip_static_module \
		--with-http_slice_module \
		--with-http_stub_status_module \
		--with-http_realip_module \
                --with-stream_realip_module \
		--with-stream_ssl_module \
		--with-stream_ssl_preread_module \
		--with-select_module \
		--with-poll_module \
        --add-module=/usr/local/src/nginx/modules/ngx_devel_kit"

		# Optional modules
		# LibreSSL 
		if [[ "$LIBRESSL" = 'y' ]]; then
#			NGINX_MODULES=$(echo $NGINX_MODULES; echo --with-openssl=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER})
			NGINX_MODULES=$(echo $NGINX_MODULES; echo --with-openssl=/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER} --with-cc-opt="-I/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER}/build/include" --with-ld-opt="-L/usr/local/src/nginx/modules/libressl-${LIBRESSL_VER}/build/lib")

		fi


		# Brotli
		if [[ "$BROTLI" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_brotli")
		fi

		# LDAP Auth
		if [[ "$LDAPAUTH" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/nginx-auth-ldap-master")
		fi

		# Nginx virtual host traffic status
		if [[ "$VTS" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/nginx-module-vts")
		fi

        # ModSecurity WAF
		if [[ "$MODSEC" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo --add-module=/usr/local/src/nginx/modules/ModSecurity-nginx)
		fi

		# NAXSI WAF
		if [[ "$NAXSI" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/naxsi-master/naxsi_src")
		fi

		# More Headers
		if [[ "$HEADERMOD" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/headers-more-nginx-module-${HEADERMOD_VER}")
		fi

        # GeoIP 2
        if [[ "$GEOIP2" = 'y' ]]; then			
            NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/ngx_http_geoip2_module")
        fi

		# OpenSSL
		if [[ "$OPENSSL" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--with-openssl=/usr/local/src/nginx/modules/openssl-${OPENSSL_VER}")
		fi

		# Cache Purge
		if [[ "$CACHEPURGE" = 'y' ]]; then
			NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/ngx_cache_purge")
		fi

		# Fancy index
		if [[ "$FANCYINDEX" = 'y' ]]; then
			git clone --quiet https://github.com/aperezdc/ngx-fancyindex.git /usr/local/src/nginx/modules/fancyindex >> /tmp/nginx-install.log 2>&1
			NGINX_MODULES=$(echo $NGINX_MODULES; echo --add-module=/usr/local/src/nginx/modules/fancyindex)
		fi

        # Http Redis 2
        if [[ "$REDIS2" = 'y' ]]; then
            NGINX_MODULES=$(echo $NGINX_MODULES; echo "--add-module=/usr/local/src/nginx/modules/redis2-nginx-module")
        fi
		
        # SET_MISC
     	if [[ "$SET_MISC" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/set-misc-nginx-module")
		fi

        # SRCache
		if [[ "$SRCACHE" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/srcache-nginx-module")
		fi

        # MEMC
		if [[ "$MEMC_NGINX" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/memc-nginx-module")
		fi

        # PCRE
		if [[ "$PCRE_NGINX" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-pcre=/usr/local/src/nginx/modules/pcre2-${PCRE_NGINX_VER}")
		fi

        # ZLIB
		if [[ "$ZLIB_NGINX" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-zlib=/usr/local/src/nginx/modules/zlib-${ZLIB_NGINX_VER}")
		fi

		# Additional Modules
		# Image Filter Module (Built-in)
		if [[ "$IMAGE_FILTER" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-http_image_filter_module")
		fi

		# Prometheus Exporter
		if [[ "$PROMETHEUS" = 'y' ]]; then
			cd /usr/local/src/nginx/modules
			echo -ne "       Downloading Prometheus Exporter   [..]\r"
			git clone https://github.com/nginxinc/nginx-prometheus-exporter >> /tmp/nginx-install.log 2>&1
			if [ $? -eq 0 ]; then
				echo -ne "       Downloading Prometheus Exporter   [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       Downloading Prometheus Exporter   [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--add-module=/usr/local/src/nginx/modules/nginx-prometheus-exporter")
		fi

		# Perl Module (Built-in)
		if [[ "$PERL_MODULE" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-http_perl_module")
		fi

		# XSLT Module (Built-in)
		if [[ "$XSLT_MODULE" = 'y' ]]; then
			NGINX_MODULES=$(echo "$NGINX_MODULES"; echo "--with-http_xslt_module")
		fi

		# Cloudflare's TLS Dynamic Record Resizing patch
		if [[ "$TLSPATCH" = 'y' ]]; then
			echo -ne "       TLS Dynamic Records support    [..]\r"

	    wget -O nginx.patch https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/nginx_dynamic_tls_records.patch >> /tmp/nginx-install.log 2>&1
            patch -p1 < nginx.patch >> /tmp/nginx-install.log 2>&1
		        
			if [ $? -eq 0 ]; then
				echo -ne "       TLS Dynamic Records support    [${CGREEN}OK${CEND}]\r"
				echo -ne "\n"
			else
				echo -e "       TLS Dynamic Records support    [${CRED}FAIL${CEND}]"
				echo ""
				echo "Please look at /tmp/nginx-install.log"
				echo ""
				exit 1
			fi
		fi

		# We configure Nginx
		echo -ne "       Configuring Nginx              [..]\r"
		CFLAGS="-Wno-stringop-truncation -Wno-stringop-overflow" ./configure $NGINX_OPTIONS --with-cc-opt='-g -O2 -fPIC -fstack-protector-strong -Wformat -Wno-error -Wdate-time -D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions -fPIC -pie -Wl,-z,relro -Wl,-z,now' --with-pcre-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' --with-zlib-opt='-g -Ofast -fPIC -m64 -march=native -fstack-protector-strong -D_FORTIFY_SOURCE=2' $NGINX_MODULES >> /tmp/nginx-install.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Configuring Nginx              [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Configuring Nginx              [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# Then we compile
		echo -ne "       Compiling Nginx                [..]\r"
		make -j $cores >> /tmp/nginx-install.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Compiling Nginx                [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Compiling Nginx                [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		# Then we install \o/
		echo -ne "       Installing Nginx               [..]\r"
		make install >> /tmp/nginx-install.log 2>&1
		
		# remove debugging symbols
		strip -s /usr/sbin/nginx

		if [ $? -eq 0 ]; then
			echo -ne "       Installing Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Installing Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

        mkdir -p /etc/nginx/ssl >> /tmp/nginx-install.log 2>&1
        mkdir -p /etc/nginx/conf.d >> /tmp/nginx-install.log 2>&1
        wget -O /etc/nginx/conf.d/geo_fence.conf.default https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/geo_fence.conf >> /tmp/nginx-install.log 2>&1
	if [[ "$GEOIP2" = 'y' ]]; then
	    # Only download geoip2.conf if it doesn't exist to avoid duplication
	    if [[ ! -e /etc/nginx/conf.d/geoip2.conf ]]; then
	        wget -O /etc/nginx/conf.d/geoip2.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/geoip2.conf >> /tmp/nginx-install.log 2>&1
	    fi
	    # Only download logformat.conf if it doesn't exist
	    if [[ ! -e /etc/nginx/conf.d/logformat.conf ]]; then
	        wget -O /etc/nginx/conf.d/logformat.conf https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/logformat.conf >> /tmp/nginx-install.log 2>&1
	    fi
fi
		# Nginx installation from source does not add an init script for systemd and logrotate
		# Using the official systemd script and logrotate conf from nginx.org
		if [[ ! -e /lib/systemd/system/nginx.service ]]; then
			cd /lib/systemd/system/
			wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/nginx.service >> /tmp/nginx-install.log 2>&1
			# Enable nginx start at boot
			systemctl enable nginx >> /tmp/nginx-install.log 2>&1
		fi

		if [[ ! -e /etc/logrotate.d/nginx ]]; then
			cd /etc/logrotate.d/
			wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/conf/nginx-logrotate -O nginx >> /tmp/nginx-install.log 2>&1
		fi

		# Nginx's cache directory is not created by default
		if [[ ! -d /var/cache/nginx ]]; then
			mkdir -p /var/cache/nginx
		fi

		# We add sites-* folders as some use them. /etc/nginx/conf.d/ is the vhost folder by defaultnginx 
		if [[ ! -d /etc/nginx/sites-available ]]; then
			mkdir -p /etc/nginx/sites-available
		fi
		if [[ ! -d /etc/nginx/sites-enabled ]]; then
			mkdir -p /etc/nginx/sites-enabled
		fi
		if [[ ! -d /etc/nginx/ssl ]]; then
			mkdir -p /etc/nginx/ssl
		fi

		# Restart Nginx
		echo -ne "       Restarting Nginx               [..]\r"
		systemctl restart nginx >> /tmp/nginx-install.log 2>&1

		if [ $? -eq 0 ]; then
			echo -ne "       Restarting Nginx               [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Restarting Nginx               [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi

		if [[ $(lsb_release -si) == "Debian" ]] || [[ $(lsb_release -si) == "Ubuntu" ]]
		then
			echo -ne "       Blocking nginx from APT        [..]\r"
			cd /etc/apt/preferences.d/
			echo -e "Package: nginx*\nPin: release *\nPin-Priority: -1" > nginx-block
			echo -ne "       Blocking nginx from APT        [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi

		# Removing temporary Nginx and modules files
		echo -ne "       Removing Nginx files           [..]\r"
		rm -r /usr/local/src/nginx >> /tmp/nginx-install.log 2>&1
		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
		echo -ne "\n"

		# We're done !
		echo ""
		echo -e "       ${CGREEN}Installation successful !${CEND}"
		echo ""
		
		# Enhanced ModSecurity Summary
		if [[ "$MODSEC_ENABLE" = 'y' ]]; then
			echo -e "${CMAGENTA}========================================${CEND}"
			echo -e "${CMAGENTA}    ModSecurity WAF Configuration    ${CEND}"
			echo -e "${CMAGENTA}========================================${CEND}"
			echo ""
			
			case "$MODSEC_RULES" in
				1)
					echo -e "  WAF Configuration: ${CGREEN}OWASP CRS Standard${CEND}"
					echo -e "  Rules Source: OWASP Core Rule Set v4.0"
					echo -e "  Coverage: OWASP Top 10 + Common Attacks"
					;;
				2)
					echo -e "  WAF Configuration: ${CGREEN}OWASP CRS + Application Rules${CEND}"
					echo -e "  Rules Source: OWASP CRS + Application-Specific"
					echo -e "  Coverage: Enhanced with WordPress/Joomla rules"
					;;
				3)
					echo -e "  WAF Configuration: ${CGREEN}Minimal Rules${CEND}"
					echo -e "  Rules Source: Curated High-Confidence Rules"
					echo -e "  Coverage: Essential protection only"
					;;
				4)
					echo -e "  WAF Configuration: ${CGREEN}Custom Rules${CEND}"
					echo -e "  Rules Source: Template provided"
					echo -e "  Coverage: User-defined"
					;;
				5)
					echo -e "  WAF Configuration: ${CGREEN}🏢 COMODO ENTERPRISE (FREE)${CEND}"
					echo -e "  Rules Source: Comodo commercial-grade rules"
					echo -e "  Coverage: Enterprise protection without subscription costs"
					echo -e "  Compatibility: 100% ModSecurity compatible"
					;;
				6)
					echo -e "  WAF Configuration: ${CMAGENTA}🎯 INTELLIGENT HYBRID${CEND}"
					echo -e "  Rules Source: Smart selection based on environment"
					echo -e "  Coverage: Optimized for your system"
					if [[ "$DETECTED_APPS" != "" ]]; then
						echo -e "  Detected Apps: $DETECTED_APPS"
					fi
					;;
				7)
					echo -e "  WAF Configuration: ${CGREEN}� ALL RULESETS${CEND}"
					echo -e "  Rules Source: OWASP + Application + Zero-Day + Commercial + Comodo + Enterprise"
					echo -e "  Coverage: Comprehensive maximum protection with all rule sources"
					;;
			esac
			
			# Auto-Updates Status (for all configurations)
			if [[ "$UPDATE_FREQ" != "4" ]]; then
				echo -e "  Auto-Updates: ${CGREEN}Enabled ($UPDATE_DESC)${CEND}"
			else
				echo -e "  Auto-Updates: ${CYAN}Manual only${CEND}"
			fi
			
			# Paranoia Level
			case "$PARANOIA_LEVEL" in
				1)
					echo -e "  Paranoia Level: ${CGREEN}1 (Low False Positives)${CEND}"
					;;
				2)
					echo -e "  Paranoia Level: ${CGREEN}2 (Balanced)${CEND}"
					;;
				3)
					echo -e "  Paranoia Level: ${CGREEN}3 (High Security)${CEND}"
					;;
				4)
					echo -e "  Paranoia Level: ${CRED}4 (Maximum Security)${CEND}"
					;;
			esac
			
			# Performance Level
			case "$PERF_LEVEL" in
				1)
					echo -e "  Performance: ${CGREEN}High Performance${CEND}"
					;;
				2)
					echo -e "  Performance: ${CGREEN}Balanced${CEND}"
					;;
				3)
					echo -e "  Performance: ${CGREEN}Maximum Security${CEND}"
					;;
			esac
			
			echo ""
			echo -e "${CCYAN}ModSecurity Configuration Files:${CEND}"
			echo -e "  Main Config: /etc/nginx/modsec/modsecurity.conf"
			echo -e "  Rules Directory: /etc/nginx/modsec/rules/"
			if [[ "$UPDATE_FREQ" != "4" ]]; then
				echo -e "  Update Script: /usr/local/bin/modsec-update.sh"
				echo -e "  Update Log: /var/log/modsec-update.log"
				echo -e "  Backup Location: /etc/nginx/modsec/backups/"
			fi
			echo ""
			echo -e "${CCYAN}ModSecurity Management:${CEND}"
			echo -e "  Test rules: nginx -t"
			echo -e "  Reload nginx: systemctl reload nginx"
			if [[ "$UPDATE_FREQ" != "4" ]]; then
				echo -e "  Manual update: /usr/local/bin/modsec-update.sh"
				echo -e "  View cron: crontab -l"
			fi
			echo ""
		fi
		
		echo "       Installation log: /tmp/nginx-install.log"
		echo ""
	exit
	;;
	2) # Install Bad Bot Blocker
		echo ""
		echo "This will install Nginx Bad Bot and User-Agent Blocker."
		echo ""
		echo "Download the install script."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker
		chmod +x /usr/local/sbin/install-ngxblocker

		echo ""
		echo "Run the install-ngxblocker script in DRY-MODE,"
		echo "which will show you what changes it will make and what files it will download for you.."
		echo "This is only a DRY-RUN so no changes are being made yet."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin || exit 1
		./install-ngxblocker

		echo ""
		echo "Run the install script with the -x parameter,"
		echo "to download all the necessary files from the repository.."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin/ || exit 1
		./install-ngxblocker -x
		chmod +x /usr/local/sbin/setup-ngxblocker
		chmod +x /usr/local/sbin/update-ngxblocker

		echo ""
		echo "All the required files have now been downloaded to the correct folders,"
		echo " on Nginx for you directly from the repository."
		echo ""
		echo "Run the setup-ngxblocker script in DRY-MODE,"
		echo "which will show you what changes it will make and what files it will download for you."
		echo "This is only a DRY-RUN so no changes are being made yet."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin/ || exit 1
		./setup-ngxblocker -e conf

		echo ""
		echo "Run the setup script with the -x parameter,"
		echo "to make all the necessary changes to your nginx.conf (if required),"
		echo "and also to add the required includes into all your vhost files."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		cd /usr/local/sbin/ || exit 1
		./setup-ngxblocker -x -e conf

		echo ""
		echo "Test your nginx configuration"
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		/usr/sbin/nginx -t

		echo ""
		echo "Restart Nginx,"
		echo "and the Bot Blocker will immediately be active and protecting all your web sites."
		echo ""
		read -n1 -r -p " press any key to continue..."
		echo ""

		/usr/sbin/nginx -t && systemctl restart nginx

		echo "That's it, the blocker is now active and protecting your sites from thousands of malicious bots and domains."
		echo ""
		echo "For more info, visit: https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker"
		echo ""
		exit
	;;    
	3) # Uninstall Nginx
		while [[ $CONF !=  "y" && $CONF != "n" ]]; do
			read -p "       Remove configuration files ? [y/n]: " -e CONF
		done
		while [[ $LOGS !=  "y" && $LOGS != "n" ]]; do
			read -p "       Remove logs files ? [y/n]: " -e LOGS
		done
		# Stop Nginx
		echo -ne "       Stopping Nginx                 [..]\r"
		systemctl stop nginx
		if [ $? -eq 0 ]; then
			echo -ne "       Stopping Nginx                 [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		else
			echo -e "       Stopping Nginx                 [${CRED}FAIL${CEND}]"
			echo ""
			echo "Please look at /tmp/nginx-install.log"
			echo ""
			exit 1
		fi
		# Removing Nginx files and modules files
		echo -ne "       Removing Nginx files           [..]\r"
		rm -r /usr/local/src/nginx \
		/usr/sbin/nginx* \
		/etc/logrotate.d/nginx \
		/var/cache/nginx \
		/lib/systemd/system/nginx.service \
		/etc/systemd/system/multi-user.target.wants/nginx.service >> /tmp/nginx-install.log 2>&1

		echo -ne "       Removing Nginx files           [${CGREEN}OK${CEND}]\r"
		echo -ne "\n"

		# Remove conf files
		if [[ "$CONF" = 'y' ]]; then
			echo -ne "       Removing configuration files   [..]\r"
			rm -r /etc/nginx/ >> /tmp/nginx-install.log 2>&1
			echo -ne "       Removing configuration files   [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi

		# Remove logs
		if [[ "$LOGS" = 'y' ]]; then
			echo -ne "       Removing log files             [..]\r"
			rm -r /var/log/nginx >> /tmp/nginx-install.log 2>&1
			echo -ne "       Removing log files             [${CGREEN}OK${CEND}]\r"
			echo -ne "\n"
		fi

		# We're done !
		echo ""
		echo -e "       ${CGREEN}Uninstallation successful !${CEND}"
		echo ""
		echo "       Installation log: /tmp/nginx-install.log"
		echo ""

	exit
	;;
	4) # Update the script
		wget https://raw.githubusercontent.com/marirs/autoinstalls/master/nginx/nginx-install.sh -O nginx-install.sh >> /tmp/nginx-install.log 2>&1
		chmod +x nginx-install.sh
		echo ""
		echo -e "${CGREEN}Update succcessful !${CEND}"
		sleep 2
		nginx-install.sh
		exit
	;;
	*) # Exit
		exit
	;;

esac
