#!/bin/sh

# ports must match the "ports:" section of docker-compose.yml
PORT_DENORMALIZED=17431
PORT_NORMALIZED=17432

# list all of the files that will be loaded into the database
# for the first part of this assignment, we will only load a small test zip file with ~10000 tweets
# but we will write are code so that we can easily load an arbitrary number of files
files='
test-data.zip
'

echo 'load normalized'
for file in $files; do
    # call the load_tweets.py file to load data into pg_normalized
    python3 load_tweets.py --db=postgresql://postgres:pass@localhost:$PORT_NORMALIZED/ --inputs $file
done

echo 'load denormalized'
for file in $files; do
    # use SQL's COPY command to load data into pg_denormalized
    #
    # - unzip -p streams the jsonl to stdout, one tweet per line
    # - sed strips \u0000 (postgres JSONB rejects null chars); this matches remove_nulls() in load_tweets.py
    # - COPY's default text format treats backslashes as escapes, which would corrupt the JSON,
    #   so we use CSV format with quote/delimiter set to control characters that never appear in tweets;
    #   each line then lands in the data column completely unmodified
    unzip -p "$file" | sed 's/\\u0000//g' | psql postgresql://postgres:pass@localhost:$PORT_DENORMALIZED/ -c "COPY tweets_jsonb (data) FROM STDIN csv quote e'\x01' delimiter e'\x02';"
done
