#!/bin/zsh

scriptDir=${0:A:h}
savedFile="$scriptDir/python_target_file.txt"

setCommand() { # $1:directory, $2:query, $3:option
	local savedData=("${(@f)$(<"$savedFile")}") # split on newlines
	newData=""
	isExists=0
	file="./main.py" # Default
	for line in $savedData; do
		local array=("${(@s/:/)line}")
		local flag=0
		if [[ -n "$3" && "$3" == "--clean" ]]; then
			isExists=1 # To rewrite data
			if [[ "${array[1]::1}" != "#" && ! -d "$array[1]" ]]; then
				echo "$array[1]"
				((removed++))
				continue
			fi
		fi
		if [[ "${1:A}" == "$array[1]" ]]; then
			isExists=1
			file="$array[2]"
			[[ -n "$3" && "$3" == "--remove" ]] && continue # pass updating newData
			if [[ -n "$2" ]]; then # New command
				newData="$newData${array[1]}:${2}\n" # New command
				flag=1
			fi
		fi
		[[ "$flag" -eq 0 ]] && newData="$newData$line\n"
	done
	[[ "$isExists" -eq 1 ]] && echo -en "$newData" > "$savedFile" # Save
}

save() {
	local fileName=${1:-./main.py}
	if [[ "$isExists" -eq 1 ]]; then # Already exists
		setCommand "$PWD" "$fileName"
	else # Not found
		echo "${PWD:A}:${fileName:A}" >> "$savedFile"
	fi
	echo "  Set file: ${fileName##*/}"
}

[[ ! -f "$savedFile" ]] && echo "# You can manually add paths here." > "$savedFile"
setCommand "$PWD"
if [[ "${0##*/}" == "run" ]]; then
	[[ -d ".venv" ]] && source .venv/bin/activate # Activate venv
	if [[ -f "$file" ]]; then # File found
		echo "$file"
		python3 "$file" "$@"
	elif [[ "${file::3}" == "-m " ]]; then # Module
		echo "${file:3}"
		python3 -m "${file:3}" "$@"
	else
		echo "run: no such file or directory: "${file##*/}""
	fi
elif [[ "${0##*/}" == "runfile" ]]; then
	if [[ "$1" == "-h" ]]; then # Help
		echo "usage: runfile [-m] [-h] [--remove] [--clean] [file]"
	elif [[ "$1" == "-m" ]]; then # Module
		if [[ -n "$2" ]]; then
			save "-m $2"
		else
			echo "runfile: No input file"
		fi
	elif [[ "$1" == "--remove" ]]; then
		setCommand "$PWD" "Null" "--remove"
	elif [[ "$1" == "--clean" ]]; then
		removed=0
		setCommand "Null" "Null" "--clean"
		echo "  Removed "$removed" command links."
	else
		save "${1:A}"
	fi
else
	echo "Something went wrong."
fi
