#!/bin/env bash

updates=$(yay -Qua | wc -l)
echo "$updates"
