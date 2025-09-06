#!/usr/bin/env bash
aws s3 ls s3://$1/backup/ --recursive --human-readable --summarize
