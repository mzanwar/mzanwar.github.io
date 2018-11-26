#!/bin/bash

DATE=$(date)
echo $DATE
cd /Users/zeshan.anwar/Blog/mzanwar.github.io/
git add .
git commit -m "Commit Date: - $DATE"
git push
