#!/bin/bash

# Configuration
# IMPORTANT: Adjust BROWSER_APP_NAME based on your browser's .app bundle name
# For Google Chrome: "Google Chrome"
# For Brave: "Brave Browser"
# For Microsoft Edge: "Microsoft Edge"
# For Chromium: "Chromium"
BROWSER_APP_NAME="Google Chrome" 

# BROWSER_EXECUTABLE is usually within the .app bundle
# Example: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
# BROWSER_EXECUTABLE="/Applications/${BROWSER_APP_NAME}.app/Contents/MacOS/${BROWSER_APP_NAME}"
BROWSER_EXECUTABLE = "Google Chrome Helper (Renderer).app/Contents/MacOS/Google Chrome Helper (Renderer)"

echo "Attempting to kill renderer (tab) processes for '$BROWSER_APP_NAME'..."

# Get PIDs and full command lines of all relevant processes
# ps auxww:
#   a: show processes for all users
#   u: display user-oriented format
#   x: show processes without controlling ttys
#   ww: wide output, do not truncate command line
# We grep for the browser's executable path, and exclude grep's own process.
PROCESS_INFO=$(ps auxww | grep "${BROWSER_EXECUTABLE}" | grep -v "grep")

if [ -z "$PROCESS_INFO" ]; then
    echo "No '$BROWSER_APP_NAME' processes found."
    exit 0
fi

# Initialize array for PIDs to kill
PIDS_TO_KILL=()
MAIN_BROWSER_PID=""

# Read process info line by line
while IFS= read -r line; do
    # Extract PID (2nd column in ps aux output)
    PID=$(echo "$line" | awk '{print $2}')
    
    # Check if it's the main browser process (contains --type=browser)
    if [[ "$line" =~ --type=browser ]]; then
        MAIN_BROWSER_PID="$PID"
        echo "Keeping main browser process (PID: $PID)"
        continue # Skip to the next line, don't add to kill list
    fi

    # Check if it's a renderer process (contains --type=renderer)
    if [[ "$line" =~ --type=renderer ]]; then
        echo "Identified renderer (tab) process to kill (PID: $PID)"
        PIDS_TO_KILL+=("$PID")
    fi

    # Optional: You might want to also kill --type=extension processes if they're eating resources
    # if [[ "$line" =~ --type=extension ]]; then
    #     echo "Identified extension process to kill (PID: $PID)"
    #     PIDS_TO_KILL+=("$PID")
    # fi

    # You could also consider specific utility processes that are *not* critical,
    # but be very careful here as many utilities are essential for browser function.
    # For example, if you see `--utility-sub-type=media.mojom.MediaService` is high,
    # you might target it if you know it's safe to kill for your use case.
    # else if [[ "$line" =~ --type=utility && "$line" =~ --utility-sub-type=SOME_SPECIFIC_UTILITY ]]; then
    #    echo "Identified specific utility process to kill (PID: $PID)"
    #    PIDS_TO_KILL+=("$PID")
    # fi

done <<< "$PROCESS_INFO" # Feed PROCESS_INFO into the while loop

if [ ${#PIDS_TO_KILL[@]} -eq 0 ]; then
    echo "No '$BROWSER_APP_NAME' renderer (tab) processes found to kill."
else
    echo "Identified PIDs to kill: ${PIDS_TO_KILL[*]}"
    read -p "Are you sure you want to kill these renderer processes? (y/N): " -n 1 -r
    echo # (optional) move to a new line
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Killing processes..."
        # Try graceful termination first (SIGTERM)
        kill -TERM "${PIDS_TO_KILL[@]}" 2>/dev/null
        
        # Give a moment for graceful shutdown
        sleep 2
        
        # Check if any processes are still running and force kill (SIGKILL)
        STILL_RUNNING_PIDS=()
        for PID in "${PIDS_TO_KILL[@]}"; do
            if ps -p $PID > /dev/null; then
                STILL_RUNNING_PIDS+=("$PID")
            fi
        done
        
        if [ ${#STILL_RUNNING_PIDS[@]} -ne 0 ]; then
            echo "Some processes did not terminate gracefully. Force killing: ${STILL_RUNNING_PIDS[*]}"
            kill -KILL "${STILL_RUNNING_PIDS[@]}" 2>/dev/null
        fi
        
        echo "'$BROWSER_APP_NAME' renderer process cleanup complete. You may see 'Aw, Snap!' pages, which can be reloaded."
    else
        echo "Operation cancelled."
    fi
fi

exit 0
