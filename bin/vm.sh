#!/usr/bin/env zsh

# --- Configuration ---
VM_NAME="win11"
VM_DIR="$HOME/Documents/VM"
VDI_PATH="$VM_DIR/VDI/windows11.qcow2"
BIOS_PATH="$VM_DIR/bios/OVMF_CODE_4M.secboot.fd"
VARS_PATH="$VM_DIR/bios/OVMF_VARS_4M.secboot.fd"
TPM_STATE_DIR="$VM_DIR/tpm"
TPM_SOCK_PATH="$TPM_STATE_DIR/swtpm-sock"
ISO_PATH="$HOME/Downloads/ISO/Win11_24H2_English_x64.iso"
VIRTIO_ISO_PATH="$HOME/Downloads/ISO/virtio-win-0.1.271.iso"
VDI_SIZE="128G"

# Default state
ENABLE_INSTALL_ISO=false
MAX_OUTPUTS=1 

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --install)
            ENABLE_INSTALL_ISO=true
            echo "Mode: Installation (ISO Boot)"
            ;;
        --displays)
            case "$2" in
                0|1|2)
                    MAX_OUTPUTS="$2"
                    echo "Config: Max display outputs set to $MAX_OUTPUTS"
                    shift
                    ;;
                *)
                    echo "Error: --displays requires 0, 1, or 2."
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--install] [--displays 0|1|2]"
            exit 1
            ;;
    esac
    shift
done

# --- Initialization ---
# 1. Create Disk if missing
if [ ! -f "$VDI_PATH" ]; then
    echo "Creating new 128GB VDI..."
    mkdir -p "$VM_DIR/VDI"
    qemu-img create -f qcow2 "$VDI_PATH" -o nocow=on "$VDI_SIZE"
fi

# 2. Setup TPM
mkdir -p "$TPM_STATE_DIR"
[ -e "$TPM_SOCK_PATH" ] && rm "$TPM_SOCK_PATH"

echo "Starting swtpm..."
swtpm socket --tpm2 --tpmstate dir="$TPM_STATE_DIR" --ctrl type=unixio,path="$TPM_SOCK_PATH" &
SWTPM_PID=$!
sleep 1

# --- Build QEMU Command ---
QEMU_COMMAND=(
    "qemu-system-x86_64"
    "-enable-kvm"
    "-machine" "q35,smm=on"
    "-m" "8G"
    "-cpu" "host,topoext=on"
    "-smp" "cores=4,threads=2"
    "-drive" "file=$VDI_PATH,if=none,id=disk0,format=qcow2"
    "-device" "virtio-blk-pci,drive=disk0,bootindex=1"
    "-drive" "if=pflash,format=raw,readonly=on,file=$BIOS_PATH"
    "-drive" "if=pflash,format=raw,file=$VARS_PATH"
    "-chardev" "socket,id=chrtpm,path=$TPM_SOCK_PATH"
    "-tpmdev" "emulator,id=tpm0,chardev=chrtpm"
    "-device" "tpm-tis,tpmdev=tpm0"
    "-object" "rng-random,filename=/dev/urandom,id=rng0"
    "-device" "virtio-rng-pci,rng=rng0"
    "-name" "$VM_NAME"
)

if [ "$ENABLE_INSTALL_ISO" == true ]; then
    QEMU_COMMAND+=(
        "-drive" "if=none,id=cd0,format=raw,media=cdrom,file=$ISO_PATH"
        "-drive" "if=none,id=cd1,format=raw,media=cdrom,file=$VIRTIO_ISO_PATH"
        "-device" "ide-cd,bus=ide.0,drive=cd0,bootindex=0"
        "-device" "ide-cd,bus=ide.1,drive=cd1"
        "-vga" "std"
        "-display" "gtk,gl=on"
        "-boot" "menu=on"
    )
else
    QEMU_COMMAND+=(
        "-device" "virtio-gpu-pci,max_outputs=$MAX_OUTPUTS"
        "-device" "virtio-serial-pci"
        "-spice" "port=5930,disable-ticketing=on"
        "-device" "virtserialport,chardev=spicechannel0,name=com.redhat.spice.0"
        "-chardev" "spicevmc,id=spicechannel0,name=vdagent"
        "-display" "gtk,gl=on" 
        "-netdev" "user,id=vnet0"
        "-device" "virtio-net-pci,netdev=vnet0"
        "-audiodev" "alsa,id=sound,out.try-poll=off"
        "-device" "ich9-intel-hda"
        "-device" "hda-duplex,audiodev=sound"
        "-usb"
        "-device" "usb-tablet"
        "-device" "usb-ehci,id=ehci"
        "-device" "qemu-xhci,id=xhci"
        "-device" "usb-host,bus=xhci.0,vendorid=0x322e,productid=0x2233"
    )
fi

# --- Execution ---
echo "Launching VM..."
"${QEMU_COMMAND[@]}"

# --- Cleanup ---
echo "Shutting down swtpm..."
kill -TERM "$SWTPM_PID" 2>/dev/null
wait "$SWTPM_PID" 2>/dev/null
[ -e "$TPM_SOCK_PATH" ] && rm "$TPM_SOCK_PATH"
echo "Done."
