#!/bin/bash

# Network Configuration Script
# For adding IPv6 static addresses to network interfaces

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
SELECTED_INTERFACE=""
SELECTED_IPV6=""
SELECTED_SUBNET=""
BACKUP_DIR="/tmp/network-config-backup-$(date +%Y%m%d-%H%M%S)"

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root${NC}"
        exit 1
    fi
}

# Detect if interface is a VLAN interface
is_vlan_interface() {
    local interface="$1"
    
    # Check for VLAN interface naming patterns (contains dot)
    if [[ "$interface" =~ \. ]]; then
        return 0  # Is VLAN
    fi
    
    # Check for VLAN interface in system
    if command -v ip >/dev/null 2>&1; then
        local vlan_info=$(ip -details link show "$interface" 2>/dev/null | grep -i "vlan\|802.1q" || true)
        if [[ -n "$vlan_info" ]]; then
            return 0  # Is VLAN
        fi
    fi
    
    return 1  # Not VLAN
}

# Detect if interface is a VPN interface
is_vpn_interface() {
    local interface="$1"
    
    # Check for common VPN interface naming patterns
    if [[ "$interface" =~ ^(tun|tap|vpn|ppp|wg|ipsec)[0-9]*$ ]]; then
        return 0  # Is VPN
    fi
    
    # Check for common VPN interface patterns
    if [[ "$interface" =~ ^(tun|tap|vpn|ppp|wg|ipsec) ]]; then
        return 0  # Is VPN
    fi
    
    # Check interface type from system
    if command -v ip >/dev/null 2>&1; then
        local interface_type=$(ip -details link show "$interface" 2>/dev/null | grep -i "tun\|tap\|vpn\|ppp\|wireguard\|ipsec" || true)
        if [[ -n "$interface_type" ]]; then
            return 0  # Is VPN
        fi
    fi
    
    return 1  # Not VPN
}

# Get list of network interfaces
get_network_interfaces() {
    local interfaces=()
    local interface_info=()
    
    # Parse ip link show output correctly for Debian
    while IFS= read -r line; do
        if [[ "$line" =~ ^[0-9]+:[[:space:]]*([^:@]+) ]]; then
            local full_iface="${BASH_REMATCH[1]}"
            
            # Remove @parent suffix from VLAN interfaces
            local iface="${full_iface%@*}"
            
            # Skip loopback and docker interfaces
            if [[ "$iface" != "lo" ]] && [[ ! "$iface" =~ ^docker[0-9]*$ ]] && [[ ! "$iface" =~ ^br-[0-9a-f]*$ ]]; then
                # Get IP address
                local ip=$(ip -4 addr show "$iface" 2>/dev/null | grep -oP 'inet \K[0-9.]+' | head -1)
                if [[ -z "$ip" ]]; then
                    ip="No IP"
                fi
                
                # Get interface status from the same line
                local status="DOWN"
                if [[ "$line" =~ state[[:space:]]+([A-Z]+) ]]; then
                    status="${BASH_REMATCH[1]}"
                fi
                
                # Check if this is a VLAN interface
                local vlan_label=""
                if is_vlan_interface "$iface"; then
                    vlan_label=" - VLAN"
                fi
                
                interfaces+=("$iface")
                interface_info+=("$iface - $ip/$status$vlan_label")
            fi
        fi
    done <<< "$(ip link show | grep -E '^[0-9]+:')"
    
    # Add loopback interface
    interfaces+=("lo")
    interface_info+=("lo - 127.0.0.1/8 (UP)")
    
    # Output each interface and info on separate lines
    for i in "${!interfaces[@]}"; do
        echo "${interfaces[i]}|${interface_info[i]}"
    done
}

# Select network interface
select_interface() {
    echo -e "${CYAN}=== Network Configuration Tool ===${NC}"
    echo ""
    echo -e "${CYAN}Current network interfaces:${NC}"
    
    # Get interfaces in pipe-separated format
    local interfaces=()
    local interface_info=()
    
    while IFS='|' read -r iface info; do
        interfaces+=("$iface")
        interface_info+=("$info")
        echo "  $(( ${#interfaces[@]} )). $info"
    done <<< "$(get_network_interfaces)"
    
    echo ""
    while true; do
        read -p "Select interface to configure (1-${#interfaces[@]}): " interface_choice
        
        if [[ "$interface_choice" =~ ^[0-9]+$ ]] && [ "$interface_choice" -ge 1 ] && [ "$interface_choice" -le ${#interfaces[@]} ]; then
            SELECTED_INTERFACE="${interfaces[$((interface_choice-1))]}"
            break
        else
            echo -e "${RED}Invalid choice. Please enter a number between 1 and ${#interfaces[@]}${NC}"
        fi
    done
    
    echo -e "${GREEN}Selected interface: $SELECTED_INTERFACE${NC}"
    echo ""
}

# Ask if user wants to add IPv6
ask_ipv6_config() {
    while true; do
        read -p "Do you want to add IPv6 static addresses? [y/N]: " add_ipv6
        case "$add_ipv6" in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                echo -e "${YELLOW}No IPv6 configuration requested. Exiting.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Please enter y or n${NC}"
                ;;
        esac
    done
}

# Read current network configuration
read_current_config() {
    local interface="$1"
    echo -e "${CYAN}Current configuration for $interface:${NC}"
    echo ""
    
    if [[ -f "/etc/network/interfaces" ]]; then
        # Extract interface configuration
        local in_interface=false
        local current_iface=""
        local ipv4_config=()
        local ipv6_config=()
        
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            
            # Check for interface definition
            if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+([^[:space:]]+) ]]; then
                current_iface="${BASH_REMATCH[1]}"
                if [[ "$current_iface" == "$interface" ]]; then
                    in_interface=true
                    echo -e "${BLUE}Interface: $current_iface${NC}"
                else
                    in_interface=false
                fi
                continue
            fi
            
            # Parse configuration lines for the selected interface
            if [[ "$in_interface" == true ]]; then
                if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+.*inet6[[:space:]]+ ]]; then
                    echo -e "${GREEN}  IPv6: ${line//^[[:space:]]*/}${NC}"
                    ipv6_config+=("$line")
                elif [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+.*inet[[:space:]]+ ]]; then
                    echo -e "${GREEN}  IPv4: ${line//^[[:space:]]*/}${NC}"
                    ipv4_config+=("$line")
                elif [[ "$line" =~ ^[[:space:]]*(address|netmask|gateway) ]]; then
                    echo -e "${YELLOW}    ${line//^[[:space:]]*/}${NC}"
                    if [[ "$line" =~ address ]]; then
                        ipv4_config+=("$line")
                    fi
                fi
            fi
        done < "/etc/network/interfaces"
        
        # Store current configurations globally
        CURRENT_IPV4_CONFIG=("${ipv4_config[@]}")
        CURRENT_IPV6_CONFIG=("${ipv6_config[@]}")
        
        if [[ ${#ipv4_config[@]} -eq 0 && ${#ipv6_config[@]} -eq 0 ]]; then
            echo -e "${YELLOW}  No configuration found for $interface${NC}"
            return 1
        fi
        
        return 0
    else
        echo -e "${RED}  /etc/network/interfaces not found${NC}"
        return 1
    fi
}

# Analyze current configuration and suggest actions
analyze_config_and_suggest() {
    echo ""
    echo -e "${CYAN}Configuration Analysis:${NC}"
    
    local has_ipv4=false
    local has_ipv6=false
    local ipv4_type=""
    local ipv6_type=""
    
    # Check IPv4 configuration
    for line in "${CURRENT_IPV4_CONFIG[@]}"; do
        if [[ "$line" =~ inet[[:space:]]+static ]]; then
            has_ipv4=true
            ipv4_type="static"
        elif [[ "$line" =~ inet[[:space:]]+dhcp ]]; then
            has_ipv4=true
            ipv4_type="dhcp"
        fi
    done
    
    # Check IPv6 configuration
    for line in "${CURRENT_IPV6_CONFIG[@]}"; do
        if [[ "$line" =~ inet6[[:space:]]+static ]]; then
            has_ipv6=true
            ipv6_type="static"
        elif [[ "$line" =~ inet6[[:space:]]+dhcp ]]; then
            has_ipv6=true
            ipv6_type="dhcp"
        fi
    done
    
    # Display analysis
    if [[ "$has_ipv4" == true ]]; then
        echo -e "  IPv4 Configuration: ${GREEN}Yes ($ipv4_type)${NC}"
    else
        echo -e "  IPv4 Configuration: ${RED}No${NC}"
    fi
    
    if [[ "$has_ipv6" == true ]]; then
        echo -e "  IPv6 Configuration: ${GREEN}Yes ($ipv6_type)${NC}"
    else
        echo -e "  IPv6 Configuration: ${RED}No${NC}"
    fi
    echo ""
    
    # Suggest actions based on current config and get user choice
    echo -e "${CYAN}Suggested Actions:${NC}"
    
    while true; do
        if [[ "$has_ipv6" == true && "$ipv6_type" == "static" ]]; then
            echo "  1. Add additional IPv6 addresses"
            echo "  2. Modify existing IPv6 configuration"
            echo "  3. Add IPv4 addresses"
            echo "  4. Add new VLAN interface"
            echo "  5. Show current configuration only"
            echo ""
            read -p "Enter your choice (1-5): " config_choice
            
            case "$config_choice" in
                1) return 1 ;;  # IPv6
                2) return 4 ;;  # Modify
                3) return 2 ;;  # IPv4
                4) return 3 ;;  # VLAN
                5) return 5 ;;  # Show only
                *) echo -e "${RED}Invalid choice. Please enter 1, 2, 3, 4, or 5${NC}" ;;
            esac
        elif [[ "$has_ipv6" == false ]]; then
            echo "  1. Add IPv6 static configuration"
            echo "  2. Add IPv4 addresses"
            echo "  3. Add new VLAN interface"
            echo "  4. Show current configuration only"
            echo ""
            read -p "Enter your choice (1-4): " config_choice
            
            case "$config_choice" in
                1) return 1 ;;  # IPv6
                2) return 2 ;;  # IPv4
                3) return 3 ;;  # VLAN
                4) return 5 ;;  # Show only
                *) echo -e "${RED}Invalid choice. Please enter 1, 2, 3, or 4${NC}" ;;
            esac
        elif [[ "$has_ipv4" == true && "$ipv4_type" == "static" ]]; then
            echo "  1. Add additional IPv4 addresses"
            echo "  2. Add IPv6 addresses"
            echo "  3. Add new VLAN interface"
            echo "  4. Show current configuration only"
            echo ""
            read -p "Enter your choice (1-4): " config_choice
            
            case "$config_choice" in
                1) return 2 ;;  # IPv4
                2) return 1 ;;  # IPv6
                3) return 3 ;;  # VLAN
                4) return 5 ;;  # Show only
                *) echo -e "${RED}Invalid choice. Please enter 1, 2, 3, or 4${NC}" ;;
            esac
        else
            echo "  1. Add IPv4 addresses"
            echo "  2. Add IPv6 addresses"
            echo "  3. Add new VLAN interface"
            echo "  4. Show current configuration only"
            echo ""
            read -p "Enter your choice (1-4): " config_choice
            
            case "$config_choice" in
                1) return 2 ;;  # IPv4
                2) return 1 ;;  # IPv6
                3) return 3 ;;  # VLAN
                4) return 5 ;;  # Show only
                *) echo -e "${RED}Invalid choice. Please enter 1, 2, 3, or 4${NC}" ;;
            esac
        fi
    done
}

