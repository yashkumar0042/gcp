Use **GitHub Personal Access Token (PAT)**. Don’t use your GitHub password.

## Step 1: Create GitHub token

Go to GitHub:

**Profile icon → Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**

For basic Jenkins checkout:

```text
Repository access: Only selected repositories
Permissions:
- Contents: Read-only
```

For private repo, make sure that repo is selected. GitHub documents fine-grained PAT creation under Developer settings. ([GitHub Docs][1])

Copy the token once generated.

---

## Step 2: Add token in Jenkins

Go to Jenkins:

**Dashboard → Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

Fill like this:

```text
Kind: Username with password
Username: your-github-username
Password: paste GitHub token here
ID: github-token
Description: GitHub PAT for Jenkins
```

Jenkins supports storing GitHub personal access tokens in credentials, and the Git plugin supports username/password credentials for HTTPS checkout. ([Jenkins][2])

---

## Step 3: Use credentials in Jenkins Pipeline

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-token',
                    url: 'https://github.com/your-username/your-repo.git'
            }
        }

        stage('Build') {
            steps {
                echo 'Building application...'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
            }
        }
    }
}
```

Replace:

```text
your-username
your-repo
```

with your actual GitHub repo.

---

## For Freestyle Job

Go to job configuration:

```text
Source Code Management → Git
Repository URL: https://github.com/your-username/your-repo.git
Credentials: select github-token
Branch: */main
```

Then save and click **Build Now**.

---

## Common mistake

Don’t put token directly in pipeline like this:

```groovy
https://TOKEN@github.com/user/repo.git
```

That is unsafe. Always store it in **Jenkins Credentials** and use `credentialsId`.

For your basic local Jenkins setup, **Username with password + GitHub PAT** is the easiest method.

[1]: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens?utm_source=chatgpt.com "Managing your personal access tokens"
[2]: https://www.jenkins.io/doc/book/using/using-credentials/?utm_source=chatgpt.com "Using credentials"
