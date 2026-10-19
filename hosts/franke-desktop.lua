-- Copy to hypr/local.lua only on the original desktop.
return {
    monitors = {
        { output = "DP-1", mode = "2560x1440@165", position = "1922x-350", scale = 1, transform = 0 },
        { output = "HDMI-A-2", mode = "1920x1080@144", position = "0x0", scale = 1, transform = 0 },
    },
    environment = {
        LIBVA_DRIVER_NAME = "nvidia",
        __GLX_VENDOR_LIBRARY_NAME = "nvidia",
    },
}