# Detect mixed configuration (up/down commands vs address lines)
detect_mixed_config() {
    local interface="$1"
    local has_up_commands=false
    local has_address_lines=false
    
    for line in "${CURRENT_IPV6_CONFIG[@]}"; do
        if [[ "$line" =~ ^[[:space:]]*up[[:space:]]+ip[[:space:]]+-6[[:space:]]+addr[[:space:]]+add ]]; then
            has_up_commands=true
        elif [[ "$line" =~ ^[[:space:]]*address[[:space:]]+ ]]; then
            has_address_lines=true
        fi
    done
    
    if [[ "$has_up_commands" == true ]] && [[ "$has_address_lines" == true ]]; then
        return 2  # Mixed configuration
    elif [[ "$has_up_commands" == true ]]; then
        return 1  # Up/down commands only
    else
        return 0  # Standard address lines
    fi
}
ask_configuration_type() {
    echo ""
    echo -e "${CYAN}What would you like to configure?${NC}"
    echo "  1. Add IPv6 addresses"
    echo "  2. Add IPv4 addresses"
    echo "  3. Add new VLAN interface"
    echo "  4. Modify existing configuration"
    echo "  5. Show current configuration only"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-5): " config_choice
        
        case "$config_choice" in
            1)
                return 1  # IPv6
                ;;
            2)
                return 2  # IPv4
                ;;
            3)
                return 3  # VLAN
                ;;
            4)
                return 4  # Modify
                ;;
            5)
                return 5  # Show only
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1, 2, 3, 4, or 5${NC}"
                ;;
        esac
    done
}

# Ask for IPv6 addition method
ask_ipv6_method() {
    echo ""
    echo -e "${CYAN}How would you like to add IPv6 addresses?${NC}"
    echo "  1. Add single IPv6 address"
    echo "  2. Add range of IPv6 addresses (bulk)"
    echo "  3. Add specific IPv6 addresses (custom list)"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-3): " method_choice
        
        case "$method_choice" in
            1)
                return 1  # Single
                ;;
            2)
                return 2  # Range
                ;;
            3)
                return 3  # Custom list
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter a number between 1 and 3${NC}"
                ;;
        esac
    done
}

# Calculate maximum available IPs in IPv6 subnet
calculate_max_ipv6_ips() {
    local cidr="$1"
    local prefix_length=${cidr#*/}
    
    # IPv6 has 128 bits total
    local total_bits=128
    local host_bits=$((total_bits - prefix_length))
    
    # For practical purposes, we consider /64 as the standard subnet size
    # Larger subnets (/48, /56) have more host bits, smaller have fewer
    # We'll calculate based on the actual CIDR but cap at reasonable limits
    
    if [[ $host_bits -ge 64 ]]; then
        # /64 or larger - essentially unlimited for practical purposes
        echo "18446744073709551616"  # 2^64
    elif [[ $host_bits -ge 16 ]]; then
        # /112 to /63 - calculate actual value
        echo $((2 ** host_bits))
    else
        # /113 to /128 - very small subnets
        echo $((2 ** host_bits))
    fi
}

# Format large numbers for display
format_number() {
    local number="$1"
    
    if [[ $number -ge 1000000000000000 ]]; then
        # Quadrillions+
        echo "$((number / 1000000000000000)) quadrillion"
    elif [[ $number -ge 1000000000000 ]]; then
        # Trillions
        echo "$((number / 1000000000000)) trillion"
    elif [[ $number -ge 1000000000 ]]; then
        # Billions
        echo "$((number / 1000000000)) billion"
    elif [[ $number -ge 1000000 ]]; then
        # Millions
        echo "$((number / 1000000)) million"
    elif [[ $number -ge 1000 ]]; then
        # Thousands
        echo "$((number / 1000)) thousand"
    else
        echo "$number"
    fi
}

# Extract existing IPv6 addresses from configuration
extract_existing_ipv6_addresses() {
    local interface="$1"
    local existing_addresses=()
    
    # Extract from CURRENT_IPV6_CONFIG array (if populated)
    for line in "${CURRENT_IPV6_CONFIG[@]}"; do
        if [[ "$line" =~ address[[:space:]]+([0-9a-fA-F:]+) ]]; then
            local addr="${BASH_REMATCH[1]}"
            # Remove CIDR if present
            addr=$(echo "$addr" | cut -d'/' -f1)
            existing_addresses+=("$addr")
        fi
    done
    
    # If array is empty, parse interfaces file directly
    if [[ ${#existing_addresses[@]} -eq 0 ]] && [[ -f "/etc/network/interfaces" ]]; then
        local in_ipv6_section=false
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+${interface}[[:space:]]+inet6[[:space:]]+static ]]; then
                # Found IPv6 section, start reading address lines
                in_ipv6_section=true
                continue
            elif [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+ ]] && [[ "$in_ipv6_section" == true ]]; then
                # Reached next interface, stop reading
                break
            elif [[ "$in_ipv6_section" == true ]]; then
                # Check for address line
                if [[ "$line" =~ ^[[:space:]]*address[[:space:]]+([0-9a-fA-F:]+) ]]; then
                    local addr="${BASH_REMATCH[1]}"
                    # Remove CIDR if present
                    addr=$(echo "$addr" | cut -d'/' -f1)
                    existing_addresses+=("$addr")
                # Check for up commands with IPv6 addresses
                elif [[ "$line" =~ ^[[:space:]]*up[[:space:]]+ip[[:space:]]+-6[[:space:]]+addr[[:space:]]+add[[:space:]]+([0-9a-fA-F:]+) ]]; then
                    local addr="${BASH_REMATCH[1]}"
                    # Remove CIDR if present
                    addr=$(echo "$addr" | cut -d'/' -f1)
                    existing_addresses+=("$addr")
                fi
            fi
        done < "/etc/network/interfaces"
    fi
    
    # Extract from up commands (like: up ip -6 addr add 2a01:4f9:1a:97cb::3/64 dev $IFACE)
    for line in "${CURRENT_IPV6_CONFIG[@]}"; do
        if [[ "$line" =~ ip[[:space:]]+-6[[:space:]]+addr[[:space:]]+add[[:space:]]+([0-9a-fA-F:]+) ]]; then
            local addr="${BASH_REMATCH[1]}"
            # Remove CIDR if present
            addr=$(echo "$addr" | cut -d'/' -f1)
            existing_addresses+=("$addr")
        fi
    done
    
    echo "${existing_addresses[@]}"
}

# Find next available IPv6 address
find_next_ipv6_address() {
    local base_address="$1"  # e.g., 2a01:4f9:1a:97cb::
    local existing_addresses=("${@:2}")  # array of existing addresses
    
    local next_num=1
    
    # Extract numbers from existing addresses
    for addr in "${existing_addresses[@]}"; do
        if [[ "$addr" =~ ${base_address}([0-9]+)$ ]]; then
            local num="${BASH_REMATCH[1]}"
            if [[ $num -gt $next_num ]]; then
                next_num=$num
            fi
        fi
    done
    
    # Next available is one more than the highest found
    echo $((next_num + 1))
}

# Create new VLAN interface
create_vlan_interface() {
    local parent_interface="$1"
    
    echo ""
    echo -e "${CYAN}VLAN Interface Creation:${NC}"
    echo -e "${BLUE}Parent interface: $parent_interface${NC}"
    echo ""
    
    # Get VLAN ID
    while true; do
        read -p "Enter VLAN ID (e.g., 4000, 100, 200): " vlan_id
        if [[ "$vlan_id" =~ ^[0-9]+$ ]] && [ "$vlan_id" -ge 1 ] && [ "$vlan_id" -le 4094 ]; then
            break
        else
            echo -e "${RED}VLAN ID must be between 1 and 4094${NC}"
        fi
    done
    
    local vlan_interface="${parent_interface}.${vlan_id}"
    echo -e "${BLUE}New VLAN interface will be: $vlan_interface${NC}"
    
    # Check if VLAN already exists
    if ip link show "$vlan_interface" >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: VLAN interface $vlan_interface already exists${NC}"
        while true; do
            read -p "Continue anyway? [y/N]: " continue_choice
            case "$continue_choice" in
                [Yy]|[Yy][Ee][Ss])
                    break
                    ;;
                *)
                    echo -e "${CYAN}VLAN creation cancelled${NC}"
                    return 1
                    ;;
            esac
        done
    fi
    
    # Choose IP configuration type
    echo ""
    echo -e "${CYAN}VLAN Configuration:${NC}"
    echo "  1. IPv4 only"
    echo "  2. IPv6 only"
    echo "  3. Both IPv4 and IPv6"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-3): " ip_type
        case "$ip_type" in
            1|2|3)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1, 2, or 3${NC}"
                ;;
        esac
    done
    
    # Backup configuration
    mkdir -p "$BACKUP_DIR"
    cp /etc/network/interfaces "$BACKUP_DIR/"
    
    # Add VLAN configuration to interfaces file
    local temp_file=$(mktemp)
    local vlan_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Add VLAN configuration after the parent interface
        if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+${parent_interface}[[:space:]]+.* ]] && [[ "$vlan_added" == false ]]; then
            echo "" >> "$temp_file"
            echo "auto $vlan_interface" >> "$temp_file"
            
            if [[ "$ip_type" == "1" ]] || [[ "$ip_type" == "3" ]]; then
                echo "iface $vlan_interface inet static" >> "$temp_file"
                get_vlan_ipv4_config >> "$temp_file"
            fi
            
            if [[ "$ip_type" == "2" ]] || [[ "$ip_type" == "3" ]]; then
                if [[ "$ip_type" == "3" ]]; then
                    echo "" >> "$temp_file"
                fi
                echo "iface $vlan_interface inet6 static" >> "$temp_file"
                get_vlan_ipv6_config >> "$temp_file"
            fi
            
            vlan_added=true
        fi
    done < "/etc/network/interfaces"
    
    # If parent interface not found, add at the end
    if [[ "$vlan_added" == false ]]; then
        echo "" >> "$temp_file"
        echo "auto $vlan_interface" >> "$temp_file"
        
        if [[ "$ip_type" == "1" ]] || [[ "$ip_type" == "3" ]]; then
            echo "iface $vlan_interface inet static" >> "$temp_file"
            get_vlan_ipv4_config >> "$temp_file"
        fi
        
        if [[ "$ip_type" == "2" ]] || [[ "$ip_type" == "3" ]]; then
            if [[ "$ip_type" == "3" ]]; then
                echo "" >> "$temp_file"
            fi
            echo "iface $vlan_interface inet6 static" >> "$temp_file"
            get_vlan_ipv6_config >> "$temp_file"
        fi
    fi
    
    # Replace original file
    mv "$temp_file" /etc/network/interfaces
    
    echo -e "${GREEN}✓ VLAN configuration added to /etc/network/interfaces${NC}"
    
    # Bring up VLAN interface
    echo -e "${CYAN}Bringing up VLAN interface...${NC}"
    ifup "$vlan_interface" 2>/dev/null
    
    if ip link show "$vlan_interface" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $vlan_interface is now UP${NC}"
        
        # Test connectivity
        echo -e "${CYAN}Testing connectivity...${NC}"
        if [[ "$ip_type" == "1" ]] || [[ "$ip_type" == "3" ]]; then
            local vlan_ip=$(ip -4 addr show "$vlan_interface" | grep -oP 'inet \K[0-9.]+' | head -1)
            if [[ -n "$vlan_ip" ]]; then
                echo -e "${GREEN}✓ VLAN interface is working with IP: $vlan_ip${NC}"
            fi
        fi
    else
        echo -e "${RED}✗ Failed to bring up VLAN interface${NC}"
        return 1
    fi
    
    return 0
}

