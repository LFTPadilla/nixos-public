#!/usr/bin/env bash
#
# Daily Input Counter Report Generator
# Generates comprehensive reports for the previous day's activity
#

set -euo pipefail

# Configuration
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/input-counter"
readonly REPORT_DIR="$DATA_DIR/reports"
readonly YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
readonly LOG_FILE="$DATA_DIR/$YESTERDAY.log"
readonly REPORT_FILE="$REPORT_DIR/$YESTERDAY-report.txt"

# Colors
readonly BOLD='\033[1m'
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[1;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

# Initialize report directory
mkdir -p "$REPORT_DIR"

# Generate report
generate_report() {
    if [[ ! -f "$LOG_FILE" ]]; then
        echo -e "${RED}No data found for $YESTERDAY${NC}"
        echo "Log file expected: $LOG_FILE"
        exit 1
    fi

    local lines
    lines=$(wc -l < "$LOG_FILE")
    if [[ $lines -le 1 ]]; then
        echo -e "${YELLOW}No activity data for $YESTERDAY${NC}"
        exit 0
    fi

    echo -e "${GREEN}Generating report for $YESTERDAY...${NC}"

    # Create report
    {
        echo "═══════════════════════════════════════════════════════════"
        echo "              INPUT ACTIVITY REPORT"
        echo "              Date: $YESTERDAY"
        echo "              Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "═══════════════════════════════════════════════════════════"
        echo
        echo "📊 SUMMARY STATISTICS"
        echo "─────────────────────────────────────────────────────────"

        # Calculate totals
        awk -F, 'NR>1 {
            clicks+=$2
            keys+=$3
            count++
        }
        END {
            total=clicks+keys
            printf "  Total Mouse Clicks:    %'"'"'d\n", clicks
            printf "  Total Key Presses:     %'"'"'d\n", keys
            printf "  Total Inputs:          %'"'"'d\n", total
            printf "  Data Points Collected: %d\n", count
            printf "  Average Clicks/Min:    %.1f\n", clicks/count
            printf "  Average Keys/Min:      %.1f\n", keys/count
            printf "  Average Inputs/Min:    %.1f\n", total/count
        }' "$LOG_FILE"

        echo
        echo "⏰ HOURLY BREAKDOWN"
        echo "─────────────────────────────────────────────────────────"
        echo "  Hour    Clicks    Keys    Total   Activity"
        echo "  ────────────────────────────────────────────────────"

        awk -F'[, :]' 'NR>1 {
            hour=$2
            clicks[hour]+=$5
            keys[hour]+=$6
        }
        END {
            for (h=0; h<24; h++) {
                hour=sprintf("%02d", h)
                c=clicks[hour]+0
                k=keys[hour]+0
                t=c+k
                if (t>0) {
                    # Activity bar
                    bar_length=int(t/100)
                    if (bar_length>50) bar_length=50
                    bar=""
                    for(i=0; i<bar_length; i++) bar=bar"█"

                    printf "  %s:00  %6d  %6d  %6d  %s\n", hour, c, k, t, bar
                }
            }
        }' "$LOG_FILE"

        echo
        echo "📈 ACTIVITY PATTERNS"
        echo "─────────────────────────────────────────────────────────"

        # Peak hours
        echo "  Peak Activity Hours:"
        awk -F'[, :]' 'NR>1 {
            hour=$2
            clicks[hour]+=$5
            keys[hour]+=$6
        }
        END {
            # Find top 3 hours
            for (h=0; h<24; h++) {
                hour=sprintf("%02d", h)
                total[hour]=clicks[hour]+keys[hour]
            }

            # Simple sort - find top 3
            for (rank=1; rank<=3; rank++) {
                max=0
                max_hour=""
                for (h=0; h<24; h++) {
                    hour=sprintf("%02d", h)
                    if (total[hour]>max) {
                        max=total[hour]
                        max_hour=hour
                    }
                }
                if (max>0) {
                    printf "    #%d: %s:00 - %d inputs\n", rank, max_hour, max
                    total[max_hour]=0
                }
            }
        }' "$LOG_FILE"

        echo
        echo "  Activity Distribution:"
        awk -F, 'NR>1 {
            clicks+=$2
            keys+=$3
        }
        END {
            total=clicks+keys
            click_pct=clicks/total*100
            key_pct=keys/total*100
            printf "    Mouse Clicks: %.1f%%\n", click_pct
            printf "    Key Presses:  %.1f%%\n", key_pct
        }' "$LOG_FILE"

        echo
        echo "🕒 TIME ANALYSIS"
        echo "─────────────────────────────────────────────────────────"

        awk -F, 'NR==2 {first=$1} END {last=$1; print "  First Activity: " first "\n  Last Activity:  " last}' "$LOG_FILE"

        # Calculate active time
        awk -F'[, :]' 'NR>1 {
            clicks+=$5
            keys+=$6
            if ($5>0 || $6>0) active_minutes++
        }
        END {
            hours=int(active_minutes/60)
            mins=active_minutes%60
            printf "  Active Time:    %dh %dm\n", hours, mins
            if (active_minutes>0) {
                printf "  Avg Inputs/Min: %.1f\n", (clicks+keys)/active_minutes
            }
        }' "$LOG_FILE"

        echo
        echo "💡 INSIGHTS"
        echo "─────────────────────────────────────────────────────────"

        awk -F, 'NR>1 {
            clicks+=$2
            keys+=$3
            total=$2+$3
            if (total>max_inputs) {
                max_inputs=total
                max_time=$1
            }
            if (NR==2 || total<min_inputs) {
                min_inputs=total
            }
        }
        END {
            total=clicks+keys
            ratio=keys/clicks

            if (ratio>3) {
                printf "  • Heavy keyboard usage (%.1fx more keys than clicks)\n", ratio
                print  "    Suggests: Text-heavy work, coding, or writing"
            } else if (ratio<1) {
                printf "  • Mouse-intensive activity (%.1fx more clicks than keys)\n", 1/ratio
                print  "    Suggests: GUI work, browsing, or design tasks"
            } else {
                print  "  • Balanced input usage"
                print  "    Suggests: Mixed computer activities"
            }

            printf "  • Most active minute: %s (%d inputs)\n", max_time, max_inputs

            if (total>50000) {
                print  "  • Very high activity day (>50k inputs)"
            } else if (total>25000) {
                print  "  • High activity day (>25k inputs)"
            } else if (total>10000) {
                print  "  • Moderate activity day"
            } else {
                print  "  • Light activity day"
            }
        }' "$LOG_FILE"

        echo
        echo "═══════════════════════════════════════════════════════════"
        echo "Report saved to: $REPORT_FILE"
        echo "═══════════════════════════════════════════════════════════"

    } > "$REPORT_FILE"

    echo -e "${GREEN}✓ Report generated successfully${NC}"
    echo -e "Location: ${CYAN}$REPORT_FILE${NC}"
    echo

    # Display the report
    cat "$REPORT_FILE"
}

# Send notification
send_notification() {
    if command -v notify-send &>/dev/null; then
        local total_inputs
        total_inputs=$(awk -F, 'NR>1 {sum+=$2+$3} END {print sum+0}' "$LOG_FILE")

        notify-send "Input Counter Report" \
            "Daily report for $YESTERDAY generated\nTotal inputs: $total_inputs" \
            --icon=dialog-information \
            --urgency=low
    fi
}

# Main
main() {
    generate_report
    send_notification
}

main "$@"
