#!/bin/bash
# USB Gadget Configuration for Tesla Storage Emulation

GADGET_DIR="/sys/kernel/config/usb_gadget/tesla-cam"
STORAGE_FILE="/mnt/tesla-storage/tesla-cam.img"
STORAGE_SIZE="256G"  # Adjust based on your storage

start_gadget() {
    echo "Starting Tesla USB Storage Gadget..."
    
    # Load required modules
    modprobe libcomposite
    
    # Create storage file if it doesn't exist
    if [ ! -f "$STORAGE_FILE" ]; then
        echo "Creating storage file..."
        sudo dd if=/dev/zero of="$STORAGE_FILE" bs=1M count=$((256*1024)) status=progress
        sudo mkfs.exfat -n TESLA-CAM "$STORAGE_FILE"
    fi
    
    # Create gadget
    mkdir -p "$GADGET_DIR"
    cd "$GADGET_DIR"
    
    # Configure gadget
    echo 0x1d6b > idVendor  # Linux Foundation
    echo 0x0104 > idProduct # Multifunction Composite Gadget
    echo 0x0100 > bcdDevice # v1.0.0
    echo 0x0200 > bcdUSB    # USB 2.0
    
    # Create English strings
    mkdir -p strings/0x409
    echo "fedcba9876543210" > strings/0x409/serialnumber
    echo "Tesla Cam AI" > strings/0x409/manufacturer
    echo "Tesla Camera Storage" > strings/0x409/product
    
    # Create configuration
    mkdir -p configs/c.1/strings/0x409
    echo "Config 1: Mass Storage" > configs/c.1/strings/0x409/configuration
    echo 250 > configs/c.1/MaxPower
    
    # Create mass storage function
    mkdir -p functions/mass_storage.usb0
    echo 1 > functions/mass_storage.usb0/stall
    echo "$STORAGE_FILE" > functions/mass_storage.usb0/lun.0/file
    echo 1 > functions/mass_storage.usb0/lun.0/removable
    echo 0 > functions/mass_storage.usb0/lun.0/cdrom
    echo 0 > functions/mass_storage.usb0/lun.0/ro
    echo 0 > functions/mass_storage.usb0/lun.0/nofua
    
    # Link function to configuration
    ln -s functions/mass_storage.usb0 configs/c.1/
    
    # Enable gadget
    ls /sys/class/udc > UDC
    
    echo "USB Storage Gadget started successfully"
    
    # Mount the storage file
    mount_storage
}

stop_gadget() {
    echo "Stopping Tesla USB Storage Gadget..."
    
    # Unmount storage
    umount_storage
    
    if [ -d "$GADGET_DIR" ]; then
        cd "$GADGET_DIR"
        
        # Disable gadget
        echo "" > UDC
        
        # Remove function from configuration
        rm -f configs/c.1/mass_storage.usb0
        
        # Remove strings
        rmdir strings/0x409
        rmdir configs/c.1/strings/0x409
        
        # Remove configuration
        rmdir configs/c.1
        
        # Remove function
        rmdir functions/mass_storage.usb0
        
        # Remove gadget
        cd /
        rmdir "$GADGET_DIR"
    fi
    
    # Unload module
    modprobe -r usb_f_mass_storage
    
    echo "USB Storage Gadget stopped"
}

mount_storage() {
    echo "Mounting Tesla storage..."
    
    # Create mount point
    mkdir -p /mnt/tesla-cam
    
    # Wait for device to be ready
    sleep 2
    
    # Mount the storage file
    mount -o loop,uid=1000,gid=1000 "$STORAGE_FILE" /mnt/tesla-cam
    
    # Create Tesla directory structure
    mkdir -p /mnt/tesla-cam/TeslaCam
    mkdir -p /mnt/tesla-cam/TeslaTrackMode
    mkdir -p /mnt/tesla-cam/TeslaSentry
    
    echo "Storage mounted at /mnt/tesla-cam"
}

umount_storage() {
    echo "Unmounting Tesla storage..."
    
    # Sync and unmount
    sync
    umount /mnt/tesla-cam 2>/dev/null || true
}

case "$1" in
    start)
        start_gadget
        ;;
    stop)
        stop_gadget
        ;;
    restart)
        stop_gadget
        sleep 2
        start_gadget
        ;;
    status)
        if [ -d "$GADGET_DIR" ] && [ -n "$(cat $GADGET_DIR/UDC 2>/dev/null)" ]; then
            echo "Tesla USB Storage Gadget is running"
            exit 0
        else
            echo "Tesla USB Storage Gadget is not running"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