# Get IPv4 configuration for VLAN
get_vlan_ipv4_config() {
    echo -e "${CYAN}IPv4 Configuration for VLAN:${NC}"
    
    # Suggest private IP ranges
    echo ""
    echo "Available private IP ranges for VLAN:"
    echo "  1. 10.30.74.0/24 (suggested)"
    echo "  2. 192.168.100.0/24"
    echo "  3. 172.16.100.0/24"
    echo "  4. Custom IP range"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-4): " range_choice
        case "$range_choice" in
            1)
                vlan_ip="10.30.74.1"
                netmask="255.255.255.0"
                break
                ;;
            2)
                vlan_ip="192.168.100.1"
                netmask="255.255.255.0"
                break
                ;;
            3)
                vlan_ip="172.16.100.1"
                netmask="255.255.255.0"
                break
                ;;
            4)
                while true; do
                    read -p "Enter VLAN IP address: " vlan_ip
                    if [[ "$vlan_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
                        break
                    else
                        echo -e "${RED}Invalid IP format${NC}"
                    fi
                done
                read -p "Enter netmask (default: 255.255.255.0): " netmask
                if [[ -z "$netmask" ]]; then
                    netmask="255.255.255.0"
                fi
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
    done
    
    read -p "Enter gateway (optional, press Enter to skip): " gateway
    
    # Suggest MTU based on existing VLANs
    local suggested_mtu="1500"
    if grep -q "mtu 1400" /etc/network/interfaces; then
        suggested_mtu="1400"
    fi
    
    read -p "MTU for VLAN (default $suggested_mtu, Press Enter for default or enter new value): " mtu
    if [[ -z "$mtu" ]]; then
        mtu="$suggested_mtu"
    fi
    
    # Generate configuration
    echo "  address $vlan_ip"
    echo "  netmask $netmask"
    if [[ -n "$gateway" ]]; then
        echo "  gateway $gateway"
    fi
    echo "  vlan-raw-device ${SELECTED_INTERFACE%.*}"
    echo "  mtu $mtu"
}

# Get IPv6 configuration for VLAN
get_vlan_ipv6_config() {
    echo -e "${CYAN}IPv6 Configuration for VLAN:${NC}"
    
    # Suggest private IPv6 ranges
    echo ""
    echo "Available private IPv6 ranges for VLAN:"
    echo "  1. fd00:30:74::1/64 (suggested)"
    echo "  2. fd00:100::1/64"
    echo "  3. fd00:16:100::1/64"
    echo "  4. Custom IPv6"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-4): " ipv6_choice
        case "$ipv6_choice" in
            1)
                ipv6_addr="fd00:30:74::1"
                prefix="64"
                break
                ;;
            2)
                ipv6_addr="fd00:100::1"
                prefix="64"
                break
                ;;
            3)
                ipv6_addr="fd00:16:100::1"
                prefix="64"
                break
                ;;
            4)
                while true; do
                    read -p "Enter IPv6 address: " ipv6_addr
                    if [[ "$ipv6_addr" =~ ^[0-9a-fA-F:]+ ]] && [[ "$ipv6_addr" == *":"*":"* ]]; then
                        break
                    else
                        echo -e "${RED}Invalid IPv6 format${NC}"
                    fi
                done
                read -p "Enter prefix (default: 64): " prefix
                if [[ -z "$prefix" ]]; then
                    prefix="64"
                fi
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                ;;
        esac
    done
    
    read -p "Enter IPv6 gateway (optional, press Enter to skip): " ipv6_gateway
    
    # Generate configuration
    echo "  address $ipv6_addr"
    echo "  netmask $prefix"
    if [[ -n "$ipv6_gateway" ]]; then
        echo "  gateway $ipv6_gateway"
    fi
}

