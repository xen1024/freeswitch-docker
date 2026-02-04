# FreeSWITCH Build from Source - Module Customization Guide

## Overview

When building FreeSWITCH from source, you can customize which modules to include. This affects:
- Build time
- Final image size
- Available features
- Runtime resource usage

## How to Customize Modules

### Method 1: Edit Dockerfile.source

Before building, edit the `Dockerfile.source` file in the builder stage. Find these lines:

```dockerfile
# Configure modules to build
RUN sed -i 's|#applications/mod_av|applications/mod_av|' modules.conf && \
    sed -i 's|#applications/mod_callcenter|applications/mod_callcenter|' modules.conf
```

Add or remove `sed` commands to enable/disable modules.

### Method 2: Create Custom modules.conf

Create a `modules.conf.custom` file with your desired modules, then modify the Dockerfile to copy it:

```dockerfile
COPY modules.conf.custom /usr/src/freeswitch/modules.conf
```

## Common Module Categories

### Essential Modules (Always Enable)
```
loggers/mod_console
loggers/mod_logfile
applications/mod_commands
applications/mod_dptools
endpoints/mod_sofia
dialplans/mod_dialplan_xml
formats/mod_local_stream
formats/mod_native_file
formats/mod_sndfile
formats/mod_tone_stream
say/mod_say_en
event_handlers/mod_event_socket
```

### Audio Codecs
```
# Standard codecs
codecs/mod_g711           # G.711 (PCMU/PCMA) - always needed
codecs/mod_g722           # G.722 HD voice
codecs/mod_g729           # G.729 (requires license)
codecs/mod_gsm            # GSM
codecs/mod_ilbc           # iLBC

# High quality codecs
#codecs/mod_opus          # Opus (modern, best quality)
#codecs/mod_speex         # Speex

# Video codecs
#codecs/mod_h264          # H.264 video
#codecs/mod_vp8           # VP8 video
#codecs/mod_vp9           # VP9 video
```

### Applications
```
# Call center
#applications/mod_callcenter

# Conference
applications/mod_conference

# Voicemail
applications/mod_voicemail

# IVR
applications/mod_dptools

# Call recording
#applications/mod_avmd      # Answering machine detection
#applications/mod_av        # Audio/Video

# Fax
#applications/mod_spandsp   # T.38 fax support

# Text-to-speech
#applications/mod_flite     # Open source TTS
#applications/mod_tts_commandline  # External TTS
```

### File Formats
```
formats/mod_local_stream   # Music on hold
formats/mod_native_file    # Native FS formats
formats/mod_sndfile        # WAV, AIFF, etc
formats/mod_tone_stream    # Generate tones

#formats/mod_shout         # MP3 streaming
#formats/mod_opusfile      # Opus files
#formats/mod_shell_stream  # Stream from shell command
```

### Endpoints
```
endpoints/mod_sofia        # SIP (essential)
#endpoints/mod_skinny      # Cisco SCCP
#endpoints/mod_verto       # WebRTC via Verto protocol
```

### Languages/Scripting
```
#languages/mod_lua         # Lua scripting
#languages/mod_python      # Python scripting
#languages/mod_perl        # Perl scripting
#languages/mod_v8          # JavaScript (V8)
```

### Databases
```
#applications/mod_db       # Simple DB interface
#applications/mod_redis    # Redis support
```

### Event Handlers
```
event_handlers/mod_event_socket   # ESL (essential)
#event_handlers/mod_cdr_csv       # CSV CDR
#event_handlers/mod_json_cdr      # JSON CDR
#event_handlers/mod_xml_cdr       # XML CDR
#event_handlers/mod_cdr_mongodb  # MongoDB CDR
```

### XML Interfaces
```
#xml_int/mod_xml_curl      # Fetch config from HTTP
#xml_int/mod_xml_cdr       # XML CDR
#xml_int/mod_xml_rpc       # XML-RPC interface
```

