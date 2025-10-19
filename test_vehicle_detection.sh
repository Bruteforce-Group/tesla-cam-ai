#!/bin/bash
echo "🚗 Testing Vehicle Detection Pipeline"
echo "================================="
echo ""
echo "Starting log monitor..."
ssh danielborrowman@192.168.222.60 'tail -f /var/log/tesla-cam-ai/main.log' &
TAIL_PID=$!

sleep 2

echo ""
echo "Generating new vehicle test..."
ssh danielborrowman@192.168.222.60 'cd /opt/tesla-cam-ai && source venv/bin/activate && timeout 60 python rpi5/dev_mode_vehicle_test.py --mode custom --plate "XYZ-999" --make "BMW" --model "X5" --color "Blue"'

echo ""
echo "Waiting for detection (10 seconds)..."
sleep 10

kill $TAIL_PID 2>/dev/null

echo ""
echo "✅ Test complete! Checking final logs..."
ssh danielborrowman@192.168.222.60 'tail -30 /var/log/tesla-cam-ai/main.log | grep -E "(Queued|Processing|Upload|13:3[2-4])"'