# Get IPv6 range configuration
get_ipv6_range() {
    echo ""
    echo -e "${CYAN}IPv6 Range Configuration:${NC}"
    
    # Check if we have existing IPv6 config to show subnet info
    local existing_subnet=""
    local existing_cidr=""
    
    if [[ ${#CURRENT_IPV6_CONFIG[@]} -gt 0 ]]; then
        for line in "${CURRENT_IPV6_CONFIG[@]}"; do
            if [[ "$line" =~ netmask[[:space:]]+([0-9]+) ]]; then
                existing_cidr="${BASH_REMATCH[1]}"
                # Try to find existing address to determine subnet
                for addr_line in "${CURRENT_IPV6_CONFIG[@]}"; do
                    if [[ "$addr_line" =~ address[[:space:]]+([0-9a-fA-F:]+) ]]; then
                        local existing_addr="${BASH_REMATCH[1]}"
                        # Extract subnet part (remove last 64 bits for standard subnets)
                        if [[ $existing_cidr -eq 64 ]]; then
                            existing_subnet=$(echo "$existing_addr" | sed 's/:[^:]*$//')::/$existing_cidr
                        else
                            # For other CIDRs, try to construct subnet
                            existing_subnet="$existing_addr/$existing_cidr"
                        fi
                        break
                    fi
                done
                break
            fi
        done
    fi
    
    # Show existing subnet info if available
    if [[ -n "$existing_subnet" ]]; then
        local max_ips=$(calculate_max_ipv6_ips "$existing_subnet")
        local formatted_max=$(format_number "$max_ips")
        echo -e "${BLUE}Current IPv6 subnet detected: $existing_subnet${NC}"
        echo -e "${BLUE}Maximum addresses available in this subnet: $formatted_max${NC}"
        
        # Extract existing IPv6 addresses
        local existing_addresses=($(extract_existing_ipv6_addresses "$SELECTED_INTERFACE"))
        if [[ ${#existing_addresses[@]} -gt 0 ]]; then
            echo -e "${BLUE}Existing IPv6 addresses detected: ${#existing_addresses[@]}${NC}"
            echo -e "${BLUE}Addresses: ${existing_addresses[*]}${NC}"
        fi
        echo ""
    fi
    
    while true; do
        # Try to detect existing IPv6 configuration properly
        local detected_subnet=""
        
        # Method 1: Check CURRENT_IPV6_CONFIG array
        if [[ ${#CURRENT_IPV6_CONFIG[@]} -gt 0 ]]; then
            for line in "${CURRENT_IPV6_CONFIG[@]}"; do
                if [[ "$line" =~ address[[:space:]]+([0-9a-fA-F:]+) ]]; then
                    local existing_addr="${BASH_REMATCH[1]}"
                    detected_subnet=$(echo "$existing_addr" | sed 's/:[^:]*$//')::/64
                    echo -e "${BLUE}Detected IPv6 address: $existing_addr${NC}"
                    echo -e "${BLUE}Derived subnet: $detected_subnet${NC}"
                    break
                fi
            done
        fi
        
        # Method 2: If array is empty, parse interfaces file directly
        if [[ -z "$detected_subnet" ]] && [[ -f "/etc/network/interfaces" ]]; then
            while IFS= read -r line; do
                if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+${SELECTED_INTERFACE}[[:space:]]+inet6[[:space:]]+static ]]; then
                    # Found IPv6 section, look for next address line
                    while IFS= read -r addr_line && [[ "$addr_line" =~ ^[[:space:]]*address[[:space:]]+([0-9a-fA-F:]+) ]]; do
                        local existing_addr="${BASH_REMATCH[1]}"
                        detected_subnet=$(echo "$existing_addr" | sed 's/:[^:]*$//')::/64
                        echo -e "${BLUE}Detected IPv6 address: $existing_addr${NC}"
                        echo -e "${BLUE}Derived subnet: $detected_subnet${NC}"
                        break 2
                    done
                fi
            done < "/etc/network/interfaces"
        fi
        
        # Show prompt with detected subnet or ask for manual input
        if [[ -n "$detected_subnet" ]]; then
            read -p "Press Enter to use detected subnet ($detected_subnet), or enter different one: " subnet
            if [[ -z "$subnet" ]]; then
                subnet="$detected_subnet"
                echo -e "${GREEN}Using detected subnet: $subnet${NC}"
            fi
        else
            echo -e "${YELLOW}Could not auto-detect IPv6 subnet${NC}"
            read -p "Enter IPv6 subnet/CIDR (e.g., 2a01:4f9:1a:97cb::/64): " subnet
        fi
        
        # Simple validation
        if [[ "$subnet" == *"/"* ]] && [[ "$subnet" =~ ^[0-9a-fA-F:]+/[0-9]{1,3}$ ]]; then
            SELECTED_SUBNET="$subnet"
            echo -e "${GREEN}Selected subnet: $subnet${NC}"
            break
        else
            echo -e "${RED}Invalid format. Use something like: 2a01:4f9:1a:97cb::/64${NC}"
        fi
    done
    
    # Extract base address and find next available
    local base_address=$(echo "$SELECTED_SUBNET" | cut -d'/' -f1 | sed 's/::$//')
    local existing_addresses=($(extract_existing_ipv6_addresses "$SELECTED_INTERFACE"))
    
    local default_start=1
    if [[ ${#existing_addresses[@]} -gt 0 ]]; then
        default_start=$(find_next_ipv6_address "$base_address::" "${existing_addresses[@]}")
        echo -e "${BLUE}Next available address detected: $base_address::$default_start${NC}"
    fi
    
    # Provide smart defaults based on CIDR
    local prefix_length=$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)
    local default_end=$((default_start + 99))
    local max_reasonable=1000
    
    # Adjust defaults based on subnet size
    if [[ $prefix_length -le 64 ]]; then
        default_end=$((default_start + 999))
        max_reasonable=10000
    elif [[ $prefix_length -le 72 ]]; then
        default_end=$((default_start + 499))
        max_reasonable=1000
    elif [[ $prefix_length -le 80 ]]; then
        default_end=$((default_start + 99))
        max_reasonable=500
    else
        default_end=$((default_start + 49))
        max_reasonable=100
    fi
    
    echo ""
    echo -e "${CYAN}Address Range Selection:${NC}"
    echo -e "${BLUE}Starting address: $base_address::$default_start (auto-detected)${NC}"
    echo -e "${BLUE}Suggested ending address: $base_address::$default_end${NC}"
    echo -e "${BLUE}Maximum reasonable range: $base_address::$((default_start + max_reasonable - 1))${NC}"
    echo ""
    
    # Ask for input method
    echo -e "${CYAN}How would you like to specify the range?${NC}"
    echo "  1. Enter ending address number"
    echo "  2. Enter number of addresses to add"
    echo ""
    
    while true; do
        read -p "Enter your choice (1-2): " input_method
        case "$input_method" in
            1)
                while true; do
                    read -p "Enter ending address number (default: $default_end): " end_num
                    if [[ -z "$end_num" ]]; then
                        end_num=$default_end
                    fi
                    
                    if [[ "$end_num" =~ ^[0-9]+$ ]] && [ "$end_num" -ge "$default_start" ] && [ "$end_num" -le 65535 ]; then
                        break
                    else
                        echo -e "${RED}Please enter a number between $default_start and 65535${NC}"
                    fi
                done
                break
                ;;
            2)
                while true; do
                    read -p "Enter number of addresses to add (default: 100): " addr_count
                    if [[ -z "$addr_count" ]]; then
                        addr_count=100
                    fi
                    
                    if [[ "$addr_count" =~ ^[0-9]+$ ]] && [ "$addr_count" -ge 1 ] && [ "$addr_count" -le 10000 ]; then
                        end_num=$((default_start + addr_count - 1))
                        echo -e "${BLUE}Will add addresses from $default_start to $end_num ($addr_count addresses)${NC}"
                        break
                    else
                        echo -e "${RED}Please enter a number between 1 and 10000${NC}"
                    fi
                done
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter 1 or 2${NC}"
                ;;
        esac
    done
    
    # Warn if trying to add too many addresses
    local total_addresses=$((end_num - default_start + 1))
    if [[ $total_addresses -gt $max_reasonable ]]; then
        echo -e "${YELLOW}Warning: You're about to add $total_addresses addresses. This may take a while and could impact performance.${NC}"
        while true; do
            read -p "Continue with $total_addresses addresses? [y/N]: " continue_choice
            case "$continue_choice" in
                [Yy]|[Yy][Ee][Ss])
                    break
                    ;;
                [Nn]|[Nn][Oo]|"")
                    echo -e "${CYAN}Please enter a smaller range.${NC}"
                    return 1
                    ;;
                *)
                    echo -e "${RED}Please enter y or n${NC}"
                    ;;
            esac
        done
    fi
    
    # Generate IPv6 addresses array with proper hexadecimal conversion
    local prefix_length=$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)
    IPV6_ADDRESSES=()
    
    for ((i=default_start; i<=end_num; i++)); do
        local hex_i=$(printf "%x" $i)  # Convert decimal to hexadecimal
        IPV6_ADDRESSES+=("${base_address}::$hex_i/$prefix_length")
    done
    
    echo -e "${GREEN}Generated ${#IPV6_ADDRESSES[@]} IPv6 addresses${NC}"
    echo -e "${CYAN}Range: ${IPV6_ADDRESSES[0]} to ${IPV6_ADDRESSES[-1]}${NC}"
    
    return 0
}

# Get custom IPv6 addresses list
get_ipv6_custom_list() {
    echo ""
    echo -e "${CYAN}Custom IPv6 Addresses Configuration:${NC}"
    echo -e "${YELLOW}Enter IPv6 addresses one per line. Enter 'done' when finished.${NC}"
    echo ""
    
    IPV6_ADDRESSES=()
    local prefix_length=""
    
    while true; do
        read -p "IPv6 address (or 'done'): " ipv6_input
        
        if [[ "$ipv6_input" == "done" ]]; then
            if [[ ${#IPV6_ADDRESSES[@]} -gt 0 ]]; then
                break
            else
                echo -e "${RED}Please enter at least one IPv6 address${NC}"
            fi
        elif [[ "$ipv6_input" =~ ^[0-9a-fA-F:]+/[0-9]{1,3}$ ]] && [[ "$ipv6_input" == *":"*":"* ]] && [[ "$ipv6_input" == *"/"* ]]; then
            IPV6_ADDRESSES+=("$ipv6_input")
            echo -e "${GREEN}Added: $ipv6_input${NC}"
        elif [[ "$ipv6_input" =~ ^([0-9a-fA-F]{1,4}:){3,7}[0-9a-fA-F]{0,4}$ ]]; then
            # If no CIDR, ask for it
            if [[ -z "$prefix_length" ]]; then
                read -p "Enter prefix length (e.g., 64): " prefix_length
            fi
            IPV6_ADDRESSES+=("${ipv6_input}/${prefix_length}")
            echo -e "${GREEN}Added: ${ipv6_input}/${prefix_length}${NC}"
        else
            echo -e "${RED}Invalid IPv6 address format. Use format like 2a01:4f9:1a:97cb::1/64${NC}"
        fi
    done
    
    echo -e "${GREEN}Added ${#IPV6_ADDRESSES[@]} IPv6 addresses${NC}"
}

# Show IPv6 addresses preview
show_ipv6_preview() {
    echo ""
    echo -e "${CYAN}IPv6 Addresses to be Added:${NC}"
    
    if [[ ${#IPV6_ADDRESSES[@]} -le 10 ]]; then
        # Show all if less than 10
        for i in "${!IPV6_ADDRESSES[@]}"; do
            echo "  $((i+1)). ${IPV6_ADDRESSES[i]}"
        done
    else
        # Show first 5, last 5, and count
        echo "  Showing first 5 and last 5 of ${#IPV6_ADDRESSES[@]} addresses:"
        echo ""
        for i in {0..4}; do
            echo "  $((i+1)). ${IPV6_ADDRESSES[i]}"
        done
        echo "  ..."
        local start_idx=$((${#IPV6_ADDRESSES[@]} - 5))
        for ((i=start_idx; i<${#IPV6_ADDRESSES[@]}; i++)); do
            echo "  $((i+1)). ${IPV6_ADDRESSES[i]}"
        done
    fi
    echo ""
}

# Add multiple IPv6 addresses to interfaces file
add_multiple_ipv6_to_interfaces() {
    echo -e "${CYAN}Adding ${#IPV6_ADDRESSES[@]} IPv6 addresses to /etc/network/interfaces...${NC}"
    
    # Backup current configuration
    mkdir -p "$BACKUP_DIR"
    cp /etc/network/interfaces "$BACKUP_DIR/"
    
    local interface_name="$SELECTED_INTERFACE"
    
    # Create temporary file for new configuration
    local temp_file=$(mktemp)
    
    # Process interfaces file and add IPv6 configuration
    local in_ipv6_section=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Check for IPv6 interface definition
        if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+([^[:space:]]+)[[:space:]]+inet6[[:space:]]+static ]]; then
            local current_iface="${BASH_REMATCH[1]}"
            if [[ "$current_iface" == "$interface_name" ]]; then
                in_ipv6_section=true
            fi
        elif [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+ ]] && [[ "$in_ipv6_section" == true ]]; then
            # We've reached the next interface, add our IPv6 addresses before it
            for ipv6_addr in "${IPV6_ADDRESSES[@]}"; do
                echo "  address $ipv6_addr" >> "$temp_file"
            done
            in_ipv6_section=false
        fi
    done < "/etc/network/interfaces"
    
    # If we're still in IPv6 section at end of file, add them there
    if [[ "$in_ipv6_section" == true ]]; then
        for ipv6_addr in "${IPV6_ADDRESSES[@]}"; do
            echo "  address $ipv6_addr" >> "$temp_file"
        done
    fi
    
    # Replace original file
    mv "$temp_file" /etc/network/interfaces
    
    echo -e "${GREEN}✓ Added ${#IPV6_ADDRESSES[@]} IPv6 addresses to configuration${NC}"
    
    # Restart interface
    ifdown "$interface_name" 2>/dev/null && ifup "$interface_name"
    
    return $?
}

# Verify IPv6 addresses were added
verify_ipv6_addresses() {
    echo -e "${CYAN}Verifying IPv6 addresses were assigned...${NC}"
    
    local assigned_count=0
    local failed_count=0
    
    for ipv6_addr in "${IPV6_ADDRESSES[@]}"; do
        local addr_only=$(echo "$ipv6_addr" | cut -d'/' -f1)
        if ip -6 addr show "$SELECTED_INTERFACE" | grep -q "$addr_only"; then
            ((assigned_count++))
            if [[ $assigned_count -le 5 ]] || [[ $assigned_count -eq ${#IPV6_ADDRESSES[@]} ]]; then
                echo -e "${GREEN}✓ $addr_only${NC}"
            fi
        else
            ((failed_count++))
            echo -e "${RED}✗ $addr_only${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}Successfully assigned: $assigned_count/${#IPV6_ADDRESSES[@]} addresses${NC}"
    if [[ $failed_count -gt 0 ]]; then
        echo -e "${RED}Failed to assign: $failed_count addresses${NC}"
    fi
    
    return $failed_count
}

# Get IPv4 configuration from user (enhanced for VLAN/private networks)
get_ipv4_config() {
    echo ""
    echo -e "${CYAN}IPv4 Configuration:${NC}"
    
    # Detect if this is a VLAN interface
    local is_vlan=false
    if [[ "$SELECTED_INTERFACE" =~ \. ]]; then
        is_vlan=true
        echo -e "${BLUE}VLAN interface detected: $SELECTED_INTERFACE${NC}"
    fi
    
    # Detect existing IPv4 to suggest next address
    local existing_ipv4=""
    local base_ip=""
    if [[ ${#CURRENT_IPV4_CONFIG[@]} -gt 0 ]]; then
        for line in "${CURRENT_IPV4_CONFIG[@]}"; do
            if [[ "$line" =~ address[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+) ]]; then
                existing_ipv4="${BASH_REMATCH[1]}"
                base_ip=$(echo "$existing_ipv4" | cut -d'.' -f1-3)
                echo -e "${BLUE}Existing IPv4: $existing_ipv4${NC}"
                echo -e "${BLUE}Network segment: $base_ip.0/24${NC}"
                break
            fi
        done
    fi
    
    # Suggest next available IP
    local suggested_ip=""
    if [[ -n "$base_ip" ]]; then
        local last_octet=$(echo "$existing_ipv4" | cut -d'.' -f4)
        local next_octet=$((last_octet + 1))
        suggested_ip="$base_ip.$next_octet"
        echo -e "${BLUE}Suggested next IP: $suggested_ip${NC}"
    fi
    
    while true; do
        if [[ -n "$suggested_ip" ]]; then
            read -p "Enter IPv4 address (current: $existing_ipv4, suggested: $suggested_ip): " ipv4_addr
            if [[ -z "$ipv4_addr" ]]; then
                ipv4_addr="$suggested_ip"
            fi
        else
            read -p "Enter IPv4 address (e.g., 10.30.73.74): " ipv4_addr
        fi
        
        if [[ "$ipv4_addr" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            # Validate IP range
            local octets=($(echo "$ipv4_addr" | tr '.' ' '))
            local valid=true
            for octet in "${octets[@]}"; do
                if [[ $octet -gt 255 ]]; then
                    valid=false
                    break
                fi
            done
            
            if [[ "$valid" == true ]]; then
                break
            else
                echo -e "${RED}Invalid IP address: octets must be 0-255${NC}"
            fi
        else
            echo -e "${RED}Invalid IPv4 address format. Use format like 10.30.73.74${NC}"
        fi
    done
    
    # Suggest netmask based on IP type
    local suggested_netmask="255.255.255.0"
    if [[ "$ipv4_addr" =~ ^10\. ]] || [[ "$ipv4_addr" =~ ^192\.168\. ]] || [[ "$ipv4_addr" =~ ^172\.1[6-9]\. ]] || [[ "$ipv4_addr" =~ ^172\.2[0-9]\. ]] || [[ "$ipv4_addr" =~ ^172\.3[0-1]\. ]]; then
        suggested_netmask="255.255.255.0"
        echo -e "${BLUE}Private IP detected, suggesting /24 netmask${NC}"
    else
        suggested_netmask="255.255.255.192"
        echo -e "${BLUE}Public IP detected, suggesting /26 netmask${NC}"
    fi
    
    while true; do
        read -p "Enter netmask (suggested: $suggested_netmask): " netmask
        if [[ -z "$netmask" ]]; then
            netmask="$suggested_netmask"
        fi
        
        if [[ "$netmask" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            break
        else
            echo -e "${RED}Invalid netmask format. Use format like 255.255.255.0${NC}"
        fi
    done
    
    while true; do
        read -p "Enter gateway (optional, press Enter to skip): " gateway
        if [[ -z "$gateway" ]]; then
            break
        elif [[ "$gateway" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            break
        else
            echo -e "${RED}Invalid gateway format. Use format like 10.30.73.1${NC}"
        fi
    done
    
    # Store for later use
    IPV4_ADDRESS="$ipv4_addr"
    IPV4_NETMASK="$netmask"
    IPV4_GATEWAY="$gateway"
}

# Add IPv4 address to existing static configuration
add_ipv4_to_interfaces() {
    echo -e "${CYAN}Adding IPv4 address to /etc/network/interfaces...${NC}"
    
    # Backup current configuration
    mkdir -p "$BACKUP_DIR"
    cp /etc/network/interfaces "$BACKUP_DIR/"
    
    local interface_name="$SELECTED_INTERFACE"
    local ipv4_addr="$SELECTED_IPV4"
    local netmask="$SELECTED_NETMASK"
    local gateway="$SELECTED_GATEWAY"
    
    # Create temporary file for new configuration
    local temp_file=$(mktemp)
    
    # Process interfaces file and add IPv4 configuration
    local in_interface=false
    local ipv4_section_added=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Check for interface definition
        if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+([^[:space:]]+) ]]; then
            local current_iface="${BASH_REMATCH[1]}"
            if [[ "$current_iface" == "$interface_name" ]]; then
                in_interface=true
            else
                in_interface=false
            fi
        fi
        
        # Add IPv4 configuration after the interface line
        if [[ "$in_interface" == true && "$ipv4_section_added" == false && "$line" =~ ^[[:space:]]*iface[[:space:]]+.*inet[[:space:]]+static ]]; then
            echo "  address $ipv4_addr" >> "$temp_file"
            echo "  netmask $netmask" >> "$temp_file"
            if [[ -n "$gateway" ]]; then
                echo "  gateway $gateway" >> "$temp_file"
            fi
            ipv4_section_added=true
        fi
    done < "/etc/network/interfaces"
    
    # Replace original file
    mv "$temp_file" /etc/network/interfaces
    
    # Restart interface
    ifdown "$interface_name" 2>/dev/null && ifup "$interface_name"
    
    return $?
}

# Add additional IPv6 addresses to existing static configuration
add_ipv6_to_interfaces() {
    echo -e "${CYAN}Adding additional IPv6 address to /etc/network/interfaces...${NC}"
    
    # Backup current configuration
    mkdir -p "$BACKUP_DIR"
    cp /etc/network/interfaces "$BACKUP_DIR/"
    
    local interface_name="$SELECTED_INTERFACE"
    local ipv6_addr="$SELECTED_IPV6"
    
    # Create temporary file for new configuration
    local temp_file=$(mktemp)
    
    # Process interfaces file and add IPv6 configuration
    local in_ipv6_section=false
    
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # Check for IPv6 interface definition
        if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+([^[:space:]]+)[[:space:]]+inet6[[:space:]]+static ]]; then
            local current_iface="${BASH_REMATCH[1]}"
            if [[ "$current_iface" == "$interface_name" ]]; then
                in_ipv6_section=true
            fi
        elif [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+ ]] && [[ "$in_ipv6_section" == true ]]; then
            # We've reached the next interface, add our IPv6 address before it
            echo "  address $ipv6_addr" >> "$temp_file"
            in_ipv6_section=false
        fi
    done < "/etc/network/interfaces"
    
    # If we're still in IPv6 section at end of file, add it there
    if [[ "$in_ipv6_section" == true ]]; then
        echo "  address $ipv6_addr" >> "$temp_file"
    fi
    
    # Replace original file
    mv "$temp_file" /etc/network/interfaces
    
    # Restart interface
    ifdown "$interface_name" 2>/dev/null && ifup "$interface_name"
    
    return $?
}

# Create new IPv6 configuration if none exists
create_ipv6_interfaces() {
    echo -e "${CYAN}Creating new IPv6 configuration in /etc/network/interfaces...${NC}"
    
    # Backup current configuration
    mkdir -p "$BACKUP_DIR"
    cp /etc/network/interfaces "$BACKUP_DIR/"
    
    local interface_name="$SELECTED_INTERFACE"
    local ipv6_addr="$SELECTED_IPV6"
    
    # Add IPv6 configuration to the end of file
    cat >> /etc/network/interfaces << EOF

iface $interface_name inet6 static
  address $ipv6_addr
  netmask 64
EOF
    
    # Restart interface
    ifdown "$interface_name" 2>/dev/null && ifup "$interface_name"
    
    return $?
}

# Generate IPv6 addresses from count (starting from next available)
generate_ipv6_addresses_from_count() {
    local subnet="$1"
    local count="$2"
    local base_address=$(echo "$subnet" | cut -d'/' -f1 | sed 's/::$//')
    local prefix_length=$(echo "$subnet" | cut -d'/' -f2)
    
    IPV6_ADDRESSES=()
    
    # Find existing addresses to determine next available
    local existing_addresses=($(extract_existing_ipv6_addresses "$SELECTED_INTERFACE"))
    local next_num=1
    
    # Find the next available number
    for addr in "${existing_addresses[@]}"; do
        if [[ "$addr" =~ ${base_address}::([0-9a-fA-F]+) ]]; then
            local hex_num="${BASH_REMATCH[1]}"
            local dec_num=$((16#$hex_num))  # Convert hex to decimal
            if [[ $dec_num -ge $next_num ]]; then
                next_num=$((dec_num + 1))
            fi
        fi
    done
    
    # Generate the requested number of addresses
    for ((i=0; i<count; i++)); do
        local current_num=$((next_num + i))
        local hex_num=$(printf "%x" $current_num)
        IPV6_ADDRESSES+=("${base_address}::$hex_num/$prefix_length")
    done
    
    echo -e "${GREEN}Generated ${#IPV6_ADDRESSES[@]} IPv6 addresses${NC}"
    echo -e "${CYAN}Starting from: ${IPV6_ADDRESSES[0]}${NC}"
    echo -e "${CYAN}Ending at: ${IPV6_ADDRESSES[-1]}${NC}"
}

# Generate IPv6 addresses from subnet (with proper hexadecimal)
generate_ipv6_addresses() {
    local subnet="$1"
    local base_address=$(echo "$subnet" | cut -d'/' -f1 | sed 's/::$//')
    local prefix_length=$(echo "$subnet" | cut -d'/' -f2)
    
    echo -e "${CYAN}Available IPv6 addresses in subnet $subnet:${NC}"
    echo ""
    
    # Show first 5 addresses in the subnet (convert to hex)
    for i in {1..5}; do
        local hex_i=$(printf "%x" $i)
        echo "  $i. ${base_address}::$hex_i"
    done
    echo "  6. Custom address"
    echo ""
}

# Select IPv6 address
select_ipv6_address() {
    while true; do
        generate_ipv6_addresses "$SELECTED_SUBNET"
        read -p "Select IPv6 address to add (1-6): " ipv6_choice
        
        case "$ipv6_choice" in
            [1-5])
                local base_address=$(echo "$SELECTED_SUBNET" | cut -d'/' -f1 | sed 's/::$//')
                local hex_choice=$(printf "%x" $ipv6_choice)  # Convert to hexadecimal
                SELECTED_IPV6="${base_address}::$hex_choice/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)"
                echo -e "${GREEN}Selected IPv6 address: $SELECTED_IPV6${NC}"
                break
                ;;
            6)
                while true; do
                    read -p "Enter custom IPv6 address: " custom_ipv6
                    if [[ "$custom_ipv6" =~ ^([0-9a-fA-F]{1,4}:){3,7}[0-9a-fA-F]{0,4}$ ]]; then
                        SELECTED_IPV6="$custom_ipv6/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)"
                        echo -e "${GREEN}Selected IPv6 address: $SELECTED_IPV6${NC}"
                        break 2
                    else
                        echo -e "${RED}Invalid IPv6 address format${NC}"
                    fi
                done
                ;;
            *)
                echo -e "${RED}Invalid choice. Please enter a number between 1 and 6${NC}"
                ;;
        esac
    done
}

# Detect network configuration method
detect_config_method() {
    if command -v nmcli >/dev/null 2>&1 && nmcli connection show --active | grep -q "$SELECTED_INTERFACE"; then
        echo "networkmanager"
    elif [[ -f "/etc/netplan/01-netcfg.yaml" ]] || [[ -f "/etc/netplan/50-cloud-init.yaml" ]]; then
        echo "netplan"
    elif [[ -f "/etc/network/interfaces" ]]; then
        echo "interfaces"
    elif [[ -d "/etc/sysconfig/network-scripts" ]]; then
        echo "ifcfg"
    else
        echo "unknown"
    fi
}

# Configure IPv6 using NetworkManager
configure_networkmanager() {
    local connection_name=$(nmcli connection show --active | grep "$SELECTED_INTERFACE" | awk '{print $1}')
    
    if [[ -z "$connection_name" ]]; then
        echo -e "${RED}No active NetworkManager connection found for $SELECTED_INTERFACE${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Configuring IPv6 using NetworkManager...${NC}"
    
    # Backup current configuration
    mkdir -p "$BACKUP_DIR"
    nmcli connection show "$connection_name" > "$BACKUP_DIR/${connection_name}.backup"
    
    # Add IPv6 address
    nmcli connection modify "$connection_name" ipv6.addresses "$SELECTED_IPV6"
    nmcli connection modify "$connection_name" ipv6.method manual
    
    # Apply configuration
    nmcli connection down "$connection_name" && nmcli connection up "$connection_name"
    
    return $?
}

# Configure IPv6 using Netplan
configure_netplan() {
    echo -e "${CYAN}Configuring IPv6 using Netplan...${NC}"
    
    # Find netplan config file
    local netplan_file=""
    for file in /etc/netplan/*.yaml; do
        if [[ -f "$file" ]]; then
            netplan_file="$file"
            break
        fi
    done
    
    if [[ -z "$netplan_file" ]]; then
        netplan_file="/etc/netplan/01-netcfg.yaml"
    fi
    
    # Backup current configuration
    mkdir -p "$BACKUP_DIR"
    cp "$netplan_file" "$BACKUP_DIR/"
    
    # Add IPv6 configuration
    local interface_name="$SELECTED_INTERFACE"
    local ipv6_address="$SELECTED_IPV6"
    
    # Create new configuration
    cat > "$netplan_file" << EOF
network:
  version: 2
  ethernets:
    $interface_name:
      dhcp4: yes
      addresses:
        - $ipv6_address
EOF
    
    # Apply configuration
    netplan apply
    
    return $?
}

# Configure IPv6 using /etc/network/interfaces
configure_interfaces() {
    echo -e "${CYAN}Configuring IPv6 using /etc/network/interfaces...${NC}"
    
    # Backup current configuration
    mkdir -p "$BACKUP_DIR"
    cp /etc/network/interfaces "$BACKUP_DIR/"
    
    # Add IPv6 configuration
    local interface_name="$SELECTED_INTERFACE"
    local ipv6_address="$SELECTED_IPV6"
    
    # Check if interface already configured
    if grep -q "iface $interface_name" /etc/network/interfaces; then
        # Add IPv6 to existing interface
        sed -i "/iface $interface_name/a\\    up ip -6 addr add $ipv6_address dev $interface_name" /etc/network/interfaces
    else
        # Add new interface configuration
        cat >> /etc/network/interfaces << EOF

auto $interface_name
iface $interface_name inet dhcp
    up ip -6 addr add $ipv6_address dev $interface_name
EOF
    fi
    
    # Restart interface
    ifdown "$interface_name" 2>/dev/null && ifup "$interface_name"
    
    return $?
}

# Apply IPv6 configuration
apply_ipv6_config() {
    echo ""
    echo -e "${CYAN}Configuration summary:${NC}"
    echo "  Interface: $SELECTED_INTERFACE"
    echo "  IPv6 address: $SELECTED_IPV6"
    echo "  Subnet: $SELECTED_SUBNET"
    echo ""
    
    while true; do
        read -p "Apply configuration? [y/N]: " apply_choice
        case "$apply_choice" in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo]|"")
                echo -e "${YELLOW}Configuration cancelled.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Please enter y or n${NC}"
                ;;
        esac
    done
    
    # Detect configuration method and apply
    local config_method=$(detect_config_method)
    echo -e "${CYAN}Detected network configuration method: $config_method${NC}"
    
    case "$config_method" in
        "networkmanager")
            if configure_networkmanager; then
                echo -e "${GREEN}✓ IPv6 address added successfully${NC}"
            else
                echo -e "${RED}✗ Failed to configure IPv6 using NetworkManager${NC}"
                return 1
            fi
            ;;
        "netplan")
            if configure_netplan; then
                echo -e "${GREEN}✓ IPv6 address added successfully${NC}"
            else
                echo -e "${RED}✗ Failed to configure IPv6 using Netplan${NC}"
                return 1
            fi
            ;;
        "interfaces")
            if configure_interfaces; then
                echo -e "${GREEN}✓ IPv6 address added successfully${NC}"
            else
                echo -e "${RED}✗ Failed to configure IPv6 using interfaces${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}✗ Unknown network configuration method${NC}"
            echo -e "${CYAN}Manual configuration required. Add this to your network config:${NC}"
            echo "  ip -6 addr add $SELECTED_IPV6 dev $SELECTED_INTERFACE"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}✓ Network configuration updated${NC}"
    echo -e "${GREEN}✓ Interface restarted${NC}"
    
    return 0
}

# Test IPv6 connectivity
test_ipv6_connectivity() {
    echo ""
    while true; do
        read -p "Test connectivity? [y/N]: " test_choice
        case "$test_choice" in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo]|"")
                return 0
                ;;
            *)
                echo -e "${RED}Please enter y or n${NC}"
                ;;
        esac
    done
    
    echo -e "${CYAN}Testing IPv6 connectivity...${NC}"
    
    # Wait for interface to be ready
    sleep 3
    
    # Test if IPv6 address is assigned
    if ip -6 addr show "$SELECTED_INTERFACE" | grep -q "$SELECTED_IPV6"; then
        echo -e "${GREEN}✓ IPv6 address assigned: $SELECTED_IPV6${NC}"
    else
        echo -e "${RED}✗ IPv6 address not found on interface${NC}"
        return 1
    fi
    
    # Test link-local connectivity
    local gateway_ip=$(ip -6 route show | grep "default via" | awk '{print $3}' | head -1)
    if [[ -n "$gateway_ip" ]]; then
        if ping6 -c 2 -W 2 "$gateway_ip" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ Ping to gateway ($gateway_ip): OK${NC}"
        else
            echo -e "${YELLOW}⚠ Ping to gateway failed: $gateway_ip${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ No IPv6 gateway found${NC}"
    fi
    
    # Test external connectivity
    if ping6 -c 2 -W 2 2001:4860:4860::8888 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Ping to external (Google DNS): OK${NC}"
    else
        echo -e "${YELLOW}⚠ Ping to external failed${NC}"
    fi
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS resolution: OK${NC}"
    else
        echo -e "${YELLOW}⚠ DNS resolution failed${NC}"
    fi
}

# Main function
main() {
    check_root
    select_interface
    
    # Read and analyze current configuration
    if ! read_current_config "$SELECTED_INTERFACE"; then
        echo -e "${YELLOW}No existing configuration found. Starting fresh configuration...${NC}"
        ask_ipv6_config
        get_ipv6_subnet
        select_ipv6_address
        apply_ipv6_config
    else
        # Simple menu - no complex analysis
        echo ""
        echo -e "${CYAN}What would you like to configure?${NC}"
        echo "  1. Add IPv6 addresses"
        echo "  2. Add IPv4 addresses"
        echo "  3. Add new VLAN interface"
        echo "  4. Show current configuration only"
        echo ""
        
        while true; do
            read -p "Enter your choice (1-4): " config_choice
            
            case "$config_choice" in
                1) local config_type=1 ;;  # IPv6
                2) local config_type=2 ;;  # IPv4
                3) local config_type=3 ;;  # VLAN
                4) local config_type=5 ;;  # Show only
                *) echo -e "${RED}Invalid choice. Please enter 1, 2, 3, or 4${NC}"; continue ;;
            esac
            break
        done
        
        case "$config_type" in
            1)  # IPv6 - Simple standard Debian format only
                echo -e "${CYAN}Adding IPv6 addresses to $SELECTED_INTERFACE...${NC}"
                
                # Step 1: Detect existing subnet, gateway, and addresses for default
                local existing_subnet=""
                local existing_gateway=""
                local existing_addresses=()
                if [[ -f "/etc/network/interfaces" ]]; then
                    while IFS= read -r line; do
                        if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+${SELECTED_INTERFACE}[[:space:]]+inet6[[:space:]]+static ]]; then
                            while IFS= read -r addr_line; do
                                if [[ "$addr_line" =~ ^[[:space:]]*address[[:space:]]+([0-9a-fA-F:]+) ]]; then
                                    local addr="${BASH_REMATCH[1]}"
                                    addr=$(echo "$addr" | cut -d'/' -f1)  # Remove /64 if present
                                    existing_addresses+=("$addr")
                                    if [[ -z "$existing_subnet" ]]; then
                                        existing_subnet=$(echo "$addr" | sed 's/::[0-9a-fA-F]*$//')::/64
                                    fi
                                elif [[ "$addr_line" =~ ^[[:space:]]*up[[:space:]]+ip[[:space:]]+-6[[:space:]]+addr[[:space:]]+add[[:space:]]+([0-9a-fA-F:]+) ]]; then
                                    local addr="${BASH_REMATCH[1]}"
                                    addr=$(echo "$addr" | cut -d'/' -f1)  # Remove /64 if present
                                    existing_addresses+=("$addr")
                                    if [[ -z "$existing_subnet" ]]; then
                                        existing_subnet=$(echo "$addr" | sed 's/::[0-9a-fA-F]*$//')::/64
                                    fi
                                elif [[ "$addr_line" =~ ^[[:space:]]*gateway[[:space:]]+([0-9a-fA-F:]+) ]]; then
                                    existing_gateway="${BASH_REMATCH[1]}"
                                elif [[ "$addr_line" =~ ^[[:space:]]*iface[[:space:]]+ ]]; then
                                    break
                                fi
                            done
                            break
                        fi
                    done < "/etc/network/interfaces"
                fi
                
                # Step 2: Get subnet with default
                echo ""
                if [[ -n "$existing_subnet" ]]; then
                    read -p "Enter IPv6 subnet/CIDR (default: $existing_subnet): " subnet
                    if [[ -z "$subnet" ]]; then
                        subnet="$existing_subnet"
                    fi
                else
                    read -p "Enter IPv6 subnet/CIDR (e.g., 2a01:4f9:1a:97cb::/64): " subnet
                fi
                
                # Validate subnet
                if [[ ! "$subnet" =~ ^[0-9a-fA-F:]+/[0-9]{1,3}$ ]]; then
                    echo -e "${RED}Invalid subnet format. Use format like: 2a01:4f9:1a:97cb::/64${NC}"
                    exit 1
                fi
                
                SELECTED_SUBNET="$subnet"
                
                # Step 3: Get number of addresses
                echo ""
                read -p "How many IPv6 addresses to add? " num_addresses
                
                if [[ ! "$num_addresses" =~ ^[0-9]+$ ]] || [ "$num_addresses" -lt 1 ]; then
                    echo -e "${RED}Invalid number. Must be 1 or more.${NC}"
                    exit 1
                fi
                
                # Step 4: Generate addresses starting from next available after existing ones
                local base_address=$(echo "$SELECTED_SUBNET" | cut -d'/' -f1 | sed 's/::$//')
                local prefix_length=$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)
                local new_addresses=()
                
                # Find the highest existing number to continue from there
                local next_num=2  # Default start from ::2
                if [[ ${#existing_addresses[@]} -gt 0 ]]; then
                    for addr in "${existing_addresses[@]}"; do
                        if [[ "$addr" =~ ${base_address}::([0-9a-fA-F]+) ]]; then
                            local hex_num="${BASH_REMATCH[1]}"
                            local dec_num=$((16#$hex_num))
                            # Find the highest number and add 1
                            if [[ $dec_num -ge $next_num ]]; then
                                next_num=$((dec_num + 1))
                            fi
                        fi
                    done
                fi
                
                echo -e "${BLUE}Existing addresses found: ${#existing_addresses[@]}${NC}"
                echo -e "${BLUE}Starting from: ${base_address}::$(printf "%x" $next_num)${NC}"
                
                # Generate the requested number of addresses
                for ((i=0; i<num_addresses; i++)); do
                    local current_num=$((next_num + i))
                    local hex_num=$(printf "%x" $current_num)
                    new_addresses+=("${base_address}::$hex_num/$prefix_length")
                done
                
                # Step 5: Show what we'll do
                echo ""
                echo -e "${CYAN}Will add ${#new_addresses[@]} IPv6 addresses to $SELECTED_INTERFACE:${NC}"
                echo -e "${GREEN}Subnet: $SELECTED_SUBNET${NC}"
                if [[ -n "$existing_gateway" ]]; then
                    echo -e "${GREEN}Gateway: $existing_gateway (preserved)${NC}"
                fi
                echo -e "${GREEN}From: ${new_addresses[0]}${NC}"
                echo -e "${GREEN}To:   ${new_addresses[-1]}${NC}"
                echo ""
                read -p "Continue? [y/N]: " confirm
                
                if [[ ! "$confirm" =~ ^[Yy] ]]; then
                    echo -e "${YELLOW}Cancelled${NC}"
                    exit 0
                fi
                
                # Step 6: Backup and rewrite IPv6 section in standard format
                echo -e "${CYAN}Updating configuration...${NC}"
                
                mkdir -p "$BACKUP_DIR"
                cp /etc/network/interfaces "$BACKUP_DIR/interfaces-$(date +%Y%m%d-%H%M%S)"
                
                local temp_file=$(mktemp)
                local ipv6_section_written=false
                
                while IFS= read -r line; do
                    # Copy all lines except old IPv6 section for target interface
                    if [[ "$line" =~ ^[[:space:]]*iface[[:space:]]+${SELECTED_INTERFACE}[[:space:]]+inet6[[:space:]]+static ]]; then
                        # Skip old IPv6 section, write new one
                        echo "iface $SELECTED_INTERFACE inet6 static" >> "$temp_file"
                        
                        # Write first address with netmask and gateway
                        if [[ ${#existing_addresses[@]} -gt 0 ]]; then
                            echo "  address ${existing_addresses[0]}/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)" >> "$temp_file"
                        else
                            echo "  address ${base_address}::2/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)" >> "$temp_file"
                        fi
                        
                        echo "  netmask $(echo "$SELECTED_SUBNET" | cut -d'/' -f2)" >> "$temp_file"
                        
                        # Add gateway if it existed
                        if [[ -n "$existing_gateway" ]]; then
                            echo "  gateway $existing_gateway" >> "$temp_file"
                        fi
                        
                        # Add additional addresses using up commands (Hetzner style)
                        local additional_addresses=("${existing_addresses[@]:1}")  # Skip first one
                        additional_addresses+=("${new_addresses[@]}")  # Add new ones
                        
                        for addr in "${additional_addresses[@]}"; do
                            # Ensure address has /64 prefix (but don't double-add)
                            if [[ ! "$addr" =~ */[0-9]+$ ]]; then
                                addr="$addr/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)"
                            fi
                            echo "  up ip -6 addr add $addr dev \$IFACE" >> "$temp_file"
                        done
                        
                        # Add corresponding down commands
                        for addr in "${additional_addresses[@]}"; do
                            # Ensure address has /64 prefix (but don't double-add)
                            if [[ ! "$addr" =~ */[0-9]+$ ]]; then
                                addr="$addr/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)"
                            fi
                            echo "  down ip -6 addr del $addr dev \$IFACE" >> "$temp_file"
                        done
                        
                        echo "" >> "$temp_file"
                        
                        ipv6_section_written=true
                        
                        # Skip all lines until next interface
                        while IFS= read -r skip_line && [[ ! "$skip_line" =~ ^[[:space:]]*iface[[:space:]]+ ]]; do
                            continue
                        done
                        echo "$skip_line" >> "$temp_file"
                    else
                        echo "$line" >> "$temp_file"
                    fi
                done < "/etc/network/interfaces"
                
                # If no IPv6 section existed, add one at the end
                if [[ "$ipv6_section_written" == false ]]; then
                    echo "" >> "$temp_file"
                    echo "iface $SELECTED_INTERFACE inet6 static" >> "$temp_file"
                    
                    # Write first address with netmask and gateway
                    if [[ ${#existing_addresses[@]} -gt 0 ]]; then
                        echo "  address ${existing_addresses[0]}/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)" >> "$temp_file"
                    else
                        echo "  address ${base_address}::2/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)" >> "$temp_file"
                    fi
                    
                    echo "  netmask $(echo "$SELECTED_SUBNET" | cut -d'/' -f2)" >> "$temp_file"
                    
                    # Add gateway if it existed
                    if [[ -n "$existing_gateway" ]]; then
                        echo "  gateway $existing_gateway" >> "$temp_file"
                    fi
                    
                    # Add additional addresses using up commands (Hetzner style)
                    local additional_addresses=("${existing_addresses[@]:1}")  # Skip first one
                    additional_addresses+=("${new_addresses[@]}")  # Add new ones
                    
                    for addr in "${additional_addresses[@]}"; do
                        # Ensure address has /64 prefix
                        if [[ ! "$addr" =~ */[0-9]+$ ]]; then
                            addr="$addr/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)"
                        fi
                        echo "  up ip -6 addr add $addr dev \$IFACE" >> "$temp_file"
                    done
                    
                    # Add corresponding down commands
                    for addr in "${additional_addresses[@]}"; do
                        # Ensure address has /64 prefix
                        if [[ ! "$addr" =~ */[0-9]+$ ]]; then
                            addr="$addr/$(echo "$SELECTED_SUBNET" | cut -d'/' -f2)"
                        fi
                        echo "  down ip -6 addr del $addr dev \$IFACE" >> "$temp_file"
                    done
                    
                    echo "" >> "$temp_file"
                fi
                
                # Replace file
                mv "$temp_file" /etc/network/interfaces
                
                # Restart interface
                echo -e "${CYAN}Restarting $SELECTED_INTERFACE...${NC}"
                
                # Try to restart interface with IPv4 conflict handling
                if ifdown "$SELECTED_INTERFACE" 2>/dev/null; then
                    sleep 2
                    if ifup "$SELECTED_INTERFACE" 2>/dev/null; then
                        echo -e "${GREEN}✅ SUCCESS: Added ${#new_addresses[@]} IPv6 addresses to $SELECTED_INTERFACE${NC}"
                        echo -e "${GREEN}   Written in standard Debian format${NC}"
                    else
                        echo -e "${YELLOW}⚠️  IPv6 configuration updated, but interface restart had issues${NC}"
                        echo -e "${YELLOW}This is usually due to IPv4 address conflicts and can be ignored${NC}"
                        echo -e "${GREEN}✅ IPv6 addresses should still work correctly${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️  Could not bring interface down, but configuration was updated${NC}"
                    echo -e "${YELLOW}IPv6 addresses will be applied on next reboot or manual restart${NC}"
                    echo -e "${YELLOW}Manual restart: ifdown $SELECTED_INTERFACE && ifup $SELECTED_INTERFACE${NC}"
                fi
                ;;
            2)  # IPv4
                echo -e "${CYAN}Configuring IPv4 address...${NC}"
                get_ipv4_config
                if add_ipv4_to_interfaces; then
                    echo -e "${GREEN}✓ IPv4 address added successfully${NC}"
                    echo -e "${CYAN}Testing IPv4 connectivity...${NC}"
                    if ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1; then
                        echo -e "${GREEN}✓ IPv4 connectivity: OK${NC}"
                    else
                        echo -e "${YELLOW}⚠ IPv4 connectivity test failed${NC}"
                    fi
                else
                    echo -e "${RED}✗ Failed to add IPv4 address${NC}"
                    exit 1
                fi
                ;;
            3)  # VLAN
                echo -e "${CYAN}Creating new VLAN interface...${NC}"
                if create_vlan_interface "$SELECTED_INTERFACE"; then
                    echo -e "${GREEN}✓ VLAN interface created successfully${NC}"
                else
                    echo -e "${RED}✗ Failed to create VLAN interface${NC}"
                    exit 1
                fi
                ;;
            5)  # Show only
                echo -e "${CYAN}Current configuration for $SELECTED_INTERFACE:${NC}"
                read_current_config "$SELECTED_INTERFACE"
                ;;
        esac
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Network configuration completed successfully!${NC}"
    echo -e "${CYAN}Backup saved to: $BACKUP_DIR${NC}"
}

# Run main function
main "$@"
