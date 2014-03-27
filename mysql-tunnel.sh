#!/bin/bash

echo -e "\nTunneling MySQL connections to staging.impactwave.com.\nPress Ctrl+C to stop.\n"
ssh -L 3306:localhost:3306 staging.impactwave.com -N
