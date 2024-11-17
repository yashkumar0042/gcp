### Column-Level Encryption in BigQuery
Column-level encryption in BigQuery can be implemented using **Client-Side Encryption (CSE)** or **BigQuery's `AEAD.ENCRYPT` and `AEAD.DECRYPT` functions** with **Cloud KMS (Key Management Service)**.

The setup involves:
1. Creating a Cloud KMS Key Ring and Crypto Key.
2. Encrypting sensitive column data using `AEAD.ENCRYPT`.
3. Decrypting data using `AEAD.DECRYPT` when querying.

### **Step 1: Set Up Cloud KMS Key**
1. **Enable Cloud KMS API:**
   ```bash
   gcloud services enable cloudkms.googleapis.com
   ```

2. **Create a Key Ring:**
   ```bash
   gcloud kms keyrings create my-key-ring --location=global
   ```

3. **Create a Crypto Key:**
   ```bash
   gcloud kms keys create my-crypto-key \
       --location=global \
       --keyring=my-key-ring \
       --purpose=encryption
   ```

4. **Grant Access to BigQuery Service Account:**
   ```bash
   gcloud kms keys add-iam-policy-binding my-crypto-key \
       --location=global \
       --keyring=my-key-ring \
       --member=serviceAccount:your-bigquery-service-account@your-project.iam.gserviceaccount.com \
       --role=roles/cloudkms.cryptoKeyEncrypterDecrypter
   ```

### **Step 2: Create a BigQuery Table**
Assume you have a table called `customer_data` with columns `customer_id`, `name`, and `ssn`. We want to encrypt the `ssn` column.

```sql
CREATE OR REPLACE TABLE my_dataset.customer_data (
  customer_id STRING,
  name STRING,
  encrypted_ssn BYTES
);
```

### **Step 3: Encrypt Data Using `AEAD.ENCRYPT`**
Encrypt the `ssn` column before inserting it into the table.

```sql
DECLARE kms_key STRING;
SET kms_key = 'projects/your-project/locations/global/keyRings/my-key-ring/cryptoKeys/my-crypto-key';

INSERT INTO my_dataset.customer_data (customer_id, name, encrypted_ssn)
VALUES (
  '123',
  'John Doe',
  AEAD.ENCRYPT(
    AEAD.KEYSET_CHAIN(
      KMS.KEYSET(kms_key)
    ),
    CAST('123-45-6789' AS BYTES),
    CAST('additional_authenticated_data' AS BYTES)
  )
);
```

### **Step 4: Decrypt Data Using `AEAD.DECRYPT`**
To read the encrypted column, use `AEAD.DECRYPT`.

```sql
DECLARE kms_key STRING;
SET kms_key = 'projects/your-project/locations/global/keyRings/my-key-ring/cryptoKeys/my-crypto-key';

SELECT
  customer_id,
  name,
  CAST(AEAD.DECRYPT(
    AEAD.KEYSET_CHAIN(
      KMS.KEYSET(kms_key)
    ),
    encrypted_ssn,
    CAST('additional_authenticated_data' AS BYTES)
  ) AS STRING) AS ssn
FROM
  my_dataset.customer_data;
```

### **Best Practices**
1. **Use Different Keys for Different Columns**: This adds an extra layer of security.
2. **Access Control**: Ensure that only authorized users have permission to decrypt data.
3. **Audit Logs**: Enable Cloud KMS logging to track key usage.

### **Considerations**
- **Performance**: Encrypting and decrypting data adds overhead. Consider the performance impact, especially on large datasets.
- **Compliance**: This method helps meet compliance requirements like GDPR or HIPAA by protecting sensitive data.

Would you like assistance with setting up this in a real project environment or extending this example?
