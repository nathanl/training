# Read in the system's dictionary.
cat /usr/share/dict/words |     

# Find words containing 'purple'
grep purple |                   

# Count the letters in each word
awk '{print length($1), $1}' |

# Sort lines ("${length} ${word}")
sort -n |                       

# Take the last line of the input
tail -n 1 |                     

# Take the second part of the line
cut -d " " -f 2 |               

# Output the results
# (this is just here so that any of the lines
# above can be commented out)
cat                             
