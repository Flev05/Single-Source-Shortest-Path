# Makefile for SSSP Project
# Requires: SWI-Prolog, SBCL (or other Common Lisp)

.PHONY: all test test-prolog test-lisp run-prolog run-lisp clean help

# Default target
all: help

# Run all tests
test: test-prolog test-lisp

# Run Prolog tests (PLUnit)
test-prolog:
	@echo "Running Prolog tests..."
	swipl -l src/Prolog/sssp.pl -l tests/Prolog/test_sssp.pl -g "run_tests, halt(0)" -t "halt(1)"

# Run Lisp tests
test-lisp:
	@echo "Running Lisp tests..."
	sbcl --script tests/Lisp/test_sssp.lisp

# Launch Prolog REPL with source loaded
run-prolog:
	@echo "Launching SWI-Prolog REPL..."
	swipl -l src/Prolog/sssp.pl

# Launch Lisp REPL with source loaded
run-lisp:
	@echo "Launching SBCL REPL..."
	sbcl --load src/Lisp/sssp.lisp

# Clean compiled files (cross-platform)
clean:
	@echo "Cleaning compiled files..."
	-@find . -name "*.fasl" -delete 2>/dev/null || del /s /q *.fasl 2>nul
	-@find . -name "*.fas" -delete 2>/dev/null || del /s /q *.fas 2>nul
	-@find . -name "*.plc" -delete 2>/dev/null || del /s /q *.plc 2>nul
	-@find . -name "*.po" -delete 2>/dev/null || del /s /q *.po 2>nul
	@echo "Clean complete."

# Help target
help:
	@echo "SSSP Project - Available targets:"
	@echo ""
	@echo "  make test         - Run all tests (Prolog and Lisp)"
	@echo "  make test-prolog - Run Prolog tests with PLUnit"
	@echo "  make test-lisp   - Run Lisp tests"
	@echo "  make run-prolog  - Launch SWI-Prolog REPL with source loaded"
	@echo "  make run-lisp    - Launch SBCL REPL with source loaded"
	@echo "  make clean       - Remove compiled files"
	@echo "  make help        - Show this help message"
	@echo ""
