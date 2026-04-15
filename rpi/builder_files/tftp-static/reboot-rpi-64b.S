/* Assembly code for rebooting a Raspberry Pi.

This allows us to implement a boot loop, used when the WALT server is down
or the OS image is not ready.

PSCI (Power State Coordination Interface) is implemented by the RPi firmware's
secure monitor. Calling it via `smc` is model-independent. However, it does
not seem to work on rpi3b+. So we enable the watchdog in config.txt as a fallback.
*/
.section .text
.global _start
_start:
    ldr x0, =0x84000009    // PSCI SYSTEM_RESET (SMC32 function ID)
    smc #0
spin:
    wfe
    b spin
