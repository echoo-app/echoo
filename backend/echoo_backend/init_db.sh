#!/bin/bash
rm -f echoo.db
sqlite3 echoo.db < migrations/schema.sql
