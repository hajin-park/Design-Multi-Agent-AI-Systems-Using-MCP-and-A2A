#!/bin/bash

# Script to verify all prerequisites for MAKDO dual-cluster deployment
# Run this before proceeding with cluster setup

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Checking prerequisites for MAKDO deployment..."
echo ""

# Track overall status
ALL_GOOD=true

# Check Docker
echo -n "Checking Docker... "
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        DOCKER_VERSION=$(docker version --format '{{.Server.Version}}')
        echo -e "${GREEN}✓${NC} Docker $DOCKER_VERSION (running)"
    else
        echo -e "${RED}✗${NC} Docker is installed but not running"
        echo "  → Start Docker Desktop or run: sudo systemctl start docker"
        ALL_GOOD=false
    fi
else
    echo -e "${RED}✗${NC} Docker not found"
    echo "  → Install from: https://docs.docker.com/get-docker/"
    ALL_GOOD=false
fi

# Check kubectl
echo -n "Checking kubectl... "
if command -v kubectl &> /dev/null; then
    KUBECTL_VERSION=$(kubectl version --client 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo -e "${GREEN}✓${NC} kubectl $KUBECTL_VERSION"
else
    echo -e "${RED}✗${NC} kubectl not found"
    echo "  → Install from: https://kubernetes.io/docs/tasks/tools/"
    ALL_GOOD=false
fi

# Check kind
echo -n "Checking kind... "
if command -v kind &> /dev/null; then
    KIND_VERSION=$(kind version | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
    echo -e "${GREEN}✓${NC} kind $KIND_VERSION"

    # Check if version is recent enough (v0.20.0+)
    KIND_MAJOR=$(echo $KIND_VERSION | cut -d'v' -f2 | cut -d'.' -f1)
    KIND_MINOR=$(echo $KIND_VERSION | cut -d'v' -f2 | cut -d'.' -f2)
    if [ "$KIND_MAJOR" -eq 0 ] && [ "$KIND_MINOR" -lt 20 ]; then
        echo -e "${YELLOW}  ⚠${NC}  Warning: kind version is old. Recommend v0.20.0+"
        echo "  → Upgrade: brew upgrade kind (macOS) or download from https://kind.sigs.k8s.io/"
    fi
else
    echo -e "${RED}✗${NC} kind not found"
    echo "  → Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
    ALL_GOOD=false
fi

# Check for existing kind clusters
echo ""
echo "Checking for existing kind clusters..."
EXISTING_CLUSTERS=$(kind get clusters 2>/dev/null || echo "")
if [ -n "$EXISTING_CLUSTERS" ]; then
    echo -e "${YELLOW}Found existing clusters:${NC}"
    echo "$EXISTING_CLUSTERS" | while read cluster; do
        echo "  - $cluster"
    done
    echo ""
    echo "If you want to use 'makdo-control' and 'makdo-worker' cluster names,"
    echo "you may need to delete existing clusters with those names first:"
    echo "  kind delete cluster --name makdo-control"
    echo "  kind delete cluster --name makdo-worker"
else
    echo -e "${GREEN}No existing kind clusters found${NC}"
fi

# Check that the host ports used by the kind clusters are free
echo ""
echo -n "Checking host ports 8080 9090 8100 8099 8200... "
if echo "$EXISTING_CLUSTERS" | grep -qE '^makdo-(control|worker)$'; then
    echo -e "${YELLOW}⚠${NC}  skipped (the makdo clusters already exist and use these ports)"
else
    BUSY_PORTS=""
    for port in 8080 9090 8100 8099 8200; do
        # A successful TCP connection means something is already listening on the port
        if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2> /dev/null; then
            BUSY_PORTS="$BUSY_PORTS $port"
        fi
    done
    if [ -n "$BUSY_PORTS" ]; then
        echo -e "${RED}✗${NC} in use:$BUSY_PORTS"
        echo "  → control-cluster.yaml / worker-cluster.yaml map these ports; stop whatever is using them"
        ALL_GOOD=false
    else
        echo -e "${GREEN}✓${NC} free"
    fi
fi

# Check available disk space
echo ""
echo -n "Checking disk space... "
AVAILABLE_GB=$(df -Pk . | awk 'NR==2 {print int($4 / 1024 / 1024)}')
if [ "$AVAILABLE_GB" -lt 10 ]; then
    echo -e "${YELLOW}⚠${NC}  Low disk space: ${AVAILABLE_GB} GB"
    echo "  → KinD clusters need ~5-10GB. Consider freeing up space."
else
    echo -e "${GREEN}✓${NC} ${AVAILABLE_GB} GB available"
fi

# Check Docker memory allocation
echo -n "Checking Docker resources... "
DOCKER_MEM=$(docker info 2>/dev/null | grep "Total Memory" | awk '{print $3 $4}')
if [ -n "$DOCKER_MEM" ]; then
    echo -e "${GREEN}✓${NC} Memory: $DOCKER_MEM"
else
    echo -e "${YELLOW}⚠${NC}  Could not check Docker memory"
fi

# Summary
echo ""
echo "=========================================="
if [ "$ALL_GOOD" = true ]; then
    echo -e "${GREEN}✓ All prerequisites met!${NC}"
    echo ""
    echo "You can proceed with cluster creation:"
    echo "  1. Create control cluster: kind create cluster --config control-cluster.yaml"
    echo "  2. Create worker cluster: kind create cluster --config worker-cluster.yaml"
else
    echo -e "${RED}✗ Some prerequisites missing${NC}"
    echo ""
    echo "Please install missing tools before proceeding."
    exit 1
fi
echo "=========================================="
