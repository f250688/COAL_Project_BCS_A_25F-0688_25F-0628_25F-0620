# COAL_Project_BCS_A_25F-0688_25F-0628_25F-0620
Super Mario Engine: a 16-bit platform game in x86 Assembly (NASM + DOSBox) for EL2003 COAL
## Deviations and design notes

### 1. Vertical position is unsigned
mario_y (the feet position) is an unsigned 8.8 value, so it wraps at 256
pixels. Pit checks (y >= 192) and falling must compare it as unsigned
(JA/JB, not JG/JL). The death fall must stop before y reaches 256.

### 2. Frame rate
The physics values in Appendix A.5 assume about 30 frames per second.
FRAME_RATE is 30 only if Module 8 speeds up the timer. If we keep the
default timer, we set FRAME_RATE to 18 and scale the physics values so
the movement feels the same. All frame counts follow from FRAME_RATE.