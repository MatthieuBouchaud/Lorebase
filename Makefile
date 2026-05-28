.PHONY: test test-network

test:
	./scripts/test.sh

test-network:
	RUN_NETWORK_TEST=1 ./scripts/test.sh
