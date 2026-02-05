#!/bin/env bash

updates=$(yay -Pu | wc -l)
echo "$updates"
