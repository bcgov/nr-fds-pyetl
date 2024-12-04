#!/bin/sh
cd /flyway
apk add git
if [ ! -d ".git" ]; then
    git init
    git branch -m main
    git remote add -f origin https://github.com/bcgov/nr-spar
    git config core.sparseCheckout true
    echo "backend/src/main/resources/db/migration" >> .git/info/sparse-checkout
fi
git pull origin main
if [ ! -d "/flyway/sql" ]; then
    ln -s /flyway/backend/src/main/resources/db/migration /flyway/sql
    chmod 777 /flyway/sql
fi
