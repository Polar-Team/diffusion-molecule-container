# Image Optimization Spec

## Overview
Optimize the diffusion-molecule-container Docker image to achieve maximum efficiency while maintaining all required functionality.

## Current State
- **Efficiency**: 97%
- **Wasted Space**: 18 MB
- **Base Image**: `docker:dind-alpine` (Docker-in-Docker)

## Wasted Space Analysis

### Files from Base Image (Cannot Remove)
These files are baked into the base `docker:dind-alpine` image layers:
- `/usr/lib/libzpool.so.6.0.0` (3.7 MB) - ZFS library used by Docker storage drivers
- `/usr/bin/ssh` (1.7 MB) - SSH client (needed for git operations)
- `/bin/busybox` (1.6 MB) - Essential Alpine Linux utility (cannot remove)
- `/usr/bin/ssh-keyscan` (980 KB) - SSH utility
- `/lib/apk/db/installed` (964 KB) - APK package database (needed for package management)
- `/usr/bin/ssh-keygen` (963 KB) - SSH key generation utility

### Why We Can't Remove These Files
1. **Base Image Layers**: Files in the base image are in read-only layers that we cannot modify
2. **Docker Dependencies**: ZFS libraries may be required by Docker's storage drivers
3. **Git Dependencies**: SSH binaries are needed for git operations with SSH remotes
4. **System Dependencies**: busybox and APK database are essential for Alpine Linux

## Optimization Strategy

### Already Applied ✅
1. Combined RUN commands to reduce layers (8 → 5 layers)
2. Added `--no-cache-dir` to pip installations
3. Cleaned up APK cache, pip cache, and temporary files
4. Removed unnecessary SSH server files (`/etc/ssh/moduli`)
5. Attempted removal of ZFS libraries (may fail if in use)

### Acceptance Criteria
- **Minimum Efficiency**: 96% (configured in `.dive-ci`)
- **Maximum Wasted Space**: 25 MB (configured in `.dive-ci`)
- **Current Achievement**: 97% efficiency, 18 MB wasted ✅

### Decision
**Accept 97% efficiency as optimal** because:
1. Remaining wasted space is from base image (outside our control)
2. Files serve legitimate purposes (Docker storage, git SSH, system utilities)
3. Removing them would break functionality or is impossible
4. 97% exceeds our 96% minimum threshold
5. 18 MB is below our 25 MB maximum threshold

## Testing Strategy
1. Build image with optimizations
2. Run dive analysis to verify efficiency
3. Test functionality:
   - Docker-in-Docker operations
   - Git clone with SSH
   - Molecule test execution
   - Ansible playbook runs

## Configuration Files
- `.dive-ci` - CI efficiency thresholds (96% minimum, 25 MB max wasted)
- `Makefile` - Build targets with DIND_VERSION override support
- `Dockerfile` - Optimized multi-stage build with cleanup

## Conclusion
The image is optimized to 97% efficiency. Further optimization would require:
- Building from scratch (losing Docker-in-Docker functionality)
- Removing essential system utilities (breaking functionality)
- Modifying base image layers (impossible)

**Status**: ✅ Optimization Complete - 97% efficiency achieved
