INPREFIX=
OUTDIR=builds
OUTPREFIX=

default: buildandupload

# Device output file
$(OUTDIR)/$(OUTPREFIX)device.nut: device
# Agent output file
$(OUTDIR)/$(OUTPREFIX)agent.nut: agent

# Build device code
device:
	pleasebuild $(INPREFIX)device.nut > $(OUTDIR)/$(OUTPREFIX)device.nut
# Build agent code
agent:
	pleasebuild $(INPREFIX)agent.nut > $(OUTDIR)/$(OUTPREFIX)agent.nut

# Build code
build: device agent

# Upload code
upload: builds/device.nut builds/agent.nut
	imp push

# Build and upload code, the default
buildandupload: build upload

clean:
	rm builds/*{device,agent}.nut

test: build
	imptest test $(IMPTEST_FILE)
