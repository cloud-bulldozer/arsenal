JSONNET = https://github.com/google/jsonnet/releases/download/v0.15.0/jsonnet-bin-v0.15.0-linux.tar.gz
BINDIR = bin
TEMPLATESDIR = templates
OUTPUTDIR = rendered
TMPDIR = tmp
ALLDIRS = $(BINDIR) $(OUTPUTDIR) $(TMPDIR)

# Get all templates at $(TEMPLATESDIR)
TEMPLATES = $(wildcard $(TEMPLATESDIR)/*.jsonnet)

# Replace $(TEMPLATESDIR)/*.jsonnet by $(OUTPUTDIR)/*.json
outputs = $(patsubst $(TEMPLATESDIR)/%.jsonnet, $(OUTPUTDIR)/%.json, $(TEMPLATES))

# Replace $(TEMPLATESDIR)/*.jsonnet by $(TMPDIR)/*.jsonnet
fmtoutputs = $(patsubst $(TEMPLATESDIR)/%.jsonnet, $(TMPDIR)/%.jsonnet, $(TEMPLATES))

all: deps build

deps: $(ALLDIRS) $(TEMPLATESDIR)/grafonnet-lib $(BINDIR)/jsonnet

$(ALLDIRS):
	mkdir -p $(ALLDIRS)

format: $(fmtoutputs)

build: deps $(TEMPLATESDIR)/grafonnet-lib $(outputs)

clean:
	@echo "Cleaning up"
	rm -rf $(ALLDIRS) $(TEMPLATESDIR)/grafonnet-lib

$(TEMPLATESDIR)/grafonnet-lib:
	git clone --depth 1 https://github.com/grafana/grafonnet-lib.git $(TEMPLATESDIR)/grafonnet-lib

$(BINDIR)/jsonnet:
	@echo "Downloading jsonnet binary"
	curl -s -L $(JSONNET) | tar xzf - -C $(BINDIR)

# Format each template and output to $(TMPDIR)
$(TMPDIR)/%.jsonnet: $(TEMPLATESDIR)/%.jsonnet
	@echo "Formating template $<"
	$(BINDIR)/jsonnetfmt $< > $@
	mv $@ $<

# Build each template and output to $(OUTPUTDIR)
$(OUTPUTDIR)/%.json: $(TEMPLATESDIR)/%.jsonnet
	@echo "Building template $<"
	$(BINDIR)/jsonnet $< > $@

