#!/bin/bash

# Navigate to workspaces directory
cd ../_workspaces

# New structure: account/region/stack
# Iterate through accounts
for account in */ ; do
  cd "$account"
  # Iterate through regions  
  for region in */ ; do
    cd "$region"
    # Iterate through stacks
    for stack in */ ; do
      cd "$stack"
      echo "Getting outputs for: $account$region$stack"
      terragrunt output -json > .outputs.json 2>/dev/null || echo "  ⚠ No outputs (infrastructure not deployed yet)"
      cd ..
    done
    cd ..
  done
  cd ..
done

echo "✓ Outputs collection complete"