## Example Custom modules.conf

### Minimal SIP Server (smallest build)
```
# Loggers
loggers/mod_console
loggers/mod_logfile

# Core
applications/mod_commands
applications/mod_dptools
dialplans/mod_dialplan_xml

# Codecs
codecs/mod_g711
codecs/mod_g722

# Endpoint
endpoints/mod_sofia

# Formats
formats/mod_local_stream
formats/mod_native_file
formats/mod_sndfile
formats/mod_tone_stream

# Event
event_handlers/mod_event_socket

# Say
say/mod_say_en
```

### Full-Featured PBX
```
# Include all from minimal, plus:

# Additional codecs
codecs/mod_opus
codecs/mod_speex

# Applications
applications/mod_callcenter
applications/mod_conference
applications/mod_voicemail
applications/mod_fifo
applications/mod_db

# Formats
formats/mod_shout
formats/mod_opusfile

# Languages
languages/mod_lua

# CDR
event_handlers/mod_cdr_csv
event_handlers/mod_json_cdr

# XML
xml_int/mod_xml_curl
```

### Call Center
```
# Include PBX modules, plus:
applications/mod_callcenter
applications/mod_fifo
applications/mod_distributor
event_handlers/mod_erlang_event
```

## Editing Modules in Dockerfile

Replace this section in Dockerfile.source:

```dockerfile
# Configure modules to build
RUN sed -i 's|#applications/mod_av|applications/mod_av|' modules.conf && \
    sed -i 's|#applications/mod_callcenter|applications/mod_callcenter|' modules.conf && \
    sed -i 's|#formats/mod_shout|formats/mod_shout|' modules.conf && \
    sed -i 's|#formats/mod_opusfile|formats/mod_opusfile|' modules.conf && \
    sed -i 's|#codecs/mod_opus|codecs/mod_opus|' modules.conf
```

With your custom enables/disables:

```dockerfile
# Minimal build example
RUN cat modules.conf | grep -v "^#" | grep -v "^$" > modules.conf.base && \
    echo "applications/mod_callcenter" >> modules.conf.base && \
    echo "applications/mod_conference" >> modules.conf.base && \
    echo "codecs/mod_opus" >> modules.conf.base && \
    mv modules.conf.base modules.conf
```

## Build Impact

| Configuration | Build Time | Image Size | Use Case |
|--------------|------------|------------|----------|
| Minimal | ~10 min | ~200 MB | SIP proxy, basic routing |
| Standard | ~20 min | ~400 MB | Small business PBX |
| Full | ~30 min | ~800 MB | Enterprise PBX, call center |
| All modules | ~45 min | ~1.5 GB | Development, testing |

## Testing Your Build

After building with custom modules:

```bash
# Build with custom modules
docker build -f Dockerfile.source -t freeswitch-custom .

# Run and check loaded modules
docker run --rm freeswitch-custom fs_cli -x "show modules" | less

# Check specific module
docker run --rm freeswitch-custom fs_cli -x "module_exists mod_opus"
```

## Troubleshooting

### Module fails to build
- Check if dependencies are installed in the builder stage
- Some modules require external libraries (add to apt-get install)

### Module not loading at runtime
- Verify module exists: `ls /usr/local/freeswitch/mod/`
- Check if dependencies copied from builder stage
- Review logs: `/var/log/freeswitch/freeswitch.log`

### Reducing build time
- Disable unused video codecs (h264, vp8, vp9)
- Skip language modules if not needed
- Disable optional applications

## Recommended Builds

### WebRTC Server
Enable these additional modules:
- endpoints/mod_verto
- codecs/mod_opus
- applications/mod_av

### SIP Trunk Provider
Minimal build plus:
- applications/mod_distributor
- applications/mod_fifo
- xml_int/mod_xml_curl

### Recording Server
Standard build plus:
- applications/mod_av
- formats/mod_shell_stream
- applications/mod_avmd
