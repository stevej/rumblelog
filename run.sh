#!/bin/sh

if [ -z "$RUMBLELOG_ADMIN_USERNAME" ]; then
    echo "Need to set RUMBLELOG_ADMIN_USERNAME"
    exit 1
fi

if [ -z "$RUMBLELOG_ADMIN_PASSWORD" ]; then
    echo "Need to set RUMBLELOG_ADMIN_PASSWORD"
    exit 1
fi

if [ -z "$RUMBLELOG_FAUNA_SECRET" ]; then
    echo "Need to set RUMBLELOG_FAUNA_SECRET"
    exit 1
fi

bundle exec shotgun -p 5000 -o 0.0.0.0
