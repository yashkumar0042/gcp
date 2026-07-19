If you're using **Google Cloud Bigtable**, you can do everything from the **cbt CLI** (recommended) or **gcloud** (for instance creation). Below is a complete workflow.

---

# Step 1: Set Project

```bash
gcloud config set project PROJECT_ID
```

Verify:

```bash
gcloud config get-value project
```

---

# Step 2: Create a Bigtable Instance

Using **gcloud**

```bash
gcloud bigtable instances create my-bigtable \
    --display-name="My Bigtable Instance" \
    --cluster=my-cluster \
    --cluster-zone=us-central1-b \
    --display-name="My Cluster" \
    --instance-type=development \
    --cluster-storage-type=SSD
```

Example

```bash
gcloud bigtable instances create dev-instance \
    --display-name="Development Instance" \
    --cluster=cluster-1 \
    --cluster-zone=us-central1-b \
    --instance-type=development
```

Check instances

```bash
gcloud bigtable instances list
```

---

# Step 3: Install cbt CLI (if not installed)

Cloud Shell already has it in most cases.

Otherwise

```bash
sudo apt install google-cloud-cli-cbt
```

Check version

```bash
cbt version
```

---

# Step 4: Configure cbt

Create a configuration file.

```bash
cat > ~/.cbtrc <<EOF
project=PROJECT_ID
instance=my-bigtable
EOF
```

Example

```bash
cat > ~/.cbtrc <<EOF
project=my-project-123
instance=dev-instance
EOF
```

Export it

```bash
export CBT_CONFIG=~/.cbtrc
```

Verify

```bash
cbt ls
```

---

# Step 5: Create a Table

```bash
cbt createtable employees
```

Verify

```bash
cbt ls
```

Output

```
employees
```

---

# Step 6: Create Column Families

Create one column family

```bash
cbt createfamily employees personal
```

Create another

```bash
cbt createfamily employees office
```

Create another

```bash
cbt createfamily employees salary
```

Verify

```bash
cbt ls employees
```

or

```bash
cbt lookup employees
```

---

# Step 7: Insert Rows

Syntax

```bash
cbt set TABLE ROW_KEY FAMILY:COLUMN=VALUE
```

Example

```bash
cbt set employees emp001 personal:name=John
```

Add another column

```bash
cbt set employees emp001 personal:age=30
```

Add office details

```bash
cbt set employees emp001 office:city=Delhi
```

Add salary

```bash
cbt set employees emp001 salary:amount=90000
```

---

Insert another employee

```bash
cbt set employees emp002 personal:name=Alice
```

```bash
cbt set employees emp002 personal:age=28
```

```bash
cbt set employees emp002 office:city=Bangalore
```

```bash
cbt set employees emp002 salary:amount=120000
```

---

# Step 8: Read a Row

```bash
cbt lookup employees emp001
```

Output

```
----------------------------------------
emp001

  personal:name @ 2025/07/18
    "John"

  personal:age
    "30"

  office:city
    "Delhi"

  salary:amount
    "90000"
```

---

# Step 9: Scan Entire Table

```bash
cbt read employees
```

---

# Step 10: Scan Limited Rows

```bash
cbt read employees count=2
```

---

# Step 11: Read Rows by Prefix

```bash
cbt read employees prefix=emp
```

---

# Step 12: Delete a Cell

```bash
cbt deletecell employees emp001 personal age
```

---

# Step 13: Delete an Entire Row

```bash
cbt deleterow employees emp001
```

---

# Step 14: Delete a Column Family

```bash
cbt deletefamily employees salary
```

---

# Step 15: Delete a Table

```bash
cbt deletetable employees
```

---

# Step 16: Delete the Bigtable Instance

```bash
gcloud bigtable instances delete dev-instance
```

---

## Complete Example

```bash
gcloud config set project my-project

gcloud bigtable instances create dev-instance \
    --display-name="Development" \
    --cluster=cluster-1 \
    --cluster-zone=us-central1-b \
    --instance-type=development

cat > ~/.cbtrc <<EOF
project=my-project
instance=dev-instance
EOF

export CBT_CONFIG=~/.cbtrc

cbt createtable employees

cbt createfamily employees personal
cbt createfamily employees office

cbt set employees emp001 personal:name=John
cbt set employees emp001 personal:age=30
cbt set employees emp001 office:city=Delhi

cbt set employees emp002 personal:name=Alice
cbt set employees emp002 personal:age=28
cbt set employees emp002 office:city=Bangalore

cbt lookup employees emp001

cbt read employees
```

### Notes

* **Row key**: The unique identifier for each row (e.g., `emp001`, `user#1001`, `order#20260719`).
* **Column family**: Groups related columns together (e.g., `personal`, `office`, `salary`). Column families must be created before storing data in them.
* **Column qualifier**: The specific column within a family (e.g., `name`, `age`, `city`).
* **Cell value**: The data stored at the intersection of a row key and column (e.g., `"John"` or `"90000"`).
