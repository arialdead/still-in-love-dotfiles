#!/bin/env bash
#----- Optimized bars animation without much CPU usage increase --------
#----- Optimized bars animation without much CPU usage increase pt2 --------

# Default values
scrDir="$(dirname "$(realpath "$0")")"
# shellcheck disable=SC1091
source "${scrDir}/globalcontrol.sh"

usage() {
    cat <<HELP
Usage: $(basename "$0") [OPTIONS]
Options:
  --bar <waybar_cava_bar>  Specify the characters to use for the bar animation (default: ▁▂▃▄▅▆▇█).
  --width <waybar_cava_width>   Specify the width of the bar.
  --range <waybar_cava_range>   Specify the range of the bar.
  --help                        Display this help message and exit.
  --restart                     Restart the waybar_cava.
  --stb <waybar_cava_stbmode>  Specify the standby mode for waybar cava (default: 0).
                                0: clean  - totally hides the module
                                1: blank  - makes module expand as spaces
                                2: full   - occupies the module with full bar
                                3: low    - makes the module display the lowest set bar
                                *: string - displays a string
HELP
    exit 1
}

# Parse command line arguments using getopt
if ! ARGS=$(getopt -o "hr" -l "help,bar:,width:,range:,restart,stb:" -n "$0" -- "$@"); then
    usage
fi

eval set -- "$ARGS"
while true; do
    case "$1" in
    --help | -h)
        usage
        ;;
    --bar)
        waybar_cava_bar="$2"
        shift 2
        ;;
    --width)
        waybar_cava_width="$2"
        shift 2
        ;;
    --range)
        waybar_cava_range="$2"
        shift 2
        ;;
    --restart) # restart by killing all waybar_cava
        pkill -f "cava -p /tmp/bar_cava_config"
        exit 0
        ;;
    --stb)
        waybar_cava_stbmode="$2"
        shift 2
        ;;
    --)
        shift
        break
        ;;
    *)
        usage
        ;;
    esac
done

bar="${waybar_cava_bar:-▁▂▃▄▅▆▇█}"
#bar="${waybar_cava_bar:-⠀⠤⠶⠿}"

# // waybar_cava_stbmode - standby mode for waybar cava - default 0
# 0: clean - totally hides the module
# 1: blank - makes module expand as spaces
# 2: full - occupies the module with full bar
# 3: low - makes the module display the lowest set bar
# <string>: - displays a string
case ${waybar_cava_stbmode:-} in
0)
    stbBar=''
    ;; # Clean
1)
    stbBar="‎ "
    ;; # Invisible char
2)
    stbBar="${bar: -1}"
    ;; # Full bar
3)
    stbBar="${bar:0:1}"
    ;; # Lowest bar
*)
    asciiBar="${waybar_cava_stbmode:-${bar}}"
    ;; 
esac

# Calculate the length of the bar outside the loop
bar_length=${#bar}
bar_width=${waybar_cava_width:-${bar_length}}
bar_range=${waybar_cava_range:-$((bar_length - 1))}
# Create dictionary to replace char with bar
dict="s/;//g"
stbAscii=$(printf '0%.0s' $(seq 1 "${bar_width}")) # predicts the amount of ancii characters to be used
[ -n "${asciiBar}" ] || asciiBar="${stbAscii//0/${stbBar}}"

dict="$dict;s/${stbAscii}/${asciiBar}/g"
i=0
while [ $i -lt "${bar_length}" ] || [ $i -lt "${bar_width}" ]; do
    if [ $i -lt "${bar_length}" ]; then
        dict="$dict;s/$i/${bar:$i:1}/g"
    fi
    ((i++))
done

# Create cava config
config_file="/tmp/bar_cava_config"
cat >"$config_file" <<EOF


[general]
bars = ${bar_width}
sleep_timer = 30
# Cava Audio Visualizer Configuration Template
# Optimized for smooth and responsive visualization

[general]
# Number of bars (20-200) - fewer bars = better performance
bars = 5
# Framerate (1-144) - higher = smoother but more CPU intensive
framerate = 60

[input]
# Audio input method: pulse, alsa, fifo, or portaudio
method = pulse
# Audio device (leave as default for auto-detection)
source = auto

[output]
# Output method: ncurses, terminal, raw, or circle
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = ${bar_range}
# Terminal color scheme
channels = mono
[smoothing]
# Noise reduction (0-100) - higher = smoother but less responsive
# 77 is default, 85 provides good balance for smooth visualization
noise_reduction = 0

# Monstercat smoothing (0 or 1) - adds smoothing between adjacent bars
monstercat = 0

# Wave effect (0 or 1) - creates wave-like motion across bars
waves = 0

# Gravity (0-200) - controls how fast bars fall
# 100 = normal gravity, 150 = faster fall, 50 = slower fall
gravity = 200


EOF

cava -p "$config_file" | sed -u "${dict}"
