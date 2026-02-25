#!/usr/bin/env bash
#
# Input Counter - Track mouse clicks and keyboard key presses
# Monitors input activity throughout the day with real-time statistics
#

set -euo pipefail

# Configuration
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/input-counter"
readonly LOG_FILE="$DATA_DIR/$(date +%Y-%m-%d).log"
readonly PID_FILE="$DATA_DIR/input-counter.pid"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Initialize data directory
init_data_dir() {
    mkdir -p "$DATA_DIR"
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "timestamp,clicks,keys" > "$LOG_FILE"
    fi
}

# Find input devices
get_mouse_id() {
    xinput list | grep -i 'mouse\|pointer' | grep -v 'Virtual' | head -n1 | grep -oP 'id=\K\d+'
}

get_keyboard_id() {
    xinput list | grep -i 'keyboard' | grep -v 'Virtual' | head -n1 | grep -oP 'id=\K\d+'
}

# Start monitoring
start_monitor() {
    if is_running; then
        echo -e "${YELLOW}Input counter is already running (PID: $(cat "$PID_FILE"))${NC}"
        return 0
    fi

    init_data_dir

    local mouse_id keyboard_id
    mouse_id=$(get_mouse_id)
    keyboard_id=$(get_keyboard_id)

    if [[ -z "$mouse_id" || -z "$keyboard_id" ]]; then
        echo -e "${RED}Error: Could not find input devices${NC}"
        echo "Available devices:"
        xinput list
        return 1
    fi

    echo -e "${GREEN}Starting input counter...${NC}"
    echo -e "Mouse device ID: ${CYAN}$mouse_id${NC}"
    echo -e "Keyboard device ID: ${CYAN}$keyboard_id${NC}"
    echo -e "Log file: ${CYAN}$LOG_FILE${NC}"

    # Start background monitoring process
    nohup bash -c "
        trap 'exit 0' SIGTERM SIGINT

        clicks=0
        keys=0
        last_save=\$(date +%s)

        # Monitor both devices simultaneously
        xinput test $mouse_id & mouse_pid=\$!
        xinput test $keyboard_id & kbd_pid=\$!

        # Process input from both devices
        while true; do
            # Read mouse events
            if read -t 0.1 line <&\$mouse_pid 2>/dev/null; then
                if echo \"\$line\" | grep -q 'button press'; then
                    ((clicks++))
                fi
            fi

            # Read keyboard events
            if read -t 0.1 line <&\$kbd_pid 2>/dev/null; then
                if echo \"\$line\" | grep -q 'key press'; then
                    ((keys++))
                fi
            fi

            # Save every 60 seconds
            now=\$(date +%s)
            if (( now - last_save >= 60 )); then
                timestamp=\$(date '+%Y-%m-%d %H:%M:%S')
                echo \"\$timestamp,\$clicks,\$keys\" >> '$LOG_FILE'
                last_save=\$now
            fi

            sleep 0.01
        done
    " > /dev/null 2>&1 &

    echo $! > "$PID_FILE"
    echo -e "${GREEN}✓ Input counter started (PID: $!)${NC}"
    echo "Use 'input-counter status' to view statistics"
}

# Stop monitoring
stop_monitor() {
    if ! is_running; then
        echo -e "${YELLOW}Input counter is not running${NC}"
        return 0
    fi

    local pid
    pid=$(cat "$PID_FILE")

    echo -e "${YELLOW}Stopping input counter (PID: $pid)...${NC}"
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"

    echo -e "${GREEN}✓ Input counter stopped${NC}"
}

# Check if running
is_running() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
}

# Show current status and statistics
show_status() {
    if is_running; then
        echo -e "${GREEN}● Input counter is running${NC} (PID: $(cat "$PID_FILE"))"
    else
        echo -e "${RED}● Input counter is not running${NC}"
    fi
    echo

    if [[ ! -f "$LOG_FILE" ]] || [[ $(wc -l < "$LOG_FILE") -le 1 ]]; then
        echo -e "${YELLOW}No data collected yet${NC}"
        return 0
    fi

    echo -e "${BLUE}═══ Today's Statistics ═══${NC}"
    echo

    # Calculate totals
    local total_clicks total_keys
    total_clicks=$(awk -F, 'NR>1 {sum+=$2} END {print sum+0}' "$LOG_FILE")
    total_keys=$(awk -F, 'NR>1 {sum+=$3} END {print sum+0}' "$LOG_FILE")

    echo -e "Total clicks: ${CYAN}$total_clicks${NC}"
    echo -e "Total keys: ${CYAN}$total_keys${NC}"
    echo -e "Total inputs: ${CYAN}$((total_clicks + total_keys))${NC}"
    echo

    # Calculate averages per hour
    local hours_active
    hours_active=$(awk -F, 'NR>1' "$LOG_FILE" | wc -l)
    hours_active=$((hours_active / 60))

    if [[ $hours_active -gt 0 ]]; then
        echo -e "Average per hour:"
        echo -e "  Clicks: ${CYAN}$((total_clicks / hours_active))${NC}"
        echo -e "  Keys: ${CYAN}$((total_keys / hours_active))${NC}"
        echo
    fi

    # Show last 5 entries
    echo -e "${BLUE}Recent activity:${NC}"
    awk -F, 'NR>1 {print "  " $1 " - Clicks: " $2 ", Keys: " $3}' "$LOG_FILE" | tail -n 5
}

