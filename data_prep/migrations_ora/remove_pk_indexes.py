import re

# Define the regular expression pattern
pattern = re.compile(r"^CREATE UNIQUE INDEX .+_PK ON .+")

# Read the file
with open("migrations_ora/sql/V2.0.2__concep_tabs_3_orig.sql", "r") as file:
    lines = file.readlines()

# Process the lines
with open("migrations_ora/sql/V2.0.2__concep_tabs_3.sql", "w") as file:
    for line in lines:
        if pattern.match(line):
            file.write(f"-- {line}")
        else:
            file.write(line)
