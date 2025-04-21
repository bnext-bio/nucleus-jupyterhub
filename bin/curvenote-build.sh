#!/bin/bash

DEVNOTE_HTML_PATH=~/work/devnotes/.html

if grep tokens ~/.curvenote/settings.json; then
    rm -f ${DEVNOTE_HTML_PATH}/index.html
else
    cp /opt/repo/share/set-token.html ${DEVNOTE_HTML_PATH}/index.html
    exit
fi

for link in `ls -1 ${DEVNOTE_HTML_PATH}`; do
    link_name = `basename ${link}`
    if [ ! -d ~/work/devnotes/${link_name} ]; then
        # Delete links to devnotes that have been removed.
        echo "Deleting removed devnote: ${link_name}"
        rm ${link}
    fi
done

for devnote_dir in `ls -1d ~/work/devnotes/*/`; do
    name=`basename $devnote_dir`
   
    export BASE_URL=${BASE_URL_PREFIX}/$name/
    
    cd $devnote_dir
    curvenote build --html
    
    if [ ! -L ~/work/devnotes/.html/$name ]; then
        if [ -d $devnote_dir/_build/html ]; then
            ln -s $devnote_dir/_build/html ~/work/devnotes/.html/$name
        fi
    fi
done

# Kill webserver
ps aux | grep "node ./server.js"| grep -v "grep" | awk '{print $2}' | xargs -r kill