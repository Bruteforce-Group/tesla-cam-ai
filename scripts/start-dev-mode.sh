#!/bin/bash
# Start Tesla Cam AI in development mode with dummy feeds

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Tesla Camera AI - Development Mode               ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running on Pi
if [[ "$HOSTNAME" != *"boz-pi"* ]]; then
    echo -e "${YELLOW}Not on Pi - connecting via SSH...${NC}"
    REMOTE_CMD="ssh danielborrowman@192.168.222.60"
else
    REMOTE_CMD=""
fi

echo -e "${GREEN}Development Mode Options:${NC}"
echo "1) Single event (person approaching)"
echo "2) Single event (custom scenario)"
echo "3) Continuous feed (generates events every minute)"
echo "4) Test suite (all scenarios)"
echo "5) Stress test (10 random events)"
echo "6) List all scenarios"
echo ""
read -p "Select mode (1-6): " MODE

case $MODE in
    1)
        echo -e "${YELLOW}Generating person approaching scenario...${NC}"
        $REMOTE_CMD "cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode single --scenario person_approaching"
        ;;
    2)
        echo "Available scenarios:"
        $REMOTE_CMD "cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --list-scenarios"
        read -p "Enter scenario name: " SCENARIO
        $REMOTE_CMD "cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode single --scenario $SCENARIO"
        ;;
    3)
        read -p "Interval between events (seconds, default 60): " INTERVAL
        INTERVAL=${INTERVAL:-60}
        echo -e "${YELLOW}Starting continuous feed (Ctrl+C to stop)...${NC}"
        $REMOTE_CMD "cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode continuous --interval $INTERVAL"
        ;;
    4)
        echo -e "${YELLOW}Generating complete test suite...${NC}"
        $REMOTE_CMD "cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode test-suite"
        ;;
    5)
        read -p "Number of events (default 10): " COUNT
        COUNT=${COUNT:-10}
        echo -e "${YELLOW}Generating $COUNT random events...${NC}"
        $REMOTE_CMD "cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --mode stress --count $COUNT"
        ;;
    6)
        $REMOTE_CMD "cd /opt/tesla-cam-ai && source venv/bin/activate && python rpi5/dev_mode.py --list-scenarios"
        ;;
    *)
        echo "Invalid selection"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}✅ Development mode execution complete!${NC}"
echo ""
echo "Check the results:"
echo "  Watch logs: ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log'"
echo "  List files: ssh danielborrowman@192.168.222.60 'ls -lh /mnt/tesla-cam/TeslaSentry/'"
echo ""
