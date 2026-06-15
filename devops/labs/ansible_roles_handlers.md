## Ansible Pipeline: Install Apache using Roles, Handlers, Galaxy

## 1. Project Structure

```text
ansible-apache-pipeline/
├── Jenkinsfile
├── inventory.ini
├── site.yml
├── requirements.yml
└── roles/
    └── apache/
        ├── tasks/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        ├── templates/
        │   └── index.html.j2
        └── defaults/
            └── main.yml
```

---

## 2. Inventory File

### `inventory.ini`

```ini
[webservers]
server1 ansible_host=10.0.0.10 ansible_user=ubuntu
server2 ansible_host=10.0.0.11 ansible_user=ubuntu
```

---

## 3. Main Playbook

### `site.yml`

```yaml
---
- name: Install and configure Apache using role
  hosts: webservers
  become: yes

  roles:
    - apache
```

---

## 4. Role Defaults

### `roles/apache/defaults/main.yml`

```yaml
---
apache_package: apache2
apache_service: apache2
apache_port: 80
```

---

## 5. Role Tasks

### `roles/apache/tasks/main.yml`

```yaml
---
- name: Update apt cache
  apt:
    update_cache: yes

- name: Install Apache package
  apt:
    name: "{{ apache_package }}"
    state: present

- name: Deploy custom index page
  template:
    src: index.html.j2
    dest: /var/www/html/index.html
  notify: Restart Apache

- name: Ensure Apache is running and enabled
  service:
    name: "{{ apache_service }}"
    state: started
    enabled: yes
```

---

## 6. Handler

### `roles/apache/handlers/main.yml`

```yaml
---
- name: Restart Apache
  service:
    name: "{{ apache_service }}"
    state: restarted
```

### What handler does

```text
Handler runs only when notified.

In this case:
If index.html changes,
then Apache restart happens.

If file is already same,
Apache will not restart.
```

---

## 7. Template File

### `roles/apache/templates/index.html.j2`

```html
<html>
  <head>
    <title>Apache Installed by Ansible</title>
  </head>
  <body>
    <h1>Apache installed successfully using Ansible Role</h1>
    <p>Managed by Jenkins + Ansible pipeline</p>
  </body>
</html>
```

---

# 8. Using Ansible Galaxy

Ansible Galaxy is used to install reusable roles from the community or your internal Git repo.

## `requirements.yml`

```yaml
---
roles:
  - name: geerlingguy.apache
```

Install Galaxy roles:

```bash
ansible-galaxy install -r requirements.yml
```

Use Galaxy role in playbook:

```yaml
---
- name: Install Apache using Galaxy role
  hosts: webservers
  become: yes

  roles:
    - geerlingguy.apache
```

---

# 9. Jenkins Pipeline

### `Jenkinsfile`

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/your-user/ansible-apache-pipeline.git'
            }
        }

        stage('Check Ansible Version') {
            steps {
                sh 'ansible --version'
            }
        }

        stage('Install Galaxy Roles') {
            steps {
                sh 'ansible-galaxy install -r requirements.yml'
            }
        }

        stage('Syntax Check') {
            steps {
                sh 'ansible-playbook -i inventory.ini site.yml --syntax-check'
            }
        }

        stage('Ping Servers') {
            steps {
                sh 'ansible all -i inventory.ini -m ping'
            }
        }

        stage('Dry Run') {
            steps {
                sh 'ansible-playbook -i inventory.ini site.yml --check'
            }
        }

        stage('Install Apache') {
            steps {
                sh 'ansible-playbook -i inventory.ini site.yml'
            }
        }
    }
}
```

---

## Final Pipeline Flow

```text
GitHub
  ↓
Jenkins Checkout
  ↓
Install Galaxy Roles
  ↓
Syntax Check
  ↓
Ping Servers
  ↓
Dry Run
  ↓
Run Playbook
  ↓
Apache Installed
```

## Interview Explanation

```text
In this pipeline, Jenkins triggers the Ansible playbook.

The playbook uses an Apache role, which contains tasks, handlers, templates, and variables.

Tasks install Apache and copy the HTML file. If the template changes, it notifies the handler, and the handler restarts Apache.

We also use Ansible Galaxy through requirements.yml to download reusable roles before executing the playbook.
```
