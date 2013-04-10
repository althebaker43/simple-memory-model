### Variables ###

SRC_DIR = src
TST_DIR = test
OBJ_DIR = work
BIN_DIR = bin
OUT_DIR = out
PLOT_DIR = plot
DOC_DIR = docs

VPATH = $(SRC_DIR) \
        $(TST_DIR) \
        $(OBJ_DIR) \
        $(BIN_DIR)
 
TARGET = datapath

SECTIONS = cpu \
           cache \
           mem

SOURCES := $(SECTIONS:%=%.vhdl) 

SECTION_OBJS := $(SECTIONS:%=%.o)

TEST_OBJS := $(SECTIONS:%=test_%.o)

TEST_BINS := $(SECTIONS:%=test_%)

RUNS := $(SECTIONS:%=run_%)

CC = ghdl

### Recipies ###

## Global Recipies

runs : $(RUNS)

tests : $(TEST_BINS)

objs : $(SECTION_OBJS)

## Individual Recipies

$(RUNS) : run_% : test_% | \
                  $(OUT_DIR) \
                  $(PLOT_DIR)
	./$(BIN_DIR)/$(notdir $<) \
		--assert-level=warning \
		--stop-time=10us \
		--vcd=$(OUT_DIR)/$@.vcd

$(TEST_BINS) : test_% : test_%.o | \
                        $(BIN_DIR)
	$(CC) \
		-e \
		-g \
		--work=$(TARGET) \
		--workdir=$(OBJ_DIR) \
		-o $(BIN_DIR)/$@ \
		$@

$(TEST_OBJS) : test_%.o : test_%.vhdl \
                          %.o | \
                          $(OBJ_DIR)
	$(CC) \
		-a \
		-g \
		--work=$(TARGET) \
		--workdir=$(OBJ_DIR) \
		$<

$(SECTION_OBJS) : %.o : misc.o \
                        %.vhdl \
                        ctags | \
                        $(OBJ_DIR)
	$(CC) \
		-a \
		-g \
		--work=$(TARGET) \
		--workdir=$(OBJ_DIR) \
		$(SRC_DIR)/$*.vhdl

misc.o : misc.vhdl \
         ctags | \
		 $(OBJ_DIR)
	$(CC) \
		-a \
		-g \
		--work=$(TARGET) \
		--workdir=$(OBJ_DIR) \
		$(SRC_DIR)/misc.vhdl

$(TARGET).o : misc.o \
              $(SECTION_OBJS) \
              ctags | \
              $(OBJ_DIR)
	$(CC) \
		-a \
		-g \
		--work=$(TARGET) \
		--workdir=$(OBJ_DIR) \
		$(SRC_DIR)/$(TARGET).vhdl


## Documentation ##

doc : | $(DOC_DIR)
	doxygen $(TARGET).doxy


ctags : $(SOURCES)
	ctags \
		--languages=VHDL \
		-R $(SRC_DIR) \


## Directory initialization ##

$(TST_DIR) :
	mkdir $@

$(BIN_DIR) :
	mkdir $@

$(OBJ_DIR) :
	mkdir $@

$(OUT_DIR) :
	mkdir $@

$(PLOT_DIR) :
	mkdir $@

$(DOC_DIR) :
	mkdir $@

## Cleaning ##

clean :
	-rm -rf $(OBJ_DIR)/*
	-rm -rf $(BIN_DIR)/*
	-rm -rf $(OUT_DIR)/*
	-rm -rf $(DOC_DIR)/*

clean-doc :
	-rm -rf $(DOC_DIR)/*