# Show detailed report
show_report() {
    local date_filter="${1:-$(date +%Y-%m-%d)}"
    local report_file="$DATA_DIR/$date_filter.log"

    if [[ ! -f "$report_file" ]]; then
        echo -e "${RED}No data found for $date_filter${NC}"
        return 1
    fi

    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo -e "${BLUE}   Input Counter Report${NC}"
    echo -e "${BLUE}   Date: $date_filter${NC}"
    echo -e "${BLUE}═══════════════════════════════════${NC}"
    echo

    # Total statistics
    local total_clicks total_keys total_inputs
    total_clicks=$(awk -F, 'NR>1 {sum+=$2} END {print sum+0}' "$report_file")
    total_keys=$(awk -F, 'NR>1 {sum+=$3} END {print sum+0}' "$report_file")
    total_inputs=$((total_clicks + total_keys))

    echo -e "${CYAN}📊 Total Statistics:${NC}"
    echo -e "   Mouse clicks: ${GREEN}$total_clicks${NC}"
    echo -e "   Key presses:  ${GREEN}$total_keys${NC}"
    echo -e "   Total inputs: ${GREEN}$total_inputs${NC}"
    echo

    # Hourly breakdown
    echo -e "${CYAN}⏰ Hourly Breakdown:${NC}"
    awk -F'[, :]' 'NR>1 {
        hour=$2":"$3
        clicks[hour]+=$5
        keys[hour]+=$6
    }
    END {
        for (hour in clicks) {
            printf "   %s - Clicks: %d, Keys: %d, Total: %d\n",
                hour, clicks[hour], keys[hour], clicks[hour]+keys[hour]
        }
    }' "$report_file" | sort
    echo

    # Activity periods
    echo -e "${CYAN}🕒 Activity Summary:${NC}"
    local first_entry last_entry duration
    first_entry=$(awk -F, 'NR==2 {print $1}' "$report_file")
    last_entry=$(awk -F, 'END {print $1}' "$report_file")

    if [[ -n "$first_entry" && -n "$last_entry" ]]; then
        echo -e "   First activity: ${GREEN}$first_entry${NC}"
        echo -e "   Last activity:  ${GREEN}$last_entry${NC}"
    fi
}

# List available logs
list_logs() {
    echo -e "${BLUE}Available logs:${NC}"
    echo

    for log in "$DATA_DIR"/*.log; do
        if [[ -f "$log" ]]; then
            local date filename total_clicks total_keys
            filename=$(basename "$log")
            date="${filename%.log}"
            total_clicks=$(awk -F, 'NR>1 {sum+=$2} END {print sum+0}' "$log")
            total_keys=$(awk -F, 'NR>1 {sum+=$3} END {print sum+0}' "$log")

            echo -e "  ${CYAN}$date${NC}"
            echo -e "    Clicks: $total_clicks, Keys: $total_keys"
        fi
    done
}

# Usage information
show_usage() {
    cat << EOF
${GREEN}Input Counter${NC} - Track mouse clicks and keyboard key presses

${YELLOW}Usage:${NC}
  input-counter start          Start monitoring input
  input-counter stop           Stop monitoring
  input-counter restart        Restart monitoring
  input-counter status         Show current status and today's stats
  input-counter report [DATE]  Show detailed report (default: today)
  input-counter list           List all available logs
  input-counter help           Show this help message

${YELLOW}Examples:${NC}
  input-counter start          # Start monitoring
  input-counter status         # Check status and stats
  input-counter report         # Today's detailed report
  input-counter report 2026-01-04  # Specific date report

${YELLOW}Log location:${NC}
  $DATA_DIR

EOF
}

# Main command dispatcher
main() {
    local command="${1:-help}"

    case "$command" in
        start)
            start_monitor
            ;;
        stop)
            stop_monitor
            ;;
        restart)
            stop_monitor
            sleep 1
            start_monitor
            ;;
        status)
            show_status
            ;;
        report)
            show_report "${2:-}"
            ;;
        list)
            list_logs
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$command'${NC}"
            echo
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
