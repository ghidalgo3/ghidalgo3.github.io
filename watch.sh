#!/bin/bash 
set -euo pipefail
pushd static
hugo -d ../wwwroot -w

