#!/bin/bash

source .env

FLOW=e2e
ARGS=()
DEVICE_ID=""

# Extract the flow flag to allow running only one suite of test and passthrough the rest of the arguments.
while [[ $# -gt 0 ]]; do
  case "$1" in
    --flow)
      FLOW="$2"
      shift
      ;;
    --device)
      DEVICE_ID="$2"
      shift
      ;;
    *)
      ARGS+=("$1")
      ;;
  esac
  shift
done

# Check if we're running a transaction test
if [[ $FLOW == *"transaction"* ]]; then
  echo "Transaction test detected."
  
  # Kill any existing Anvil process
  echo "Cleaning up any existing Anvil processes..."
  ANVIL_PID=$(lsof -t -i:8545 -c anvil 2>/dev/null)
  if [ -n "$ANVIL_PID" ]; then
    kill $ANVIL_PID
  fi
  sleep 1
  
  # Start Anvil in the background
  echo "Starting Anvil..."
  yarn anvil --host 0.0.0.0 &
  
  echo "Waiting 5 seconds for Anvil to start..."
  sleep 5
fi

echo "Running on iOS platform"

# Run the Maestro test, explicitly targeting iOS with the right device
if [ -n "$DEVICE_ID" ]; then
  echo "Using specific iOS device: $DEVICE_ID"
  maestro --device "$DEVICE_ID" -p iOS test -e DEV_PKEY="$DEV_PKEY" -e APP_ID="me.rainbow" "${ARGS[@]}" "$FLOW"
else
  # If no specific device, just use iOS platform
  echo "No specific device specified, using default iOS device"
  maestro -p iOS test -e DEV_PKEY="$DEV_PKEY" -e APP_ID="me.rainbow" "${ARGS[@]}" "$FLOW"
fi

# Store the exit code
EXIT_CODE=$?

# Clean up
ANVIL_PID=$(lsof -t -i:8545 -c anvil 2>/dev/null)
if [ -n "$ANVIL_PID" ]; then
  kill $ANVIL_PID
fi

# Exit with the test exit code
exit $EXIT_CODE