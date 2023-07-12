#!/bin/bash

#Constants:
args=("$@") #Array of arguments
nOArgs=("$#")   #Number of arguments

options=("-v" "-q" "-less" "-y" "-del")
declare -A OPTIONS_FlAGS=( [-v]=false [-q]=false [-less]=false [-y]=false [-del]=false)
#The keys in this array must be equal to the options provided by the $options array. Values are re-set in a loop whilst checking the arguments.
#Also this array should only contain false values, since the arguments can only set them to true, if the are given.

#Flags:
showVerbose=false
controlBeforeConv=true
path=""
mdepth=1

#Initial arg checks:
if [ "$nOArgs" -eq "0" ]
    then
    echo "Arguments missing. (use \"vdiConv.sh help\" for help page.)"
    exit 1
elif [ "$nOArgs" -gt "6" ]
    then
    echo "Too many arguments passed to script, exiting.. (use \"vdiConv.sh help\" for help page.)"
    exit 1
elif [ "${args[0]}" = "help" ]
    then
    printf "Syntax:\n\tvDiskConv.sh /path/to/start [maxdepth] [options]\n\tvDiskConv.sh /home/username/Virtualbox 2 -v\nOptions:\n\t-v\tShow verbose output\n\t-q\tDont show check dialog before converting\n\t-less\tPipe check dialog into less (Useful for large ammount of disks)\n\t-y\tDont ask for confirmation\n\t-del\tDeletes the vdi disk after converting it\n"
    exit 0
elif [ -d "${args[0]}" ]
    then
    path="${args[0]}"
    if [[ ${args[1]} =~ ^-?[0-9]+$  ]]
    then
        mdepth=${args[1]}
    else
        echo "Argument for maxdepth is not recognized as an integer"
        exit 1
    fi
else
    echo "Path to directory could not be found"
    exit 1
fi

#Loop args and set flags:
args_index=2 #Start at 3rd arg, 1st and 2nd have already been checked.
while [ $args_index -lt $nOArgs ]
do
    current_arg=${args[args_index]}
    options_index=0
    while [ $options_index -lt ${#options[@]} ]
    do
        if [ "$current_arg" = "${options[$options_index]}" ]
        then
            OPTIONS_FlAGS["$current_arg"]=true
        fi
        ((options_index++))
    done
    ((args_index++))
done


#Read the disks into an array:
mapfile -d $'\0' disks < <(find $path -maxdepth $mdepth -name "*.vdi" -print0)
diskCount=${#disks[@]}

new_disks=("${disks[@]}")
rename_index=0

declare -a original_full_disk_names=()
declare -a new_full_disk_names=()

#Get the diskname, remove its file extension and add a new one. Variables are set from each state of the disk path and reused later.
while [ $rename_index -lt "${#new_disks[@]}" ]
do
    c_full_diskname="${new_disks["$rename_index"]}"
    IFS='.' read -ra c_dn_splitted <<< "$c_full_diskname"
    c_dn_splitted[-1]=""

    c_diskname="$(IFS=; echo "${c_dn_splitted[*]}")"
    c_original_diskname="${c_diskname}.vdi"
    c_new_diskname="${c_diskname}.qcow2"

    #Check if a .qcow2 disk with the same name already exists
    if [ -f "$c_new_diskname" ]
    then
        if [ "${OPTIONS_FlAGS[-v]}" = "true" ]
        then
            echo "Skipping "$c_original_diskname" ..."
        fi
    else
        original_full_disk_names[$rename_index]="$c_original_diskname"
        new_full_disk_names[$rename_index]="$c_new_diskname"
    fi

    ((rename_index++))
done

if [ "${OPTIONS_FlAGS[-q]}" = "false" ]
then
    test "${OPTIONS_FlAGS[-less]}" = "true" && printf "%s\n" "Total amount of disks to convert: "${#original_full_disk_names[@]}"" "${original_full_disk_names[@]}" | less || printf "%s\n" "${original_full_disk_names[@]}" "Total amount of disks to convert: "${#original_full_disk_names[@]}""
fi

if [ "${OPTIONS_FlAGS[-y]}" = "false" ]
then
    read -p "Proceed? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1
fi

#Convert
convert_index=0
while [ $convert_index -lt ${#original_full_disk_names[@]} ]
do
    qemu-img convert -f vdi -O qcow2 "${original_full_disk_names[$convert_index]}" "${new_full_disk_names[$convert_index]}"
    if [ "${OPTIONS_FlAGS[-v]}" = "true" ]
    then
        echo "Converted disk ${convert_index}"
    fi

    if [ "${OPTIONS_FlAGS[-del]}" = "true" ]
    then
        echo "Deleted ${convert_index}"
        rm "${original_full_disk_names[$convert_index]}"
    fi

    ((convert_index++))
done

echo "Done."
exit 0
