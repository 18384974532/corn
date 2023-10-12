#!/bin/bash
ps -x | grep skynet | awk '{print $1}' | xargs kill -9
