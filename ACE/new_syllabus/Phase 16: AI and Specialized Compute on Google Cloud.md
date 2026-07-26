# Phase 16: AI and Specialized Compute on Google Cloud

This phase introduces specialized infrastructure and managed development environments used for machine learning, data science, generative AI, and enterprise application development.

> **Important product-name update:** Google now documents Vertex AI’s broader evolution under **Gemini Enterprise Agent Platform**. Some ACE material, older tutorials, and console screens may still use names such as Vertex AI, Vertex AI Agent Engine, Vertex AI Workbench, or Colab Enterprise. Always understand the underlying capability rather than relying only on the product name. citeturn364846search12turn364846search15turn364846search22

---

# 1. Why specialized compute is needed

Normal CPU-based Compute Engine VMs are suitable for:

- Web servers
- Application servers
- Databases
- CI/CD agents
- Lightweight data processing
- General-purpose development

AI and machine-learning workloads often require enormous numbers of matrix and vector operations. CPUs can perform these calculations, but GPUs and TPUs are designed to execute many mathematical operations in parallel.

Consider an image classification model:

- One image might contain millions of pixel values.
- The model may contain billions of parameters.
- Training might require processing millions of images repeatedly.
- Each training step can involve large matrix multiplications.

A CPU may have a relatively small number of powerful general-purpose cores. A GPU or TPU contains specialized execution units optimized for parallel mathematical operations.

---

# 2. GPU basics

## 2.1 What is a GPU?

A **Graphics Processing Unit**, or GPU, is a processor originally designed for graphics rendering but now widely used for parallel computing.

A GPU contains many smaller processing cores that can execute similar operations simultaneously.

For example:

```text
CPU approach:
Process operation 1
Process operation 2
Process operation 3
Process operation 4

GPU approach:
Process operations 1, 2, 3 and 4 simultaneously
```

Google Cloud provides NVIDIA GPUs through Compute Engine. Some GPU families are attached to general-purpose N1 VMs, while accelerator-optimized machine series such as A2, A3, A4, G2, and G4 include GPUs as part of the machine configuration. Availability depends on the selected region, zone, quota, and machine series. citeturn364846search1turn364846search26

## 2.2 Common GPU use cases

### Machine-learning training

Example:

- Train an image-classification model.
- Fine-tune a language model.
- Train an object-detection model.
- Train recommendation systems.

### Machine-learning inference

Inference means using a trained model to generate predictions.

Examples:

- Detect objects in an uploaded photograph.
- Generate text using a language model.
- Transcribe audio.
- Produce product recommendations.

### Graphics and visualization

Examples:

- 3D rendering
- Computer-aided design
- Video editing
- Game streaming
- Remote virtual workstations

Google Cloud also supports NVIDIA virtual workstation capabilities for visualization workloads that use APIs such as OpenGL, Vulkan, or Direct3D. citeturn364846search18

### Scientific and engineering workloads

Examples:

- Molecular simulation
- Weather modelling
- Computational fluid dynamics
- Genomic processing
- Financial risk simulation

## 2.3 GPU-related terminology

### GPU type

The hardware model, such as an NVIDIA T4, L4, A100, H100, or a newer supported accelerator.

Different GPU types provide different combinations of:

- GPU memory
- Compute performance
- Tensor-processing capability
- Power efficiency
- Cost
- Visualization support

### GPU count

The number of GPUs available to the VM.

For example:

```text
1 GPU
2 GPUs
4 GPUs
8 GPUs
```

The supported GPU count depends on the selected machine type and GPU family.

### GPU memory

GPU memory, often called VRAM, stores:

- Model parameters
- Input batches
- Intermediate tensors
- Training gradients
- Inference cache

A large model might not fit into one GPU’s memory even when the GPU’s processing power is sufficient.

### CUDA

CUDA is NVIDIA’s parallel-computing platform. Frameworks such as TensorFlow, PyTorch, JAX, and many AI libraries use CUDA to run operations on NVIDIA GPUs.

### NVIDIA driver

The operating system requires a compatible NVIDIA driver to communicate with the GPU.

A VM can have a GPU attached but still fail to use it when:

- The driver is missing.
- The CUDA version is incompatible.
- The framework was installed without GPU support.
- The container cannot access the GPU device.

## 2.4 Attached GPU versus accelerator-optimized VM

### Attached GPU

A GPU is added to a compatible general-purpose VM, commonly an N1 VM.

Conceptually:

```text
N1 CPU VM
   +
NVIDIA GPU
```

Advantages:

- Flexible CPU, memory, and GPU combination
- Suitable for older or smaller workloads
- Useful when an N1-compatible GPU matches the requirement

### Accelerator-optimized VM

The machine series is designed around accelerators.

Examples include:

```text
A2
A3
A4
G2
G4
```

Conceptually:

```text
Machine shape designed specifically around GPUs
```

Advantages:

- Better accelerator-to-CPU design
- High-performance networking options
- Better suited for large training and inference workloads
- GPU quantity is generally determined by the selected machine type

## 2.5 GPU quotas and availability

GPU resources are not guaranteed to be available in every zone.

Before deployment, check:

1. Whether the GPU is supported in the region or zone.
2. Whether the project has GPU quota.
3. Whether the selected machine type supports the GPU.
4. Whether the chosen boot image supports driver installation.
5. Whether the resource is currently available.

A quota limit and physical capacity are different:

- **Quota** controls how many resources the project is allowed to request.
- **Capacity** determines whether Google Cloud has that hardware available in the selected zone at that moment.

## 2.6 GPU pricing considerations

A GPU VM can involve charges for:

- GPU hardware
- vCPUs
- Memory
- Persistent disks
- Network traffic
- Premium operating-system images
- Virtual workstation licensing
- Public IPv4 usage

Cost-control strategies include:

- Stop the VM when it is not being used.
- Use Spot VMs for interruptible training.
- Use smaller GPUs for development.
- Use autoscaling for inference.
- Store checkpoints regularly.
- Separate experimentation from production training.
- Use committed resources for predictable long-term workloads.

---

# 3. TPU basics

## 3.1 What is a TPU?

A **Tensor Processing Unit**, or TPU, is a Google-designed application-specific integrated circuit optimized for machine-learning workloads.

TPUs are particularly effective at large tensor and matrix operations used in deep-learning models. Cloud TPU can be used through services such as Compute Engine, GKE and managed AI platforms. citeturn364846search4turn364846search20

A TPU is not simply a faster CPU. It is specialized hardware designed around machine-learning calculations.

## 3.2 Why it is called a Tensor Processing Unit

A tensor is a multidimensional collection of numbers.

Examples:

```text
Scalar:      5
Vector:      [5, 10, 15]
Matrix:      [[1, 2], [3, 4]]
Tensor:      Higher-dimensional numeric structure
```

Machine-learning models frequently manipulate tensors. TPUs are designed to process these operations efficiently.

## 3.3 Common TPU use cases

TPUs are commonly used for:

- Large TensorFlow models
- JAX workloads
- Large-scale model training
- Transformer training
- Image and language models
- High-throughput batch inference
- Distributed machine-learning workloads

Example:

A research team wants to train a transformer using a very large dataset. The training code is built with JAX and can distribute computation across many TPU chips. A TPU slice can provide efficient scaling for this workload.

## 3.4 TPU architecture concepts

### TPU chip

The basic accelerator device.

### TPU VM

A VM environment that gives users direct access to the TPU host and accelerator.

You connect to the TPU VM, install software, and execute the training program.

```bash
gcloud compute tpus tpu-vm ssh TPU_NAME \
    --zone=ZONE
```

Google’s current documentation uses the TPU VM architecture for creating and managing Cloud TPU resources. citeturn364846search3turn364846search11

### TPU slice

A group of TPU chips allocated together.

A slice might contain:

- A single host
- Multiple hosts
- Multiple interconnected TPU chips

Larger slices are used for distributed training.

### TPU topology

Topology describes how TPU chips are interconnected.

A model must be written and configured correctly to distribute calculations across the topology.

### Runtime version

A TPU VM runtime version includes the software environment required to use a framework such as:

- TensorFlow
- JAX
- PyTorch/XLA

The runtime version must be compatible with the application.

## 3.5 TPU generations

Cloud TPU hardware is available in different generations. A generation may be optimized for a particular balance of:

- Training performance
- Inference performance
- Memory
- Cost
- Scale
- Energy efficiency

Do not memorize only a generation number for certification preparation. Focus on:

- TPU is Google-designed specialized ML hardware.
- TPU is suitable for supported, highly parallel tensor workloads.
- Framework and code compatibility matter.
- Availability is region- and zone-dependent.
- Larger TPU slices support distributed workloads.

## 3.6 TPU Spot and queued resources

For fault-tolerant workloads, TPU Spot VMs can reduce cost but may be interrupted.

The application should therefore:

- Save checkpoints.
- Resume from the latest checkpoint.
- Store model artifacts in Cloud Storage.
- Avoid keeping the only model state on the TPU VM.
- Make training idempotent where possible.

For large accelerator requests, queued or flexible provisioning mechanisms can be used when immediate capacity is not essential. citeturn364846search29turn364846search40

---

# 4. GPU versus TPU

## 4.1 High-level comparison

| Area | GPU | TPU |
|---|---|---|
| Manufacturer | Commonly NVIDIA on Google Cloud | Designed by Google |
| General purpose | More flexible | More specialized |
| Framework ecosystem | Very broad | Best with supported ML frameworks |
| CUDA support | Yes, for NVIDIA GPUs | No |
| Graphics workloads | Supported | Not intended for graphics |
| ML training | Excellent | Excellent for compatible workloads |
| ML inference | Excellent | Excellent for suitable tensor workloads |
| Custom CUDA code | Supported | Not supported |
| Portability | Available across many clouds and on-premises environments | Primarily Google’s TPU ecosystem |
| Code changes | Often minimal for CUDA-enabled frameworks | May require TPU-aware code and distribution strategy |
| Best fit | Flexible ML, graphics, scientific computation | Large, optimized tensor-based ML workloads |

## 4.2 Use a GPU when

Choose a GPU when:

- The application uses CUDA.
- You need PyTorch with standard GPU support.
- You are running graphical or visualization software.
- You need a widely portable accelerator environment.
- The workload uses GPU-specific libraries.
- You need smaller-scale experimentation.
- The model is not optimized or tested for TPU execution.
- You need to use a vendor-provided GPU container.
- You are deploying GPU inference servers such as NVIDIA Triton.

### Example

A media company runs:

- Video transcoding
- Object detection
- Image enhancement
- 3D rendering

A GPU is appropriate because the workload includes both AI and graphics-processing libraries.

## 4.3 Use a TPU when

Choose a TPU when:

- The model is built using a TPU-supported framework.
- Training involves large matrix operations.
- The workload can scale across multiple TPU chips.
- You are using TensorFlow or JAX extensively.
- The model architecture has been validated on TPU.
- Large training throughput is more important than software portability.
- The team understands distributed TPU training.

### Example

A research team trains a large transformer using JAX. The workload is already designed to distribute tensors across a TPU topology. TPU is likely an appropriate choice.

## 4.4 Use a CPU when

Do not assume every AI application needs an accelerator.

A CPU can be sufficient when:

- The model is small.
- Request traffic is low.
- Inference latency is acceptable.
- The application runs occasional predictions.
- Data preprocessing is the primary task.
- The model does not support accelerators.
- GPU startup and idle cost would be wasteful.

### Example

A business executes a small fraud-detection model once every hour against a few hundred transactions. A CPU-based Cloud Run service may be more economical than a dedicated accelerator.

## 4.5 Decision process

Use this sequence:

```text
Does the workload require graphics or CUDA?
        |
       Yes
        |
       GPU
```

```text
Is the workload a large supported tensor-based ML workload?
        |
       Yes
        |
  Is it validated for TPU?
      /       \
    Yes        No
    TPU        GPU
```

```text
Is the model small with low traffic?
        |
       Yes
        |
       CPU
```

---

# 5. Attaching a GPU to a Compute Engine VM

There are two common scenarios:

1. Create a new VM with a GPU.
2. Add or modify a GPU on an existing compatible VM.

Google Cloud supports creating GPU VMs through the console, Google Cloud CLI, and APIs. Adding or changing GPUs can require stopping the VM, and the selected machine type must support the requested GPU. citeturn364846search9turn364846search17

---

# Lab 1: Create a Compute Engine VM with an attached GPU

## Lab objective

Create a Linux VM with:

- An N1 machine type
- One NVIDIA GPU
- An Ubuntu or Deep Learning VM image
- NVIDIA driver support

## Prerequisites

Enable the Compute Engine API:

```bash
gcloud services enable compute.googleapis.com
```

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export ZONE="us-central1-a"
export VM_NAME="gpu-lab-vm"
export GPU_TYPE="nvidia-tesla-t4"
export MACHINE_TYPE="n1-standard-4"
```

Check the configured project:

```bash
gcloud config set project "$PROJECT_ID"
```

Check available accelerator types:

```bash
gcloud compute accelerator-types list \
    --filter="zone:($ZONE)"
```

Check project quotas:

```bash
gcloud compute project-info describe \
    --project="$PROJECT_ID"
```

## GUI steps

1. Open **Google Cloud Console**.
2. Go to **Compute Engine → VM instances**.
3. Click **Create instance**.
4. Enter the VM name:

```text
gpu-lab-vm
```

5. Select a region and zone where the required GPU is available.
6. In **Machine configuration**, choose the appropriate machine family.
7. Select an N1 machine type such as:

```text
n1-standard-4
```

8. Open the **GPU** or accelerator section.
9. Click **Add GPU**.
10. Select:
    - GPU type: an available NVIDIA GPU
    - Number of GPUs: `1`
11. Select the boot disk.
12. For the simplest lab, choose a Google-provided Deep Learning VM image that supports NVIDIA drivers.
13. Alternatively, select Ubuntu and install the NVIDIA driver after VM creation.
14. Configure disk size.
15. Keep the default VPC and subnet for the lab.
16. Allow required access or use IAP/SSH.
17. Click **Create**.
18. After creation, click **SSH**.
19. Verify the GPU:

```bash
nvidia-smi
```

Expected information includes:

- NVIDIA driver version
- GPU model
- GPU memory
- Running GPU processes

## CLI method using an attached GPU

```bash
gcloud compute instances create "$VM_NAME" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --accelerator="type=$GPU_TYPE,count=1" \
    --maintenance-policy=TERMINATE \
    --restart-on-failure \
    --boot-disk-size=50GB \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud
```

### Why `--maintenance-policy=TERMINATE`?

GPU VMs generally cannot live-migrate like ordinary Compute Engine VMs. During host maintenance, the instance is terminated rather than transparently migrated.

### Connect to the VM

```bash
gcloud compute ssh "$VM_NAME" \
    --zone="$ZONE"
```

### Install the NVIDIA driver

The exact driver installation procedure depends on:

- OS image
- Kernel version
- GPU type
- CUDA requirement

For a learning lab, using a supported Deep Learning VM image can reduce driver-management complexity.

After installation, verify:

```bash
nvidia-smi
```

### Basic Python GPU check with PyTorch

```bash
python3 -m venv ~/gpu-env
source ~/gpu-env/bin/activate

pip install --upgrade pip
pip install torch
```

Create a file:

```bash
cat > gpu_test.py <<'PY'
import torch

print("PyTorch version:", torch.__version__)
print("CUDA available:", torch.cuda.is_available())

if torch.cuda.is_available():
    print("GPU count:", torch.cuda.device_count())
    print("GPU name:", torch.cuda.get_device_name(0))

    a = torch.rand(2000, 2000, device="cuda")
    b = torch.rand(2000, 2000, device="cuda")
    c = torch.matmul(a, b)

    print("Matrix multiplication completed on:", c.device)
else:
    print("GPU is not available to PyTorch.")
PY
```

Run:

```bash
python gpu_test.py
```

## Troubleshooting

### `nvidia-smi: command not found`

The driver is not installed or the utility is unavailable.

### `NVIDIA-SMI has failed`

Possible reasons:

- Driver mismatch
- Kernel update
- Driver installation failure
- Unsupported image

### VM creation returns a quota error

Request GPU quota for the selected region.

### Resource unavailable

Try:

- Another zone
- Another supported GPU type
- A reservation
- A Spot or standard provisioning model appropriate for the workload
- A different machine series

## Cleanup

```bash
gcloud compute instances delete "$VM_NAME" \
    --zone="$ZONE" \
    --quiet
```

---

# Lab 2: Stop a VM and add a GPU

This lab applies only to a compatible VM and machine family.

## GUI steps

1. Go to **Compute Engine → VM instances**.
2. Select the VM.
3. Click **Stop**.
4. Wait until its status is **Terminated**.
5. Click the VM name.
6. Click **Edit**.
7. Find the GPU or accelerator section.
8. Click **Add GPU**.
9. Choose a supported GPU and count.
10. Confirm the maintenance policy.
11. Save the changes.
12. Start the VM.
13. Connect using SSH.
14. Install or verify the NVIDIA driver:

```bash
nvidia-smi
```

## CLI steps

Stop the VM:

```bash
gcloud compute instances stop gpu-lab-vm \
    --zone=us-central1-a
```

Attach or change the accelerator configuration using the currently supported Compute Engine update operation for the selected machine type.

Because GPU modification rules vary by machine series, first inspect the VM:

```bash
gcloud compute instances describe gpu-lab-vm \
    --zone=us-central1-a
```

After updating, start it:

```bash
gcloud compute instances start gpu-lab-vm \
    --zone=us-central1-a
```

For production automation, creating a replacement VM from an instance template is generally safer than making repeated manual hardware changes.

---

# 6. Creating and accessing a TPU VM

Unlike a general-purpose VM with an attached GPU, Cloud TPU is normally provisioned as a TPU VM resource.

---

# Lab 3: Create a Cloud TPU VM

## Objective

Create a small TPU VM, connect to it and run a basic Python test.

TPU types, runtime versions, and regional capacity change over time. Use the following commands to list currently available options before creating the resource.

## Enable the TPU API

```bash
gcloud services enable tpu.googleapis.com
```

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export TPU_NAME="ace-tpu-lab"
export ZONE="us-central2-b"
export ACCELERATOR_TYPE="v5litepod-8"
export RUNTIME_VERSION="tpu-ubuntu2204-base"
```

Confirm supported accelerator types:

```bash
gcloud compute tpus tpu-vm accelerator-types list \
    --zone="$ZONE"
```

Confirm supported runtime versions:

```bash
gcloud compute tpus tpu-vm versions list \
    --zone="$ZONE"
```

## GUI steps

1. Open Google Cloud Console.
2. Search for **TPUs**.
3. Open the **Cloud TPU** page.
4. Click **Create TPU**.
5. Enter:

```text
Name: ace-tpu-lab
```

6. Select a supported zone.
7. Choose an accelerator type.
8. Choose a TPU software or runtime version.
9. Select the network and subnet.
10. Configure public IP access according to the lab requirement.
11. Click **Create**.
12. Wait for the TPU VM to become ready.
13. Use the provided SSH option or connect through Cloud Shell.

The current Cloud TPU console workflow creates a TPU by selecting its name, zone, accelerator type, runtime, and networking configuration. citeturn364846search3

## CLI steps

```bash
gcloud compute tpus tpu-vm create "$TPU_NAME" \
    --zone="$ZONE" \
    --accelerator-type="$ACCELERATOR_TYPE" \
    --version="$RUNTIME_VERSION"
```

Connect:

```bash
gcloud compute tpus tpu-vm ssh "$TPU_NAME" \
    --zone="$ZONE"
```

## Test TPU access

The exact Python packages depend on the selected runtime.

A simple JAX-style verification can look like:

```python
import jax

print("JAX devices:")
for device in jax.devices():
    print(device)
```

Save and run:

```bash
cat > tpu_test.py <<'PY'
import jax
import jax.numpy as jnp

print("Available devices:")
for device in jax.devices():
    print(device)

a = jnp.ones((1000, 1000))
b = jnp.ones((1000, 1000))
c = a @ b

print("Result shape:", c.shape)
print("Computation completed.")
PY

python3 tpu_test.py
```

## List TPU VMs

```bash
gcloud compute tpus tpu-vm list \
    --zone="$ZONE"
```

## Describe the TPU

```bash
gcloud compute tpus tpu-vm describe "$TPU_NAME" \
    --zone="$ZONE"
```

## Stop the TPU VM

```bash
gcloud compute tpus tpu-vm stop "$TPU_NAME" \
    --zone="$ZONE"
```

## Start the TPU VM

```bash
gcloud compute tpus tpu-vm start "$TPU_NAME" \
    --zone="$ZONE"
```

## Delete the TPU VM

```bash
gcloud compute tpus tpu-vm delete "$TPU_NAME" \
    --zone="$ZONE" \
    --quiet
```

## Important exam and operational points

- A TPU is specialized ML hardware.
- Check accelerator availability by zone.
- Use TPU VM commands to manage the resource.
- Select compatible runtime and framework versions.
- Use Cloud Storage for datasets and checkpoints.
- Delete TPU resources after a lab to prevent unnecessary charges.
- Use private connectivity where required.
- For a TPU VM without a public IP, configure appropriate subnet access, Private Google Access, IAM and potentially IAP-based connectivity. citeturn364846search49

---

# 7. AI agents and Agent Runtime

## 7.1 What is an AI agent?

An AI agent is more than a text-generation model.

A basic LLM application may work as follows:

```text
User prompt → Model → Text response
```

An agent can perform a multi-step workflow:

```text
User request
    ↓
Understand objective
    ↓
Create a plan
    ↓
Select a tool
    ↓
Call an API or data source
    ↓
Observe the result
    ↓
Take another action
    ↓
Return final response
```

Example:

A user asks:

> “Check our inventory and create a replenishment request for products that will run out this week.”

The agent might:

1. Query BigQuery for inventory.
2. Call a demand-forecasting model.
3. Identify low-stock products.
4. Call an internal procurement API.
5. Write an audit record.
6. Return a summary.

Gemini Enterprise Agent Platform is positioned as a unified environment for building, deploying, governing and optimizing enterprise-grade agents and model-based solutions. citeturn364846search22

## 7.2 Core parts of an agent

### Model

The language or reasoning model used by the agent.

Example:

```text
Gemini model
```

### Instructions

Rules describing what the agent should do.

Example:

```text
You are an inventory assistant.
Only create orders after validating current stock.
Never order more than the approved weekly limit.
```

### Tools

Functions or services the agent can invoke.

Examples:

- BigQuery
- Cloud SQL
- REST APIs
- Search systems
- Cloud Functions
- Internal applications
- Ticketing systems

### Memory or state

Information maintained across steps or conversations.

### Context

Data supplied to the model for a particular request.

### Orchestration

The logic deciding:

- Which step runs next
- Which tool is called
- How failures are retried
- When the agent stops
- When human approval is required

### Guardrails

Controls restricting agent behaviour.

Examples:

- Do not access restricted datasets.
- Require approval before issuing a refund.
- Mask personally identifiable information.
- Allow only read operations in production.
- Reject requests outside the assigned business domain.

### Evaluation

Testing whether the agent:

- Produces correct answers
- Chooses the correct tool
- Follows instructions
- Avoids hallucinations
- Completes the task
- Maintains safe behaviour

---

# 8. Agent Runtime on Gemini Enterprise Agent Platform

## 8.1 What is Agent Runtime?

Agent Runtime is the managed environment used to host and execute agents remotely.

Instead of manually managing:

- VM provisioning
- Agent process startup
- Runtime scaling
- Request routing
- Deployment infrastructure
- Runtime lifecycle

the developer deploys an agent to a managed service.

Google documents support for multiple agent frameworks, including managed integrations and custom deployment templates. Current examples include Agent Development Kit, LangChain, LangGraph, AG2, LlamaIndex, CrewAI, and custom frameworks, although the support level differs by framework. citeturn364846search6

## 8.2 Agent Runtime benefits

### Managed deployment

Developers focus on agent logic rather than maintaining application servers.

### Remote access

Applications can invoke the deployed agent through supported SDKs or APIs.

### Scalability

The runtime can handle production requests without the developer manually managing individual VMs.

### Identity

A deployed agent can run under a service account.

This allows IAM to control access to:

- BigQuery
- Cloud Storage
- Secret Manager
- Other APIs
- Internal services

### Observability

Production agents should emit:

- Request logs
- Tool-call logs
- Latency metrics
- Error logs
- Token and model usage
- Evaluation results

### Governance

Enterprise deployment requires:

- IAM
- Auditability
- Data controls
- Approved models
- Tool restrictions
- Environment separation

## 8.3 Local agent versus deployed agent

### Local agent

Runs in:

- Laptop
- Cloud Shell
- Workbench
- Colab notebook
- Local Python environment

Best for:

- Development
- Testing
- Debugging
- Prompt experimentation

### Deployed agent

Runs in Agent Runtime.

Best for:

- Shared applications
- Production usage
- API integration
- Managed scaling
- Central governance

The Agent Platform SDK aims to make querying similar whether an agent is running locally or remotely, though the remote agent requires deployment and authentication. citeturn340154search8

---

# Lab 4: Build and deploy a simple agent

The exact SDK surface is evolving quickly. The following lab shows the architecture and deployment workflow. Check the current quickstart before copying package versions into a production pipeline. Google’s current quickstarts use the Agent Platform SDK together with a selected framework such as ADK or LangChain. citeturn340154search21turn340154search23turn340154search25

## Objective

Build an agent that answers questions about cloud architecture and deploy it to Agent Runtime.

## Prerequisites

- Google Cloud project with billing
- Required Agent Platform APIs enabled
- Access to supported Gemini models
- Python 3.10 or later
- IAM permissions to create and invoke agent deployments
- Application Default Credentials

## Initial CLI setup

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="us-central1"
export AGENT_NAME="cloud-architecture-agent"

gcloud config set project "$PROJECT_ID"
```

Authenticate application code:

```bash
gcloud auth application-default login
```

Enable commonly required services:

```bash
gcloud services enable \
    aiplatform.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    serviceusage.googleapis.com
```

Create a project directory:

```bash
mkdir -p ~/agent-runtime-lab
cd ~/agent-runtime-lab
```

Create a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate

pip install --upgrade pip
```

Install the current Agent Platform SDK and chosen framework according to the current quickstart.

For example, the current LangChain quickstart documents a package pattern similar to:

```bash
pip install --upgrade \
    "google-cloud-aiplatform[agent_engines,langchain]>=1.112"
```

## Create agent logic

A conceptual example:

```python
import os

PROJECT_ID = os.environ["PROJECT_ID"]
REGION = os.environ.get("REGION", "us-central1")

SYSTEM_INSTRUCTION = """
You are a Google Cloud architecture assistant.

Responsibilities:
1. Explain Google Cloud services clearly.
2. Prefer managed services when they satisfy the requirement.
3. Identify security, availability and cost considerations.
4. Never claim to have changed a cloud resource unless a tool confirms it.
5. Ask for human approval before destructive operations.
"""

def answer_question(question: str) -> str:
    """
    Replace this placeholder with the currently supported
    Agent Platform SDK and Gemini model invocation.
    """
    return f"Received architecture question: {question}"
```

The actual deployment object depends on whether you use:

- Agent Development Kit
- LangChain
- LangGraph
- Agent Platform managed agent configuration
- A custom framework template

## Deployment workflow

Conceptually, deployment performs the following:

```text
Source code
   ↓
Dependency specification
   ↓
Agent object
   ↓
Agent Platform SDK
   ↓
Agent Runtime deployment
   ↓
Remote resource name
```

A typical SDK deployment includes:

- Agent display name
- Source packages
- Python requirements
- Region
- Runtime configuration
- Service account
- Environment variables

Google documents several deployment methods, including framework-specific SDK deployment and source-based deployment. Deploying the agent makes it remotely available to handle requests. citeturn364846search41turn340154search11

## GUI deployment and management

Depending on the selected framework and console workflow:

1. Open **Gemini Enterprise Agent Platform**.
2. Go to **Agent Platform Deployments**.
3. Select or create an agent deployment.
4. Choose the source or agent framework.
5. Select the region.
6. Configure the runtime service account.
7. Configure required environment variables.
8. Configure networking if private resources must be accessed.
9. Deploy the agent.
10. Open the deployment details.
11. Review status, logs, resource information and supported invocation details.

Google’s current management documentation directs users to the Agent Platform Deployments page for viewing and managing deployed agents. citeturn340154search17turn340154search30

## Invoke the deployed agent

A remote invocation commonly requires an OAuth access token.

Retrieve a token:

```bash
gcloud auth print-access-token
```

A REST request follows this general pattern:

```bash
curl \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -X POST \
  "AGENT_RUNTIME_ENDPOINT" \
  -d '{
    "input": {
      "text": "When should I use Cloud Run instead of GKE?"
    }
  }'
```

Use the endpoint and request schema displayed by the deployed agent resource because API paths differ by deployment method and framework.

## Production recommendations

- Use a dedicated service account.
- Avoid service-account keys.
- Grant least-privilege roles.
- Store credentials in Secret Manager.
- Separate dev, staging and production agents.
- Restrict destructive tools.
- Add human approval for high-risk operations.
- Log tool calls.
- Add evaluations to CI/CD.
- Test prompt-injection resistance.
- Set budgets and quotas.
- Validate outputs before invoking downstream systems.

---

# 9. Gemini Enterprise Agent Platform Workbench

## 9.1 What is Workbench?

Gemini Enterprise Agent Platform Workbench provides managed Jupyter-based development environments for data science and ML workflows.

A Workbench instance allows a user to interact with:

- Python
- JupyterLab
- Gemini Enterprise Agent Platform
- BigQuery
- Cloud Storage
- Training services
- Models and endpoints
- Other Google Cloud APIs

Google currently describes Workbench instances as Jupyter notebook-based environments for the full data-science workflow. citeturn364846search24

## 9.2 Workbench use cases

- Exploratory data analysis
- Feature engineering
- Model experimentation
- Training-script development
- BigQuery analysis
- Agent prototyping
- Model evaluation
- Visualization
- Generative AI experiments

## 9.3 Workbench components

A Workbench environment normally involves:

- A managed notebook interface
- Compute resources
- Persistent storage
- Service-account identity
- Network configuration
- Installed Python packages
- Optional GPU acceleration
- IAM-controlled access

## 9.4 Managed notebook versus local Jupyter

| Area | Local Jupyter | Workbench |
|---|---|---|
| Installation | User manages it | Managed cloud environment |
| Compute | Laptop or local server | Google Cloud compute |
| Identity | Local credentials | IAM and service account |
| Data access | Requires manual setup | Integrated with Google Cloud |
| Collaboration | Limited | Cloud-based sharing and access |
| GPU | Requires local hardware | Can use cloud accelerators |
| Security controls | Device dependent | Central IAM and networking |
| Scalability | Limited | Cloud-based resources |

## 9.5 Workbench versus BigQuery notebook

Use **Workbench** when:

- The workload involves broad ML development.
- You need flexible Python packages.
- You need local files and custom environments.
- You require direct access to managed AI services.
- You need an environment resembling a data-science VM.

Use a **BigQuery notebook** when:

- The workflow is mainly centered on BigQuery data.
- SQL and Python need to be combined.
- Analysts want notebook access inside BigQuery Studio.
- BigQuery DataFrames or Spark integration is central.

---

# Lab 5: Create a Workbench instance

## GUI steps

1. Open Google Cloud Console.
2. Search for **Gemini Enterprise Agent Platform Workbench**.
3. Open the **Instances** page.
4. Click **Create instance**.
5. Enter an instance name:

```text
ace-workbench-lab
```

6. Select a region and zone.
7. Choose the machine type.
8. For a low-cost lab, use a modest general-purpose machine.
9. Optionally configure:
   - GPU
   - Boot disk
   - Data disk
   - Idle shutdown
   - Service account
   - Network
   - Subnet
   - Public IP
10. Select the required IAM and security options.
11. Click **Create**.
12. When the instance is ready, click **Open JupyterLab**.
13. Create a Python notebook.
14. Run:

```python
import sys
import platform

print("Python:", sys.version)
print("Platform:", platform.platform())
```

## Query BigQuery from Workbench

Install the client if required:

```python
!pip install --quiet --upgrade google-cloud-bigquery
```

Run:

```python
from google.cloud import bigquery

client = bigquery.Client()

query = """
SELECT
  name,
  SUM(number) AS total
FROM
  `bigquery-public-data.usa_names.usa_1910_current`
WHERE
  year BETWEEN 2000 AND 2010
GROUP BY
  name
ORDER BY
  total DESC
LIMIT 10
"""

result = client.query(query).to_dataframe()
result
```

Workbench supports querying BigQuery from its JupyterLab environment using Google Cloud integrations and appropriate IAM permissions. citeturn364846search53

## Important IAM roles

The user or Workbench service account might require:

- BigQuery Job User
- BigQuery Data Viewer
- Storage Object Viewer
- Agent Platform User
- Service Account User

Grant only roles required for the task.

## Cleanup

Delete the Workbench instance through:

```text
Gemini Enterprise Agent Platform
→ Workbench
→ Instances
→ Select instance
→ Delete
```

Stopping an instance may preserve its disks and continue generating storage charges. Delete resources that are no longer required.

---

# 10. BigQuery notebooks

## 10.1 What is a BigQuery notebook?

BigQuery notebooks are Colab Enterprise-powered notebooks integrated into BigQuery Studio.

They allow users to combine:

- SQL
- Python
- Markdown
- Charts
- BigQuery DataFrames
- BigQuery data
- Machine-learning workflows
- Spark sessions

Google describes these notebooks as an end-to-end data-science and ML environment that combines SQL, Python, rich text and visualizations within BigQuery. citeturn364846search33

## 10.2 Why use BigQuery notebooks?

A normal SQL editor is useful for queries such as:

```sql
SELECT *
FROM dataset.table;
```

A notebook supports a complete analysis:

```text
Markdown explanation
        ↓
SQL query
        ↓
Python transformation
        ↓
Visualization
        ↓
Machine-learning model
        ↓
Written conclusion
```

## 10.3 BigQuery notebook use cases

- Data exploration
- Data-quality checks
- Feature engineering
- BigQuery ML experimentation
- Python analytics
- BigQuery DataFrames
- Scheduled analysis
- PySpark execution
- Sharing reproducible analysis

## 10.4 BigQuery DataFrames

BigQuery DataFrames provides a pandas-like Python API that pushes supported operations to BigQuery.

Conceptually:

```python
df = bpd.read_gbq("project.dataset.table")
result = df.groupby("category").sales.sum()
```

Instead of downloading the entire dataset to the notebook, computation can be executed in BigQuery.

This is useful when data is too large for notebook memory.

## 10.5 Notebook access and security

Notebook permissions and data permissions are separate.

A user might be able to open a notebook but still lack permission to query its datasets.

Users also need appropriate runtime and BigQuery permissions to execute notebooks. Saved notebook output can expose data to notebook viewers, so output-sharing settings must be handled carefully. citeturn340154search1

---

# Lab 6: Create and run a BigQuery notebook

## GUI steps

1. Open Google Cloud Console.
2. Go to **BigQuery**.
3. In BigQuery Studio, click the arrow beside **SQL query**.
4. Select:

```text
Notebook → Empty notebook
```

Alternatively, choose a notebook template from the gallery.

5. Select a region.
6. Give the notebook a name:

```text
ace-bigquery-notebook
```

7. Connect or create a runtime.
8. Add a Markdown cell:

```markdown
# BigQuery Public Dataset Analysis

This notebook analyzes popular names from the US names public dataset.
```

9. Add a Python cell:

```python
from google.cloud import bigquery

client = bigquery.Client()
```

10. Add another Python cell:

```python
query = """
SELECT
  name,
  gender,
  SUM(number) AS total_count
FROM
  `bigquery-public-data.usa_names.usa_1910_current`
WHERE
  year BETWEEN 2015 AND 2020
GROUP BY
  name,
  gender
ORDER BY
  total_count DESC
LIMIT 20
"""

df = client.query(query).to_dataframe()
df
```

11. Create a chart:

```python
df.plot(
    kind="bar",
    x="name",
    y="total_count",
    figsize=(12, 6),
    title="Most Popular Names: 2015-2020"
)
```

12. Save the notebook.
13. Review notebook version history.
14. Share it only with authorised users.

The notebook gallery also includes templates, such as examples based on the BigQuery public penguins dataset. citeturn340154search1turn340154search22

## SQL cell example

Depending on the notebook interface, SQL can be executed using a SQL cell or a notebook magic:

```sql
SELECT
  state,
  SUM(number) AS births
FROM
  `bigquery-public-data.usa_names.usa_1910_current`
WHERE
  year = 2020
GROUP BY
  state
ORDER BY
  births DESC;
```

## BigQuery DataFrames example

```python
import bigframes.pandas as bpd

names = bpd.read_gbq(
    """
    SELECT name, gender, number, year
    FROM `bigquery-public-data.usa_names.usa_1910_current`
    WHERE year >= 2015
    """
)

summary = (
    names.groupby(["name", "gender"])["number"]
    .sum()
    .sort_values(ascending=False)
)

summary.head(20)
```

## CLI considerations

BigQuery notebooks are primarily created and managed through the BigQuery Studio interface and underlying code-asset services. For command-line automation, a practical approach is to:

1. Create an `.ipynb` file locally.
2. Store it in source control or Cloud Storage.
3. Upload it through BigQuery Studio.
4. Use APIs or infrastructure automation where supported.
5. Keep SQL and Python dependencies version-controlled separately.

A minimal local notebook can be generated using Python:

```bash
pip install nbformat
```

```bash
cat > create_notebook.py <<'PY'
import nbformat as nbf

notebook = nbf.v4.new_notebook()

notebook.cells = [
    nbf.v4.new_markdown_cell(
        "# ACE BigQuery Notebook\n"
        "Analyze a BigQuery public dataset."
    ),
    nbf.v4.new_code_cell(
        "from google.cloud import bigquery\n"
        "client = bigquery.Client()\n"
        "print('BigQuery client created')"
    ),
    nbf.v4.new_code_cell(
        'query = """\n'
        "SELECT name, SUM(number) AS total\n"
        "FROM `bigquery-public-data.usa_names.usa_1910_current`\n"
        "GROUP BY name\n"
        "ORDER BY total DESC\n"
        "LIMIT 10\n"
        '"""\n'
        "df = client.query(query).to_dataframe()\n"
        "df"
    ),
]

with open("ace_bigquery_lab.ipynb", "w", encoding="utf-8") as file:
    nbf.write(notebook, file)

print("Created ace_bigquery_lab.ipynb")
PY

python create_notebook.py
```

Then upload `ace_bigquery_lab.ipynb`:

```text
BigQuery
→ Explorer
→ Notebooks
→ Upload to Notebooks
```

BigQuery Studio supports uploading a local notebook and associating it with a selected region. citeturn340154search1

---

# 11. Cloud Workstations

## 11.1 What is Cloud Workstations?

Cloud Workstations provides managed, secure, customizable development environments running on Google Cloud.

Instead of every developer configuring a laptop independently, a platform team creates a standard workstation configuration.

Developers receive consistent environments containing:

- Approved IDE
- Required language runtimes
- Security tools
- Corporate certificates
- Repository tools
- Cloud CLI
- Dependencies
- Network access
- Service account configuration

Google describes Cloud Workstations as preconfigured, customizable and secure managed development environments. citeturn340154search7

## 11.2 Cloud Workstations architecture

```text
Workstation cluster
        ↓
Workstation configuration
        ↓
Individual workstation
        ↓
Developer launches IDE
```

### Workstation cluster

The regional management layer for workstations.

A Cloud Workstations cluster is not a GKE cluster. citeturn340154search18

### Workstation configuration

A template defining:

- Machine type
- Container image
- Boot disk
- Persistent storage
- Idle timeout
- Running timeout
- Network
- Service account
- Environment variables
- Security settings
- Optional accelerators

Changes to the configuration are reflected when associated workstations restart according to the service’s update behaviour. citeturn340154search0

### Workstation

An individual developer environment created from the configuration.

### Workstation image

The container image containing:

- Browser-based IDE
- CLI tools
- Language runtimes
- Extensions
- Corporate development tools

## 11.3 Benefits

### Consistency

Every developer receives the same environment.

### Security

Source code can remain in the cloud environment rather than on unmanaged local devices.

### Faster onboarding

A new developer can launch a ready-to-use environment without spending days installing tools.

### Central updates

Administrators update the workstation configuration or container image.

### Private access

Workstations can be configured without public IP addresses and can access private resources through a VPC.

### Cost controls

Administrators can configure:

- Idle timeout
- Running timeout
- Machine size
- Persistent storage
- Resource pools

## 11.4 Cloud Workstations versus Workbench

| Area | Cloud Workstations | Agent Platform Workbench |
|---|---|---|
| Main user | Software developer | Data scientist or ML engineer |
| Primary interface | Browser IDE/Code OSS/custom IDE | JupyterLab |
| Main workload | Application development | Data science and ML |
| Standardization | Strong developer environment templating | Notebook-centric environment |
| Custom image | Yes | Environment customization supported |
| Persistent developer disk | Yes | Notebook storage and instance disks |
| GPU support | Configuration dependent | Common ML use case |
| Typical task | Build Spring Boot service | Train or evaluate model |

## 11.5 Cloud Workstations versus local development

Cloud Workstations is useful when:

- Developers need private VPC access.
- Source code must not reside on laptops.
- Development environments need centralized patching.
- Contractors require controlled access.
- Teams need reproducible environments.
- Developers use low-powered local devices.
- Security requires audit and IAM-based access.

Local development may remain suitable when:

- Offline access is required.
- The project is very small.
- Cloud connectivity is unreliable.
- No protected cloud resources are involved.
- The cost of managed environments is not justified.

---

# Lab 7: Create a Cloud Workstation

## Objective

Create:

1. A workstation cluster
2. A workstation configuration
3. A developer workstation
4. Launch the browser-based editor

## Enable the API

```bash
gcloud services enable workstations.googleapis.com
```

Set variables:

```bash
export PROJECT_ID="$(gcloud config get-value project)"
export REGION="us-central1"
export CLUSTER="ace-workstation-cluster"
export CONFIG="ace-dev-config"
export WORKSTATION="ace-developer-workstation"
```

## GUI steps

### Part A: Create a cluster

1. Open **Cloud Workstations**.
2. Go to **Workstation clusters**.
3. Click **Create**.
4. Enter:

```text
Cluster name: ace-workstation-cluster
Region: us-central1
```

5. Select the network and subnet.
6. Configure private or public gateway settings.
7. Click **Create**.

### Part B: Create a workstation configuration

1. Open **Workstation configurations**.
2. Click **Create**.
3. Select the cluster.
4. Enter:

```text
Configuration name: ace-dev-config
```

5. Choose a machine type, for example:

```text
e2-standard-4
```

6. Configure:
   - Boot disk
   - Persistent disk
   - Idle timeout
   - Running timeout
   - Service account
   - Container image
7. Choose the predefined Code OSS editor for the basic lab.
8. Add users who can create or use workstations.
9. Click **Create**.

A workstation configuration is the template containing machine, disk, image and developer-environment settings. citeturn340154search0

### Part C: Create the workstation

1. Open **Workstations**.
2. Click **Create**.
3. Select:

```text
Cluster: ace-workstation-cluster
Configuration: ace-dev-config
```

4. Enter:

```text
Name: ace-developer-workstation
```

5. Click **Create**.
6. When ready, click **Launch**.
7. The browser-based IDE opens.
8. Open a terminal.
9. Verify tools:

```bash
gcloud --version
git --version
python3 --version
```

The workstation launches using the editor and container image defined by its workstation configuration. citeturn340154search2

## CLI steps

### Create cluster

```bash
gcloud workstations clusters create "$CLUSTER" \
    --region="$REGION"
```

Describe it:

```bash
gcloud workstations clusters describe "$CLUSTER" \
    --region="$REGION"
```

### Create configuration

```bash
gcloud workstations configs create "$CONFIG" \
    --cluster="$CLUSTER" \
    --region="$REGION" \
    --machine-type="e2-standard-4" \
    --boot-disk-size="50" \
    --idle-timeout="3600s" \
    --running-timeout="28800s" \
    --container-predefined-image="codeoss"
```

The CLI supports additional configuration options such as persistent disks, custom images, service accounts, accelerators, private IP settings, Shielded VM controls and network restrictions. citeturn340154search16

### Create workstation

```bash
gcloud workstations create "$WORKSTATION" \
    --cluster="$CLUSTER" \
    --config="$CONFIG" \
    --region="$REGION"
```

The required CLI relationship is:

```text
Workstation
  belongs to configuration
  configuration belongs to cluster
  cluster belongs to region
```

The current command requires the workstation name together with cluster, configuration and region. citeturn340154search9

### List workstations

```bash
gcloud workstations list \
    --cluster="$CLUSTER" \
    --config="$CONFIG" \
    --region="$REGION"
```

### Start workstation

```bash
gcloud workstations start "$WORKSTATION" \
    --cluster="$CLUSTER" \
    --config="$CONFIG" \
    --region="$REGION"
```

### Stop workstation

```bash
gcloud workstations stop "$WORKSTATION" \
    --cluster="$CLUSTER" \
    --config="$CONFIG" \
    --region="$REGION"
```

### Delete workstation

```bash
gcloud workstations delete "$WORKSTATION" \
    --cluster="$CLUSTER" \
    --config="$CONFIG" \
    --region="$REGION" \
    --quiet
```

### Delete configuration

```bash
gcloud workstations configs delete "$CONFIG" \
    --cluster="$CLUSTER" \
    --region="$REGION" \
    --quiet
```

### Delete cluster

```bash
gcloud workstations clusters delete "$CLUSTER" \
    --region="$REGION" \
    --quiet
```

Delete in this order:

```text
Workstation
    ↓
Configuration
    ↓
Cluster
```

---

# 12. Developer environments on Google Cloud

A developer environment is the combination of tools, compute, identity and network access used to build and test software.

Google Cloud provides several possible developer environments.

## 12.1 Cloud Shell

Best for:

- Quick administrative tasks
- `gcloud` commands
- Terraform experiments
- Short-lived scripting
- Browser-based access

Limitations:

- Not designed as a large permanent development workstation
- Limited resources
- Ephemeral runtime characteristics
- Unsuitable for heavy model training

## 12.2 Cloud Workstations

Best for:

- Standardized enterprise software development
- Private repository and VPC access
- Secure remote IDEs
- Centralized developer environment management

## 12.3 Agent Platform Workbench

Best for:

- Data science
- ML development
- Jupyter notebooks
- Model experimentation
- Agent prototyping

## 12.4 BigQuery notebooks

Best for:

- BigQuery-centered analytics
- SQL and Python analysis
- Data storytelling
- BigQuery DataFrames
- Analyst and data-science collaboration

## 12.5 Compute Engine development VM

Best for:

- Full operating-system control
- Custom software
- Unsupported development tools
- Long-running services
- Specialized networking

Disadvantages:

- User manages patching.
- User manages IDE access.
- User manages startup and shutdown.
- Standardization requires images or configuration management.

## 12.6 Local development environment

Best for:

- Offline work
- Small projects
- Low-latency local coding
- Personal experimentation

Challenges:

- Configuration drift
- Security risks
- Difficult onboarding
- Different operating systems
- Local credential exposure

## 12.7 Cloud-based IDE decision table

| Requirement | Recommended environment |
|---|---|
| Execute a few `gcloud` commands | Cloud Shell |
| Standardized Java development | Cloud Workstations |
| Jupyter-based ML experimentation | Agent Platform Workbench |
| BigQuery SQL plus Python | BigQuery notebook |
| Full OS control | Compute Engine VM |
| GPU-based model development | GPU VM or GPU-enabled Workbench |
| TPU-based training | Cloud TPU VM |
| Production agent hosting | Agent Runtime |

---

# 13. Security best practices

## 13.1 Service accounts

Use separate service accounts for:

- Notebook development
- Workstation developers
- Production agents
- Training jobs
- Inference services

Avoid using one highly privileged service account everywhere.

## 13.2 Least privilege

An agent that reads BigQuery data should not automatically receive:

- Project Owner
- Organization Administrator
- Billing Administrator
- Network Administrator

Grant only the minimum required roles.

## 13.3 Avoid service-account keys

Prefer:

- Attached service accounts
- Workload Identity Federation
- Application Default Credentials
- User authentication for development

Static service-account keys create long-lived credential risk.

## 13.4 Private networking

Use private IP configurations where appropriate for:

- Workstations
- Workbench
- TPU VMs
- Compute Engine
- Agent connections to internal APIs

Combine with:

- Private Google Access
- Cloud NAT
- VPC Service Controls
- Firewall rules
- Private Service Connect
- IAP where supported

## 13.5 Secret management

Do not hard-code:

```python
API_KEY = "actual-secret-value"
```

Use Secret Manager and retrieve secrets under an authorised service-account identity.

## 13.6 Notebook security

A notebook can accidentally expose:

- Query results
- Tokens
- Customer data
- Credentials
- Model outputs
- Personally identifiable information

Before sharing:

- Clear sensitive output.
- Disable output saving when required.
- Verify notebook IAM.
- Verify underlying dataset IAM.
- Remove hard-coded credentials.
- Review execution history.

## 13.7 Agent security

AI agents introduce additional risks:

- Prompt injection
- Tool misuse
- Data leakage
- Excessive permissions
- Unsafe autonomous actions
- Hallucinated tool parameters
- Unexpected recursive behaviour

Mitigations:

- Validate tool arguments.
- Use allowlisted tools.
- Require approval for destructive actions.
- Apply timeout and retry limits.
- Restrict network access.
- Log all actions.
- Use read-only permissions by default.
- Test malicious prompts.
- Separate model reasoning from action authorisation.

---

# 14. Availability and operational considerations

## GPU and TPU capacity

Specialized accelerators may not be available immediately.

Production strategies include:

- Multiple zones
- Reservations
- Flexible provisioning
- Queued resources
- Spot capacity for fault-tolerant jobs
- Fallback accelerator types
- Checkpointing

## Checkpointing

A checkpoint stores training progress.

```text
Training begins
    ↓
Checkpoint 1
    ↓
Checkpoint 2
    ↓
VM interruption
    ↓
Resume from Checkpoint 2
```

Store checkpoints in durable storage such as Cloud Storage rather than only on local accelerator storage.

## Region alignment

Place related resources in compatible regions.

For example:

```text
BigQuery dataset region
Notebook runtime region
Cloud Storage bucket region
Agent Runtime region
```

Misaligned regions can cause:

- Unsupported operations
- Higher latency
- Data-transfer charges
- Compliance problems
- Deployment failures

## Development versus production

### Development

- Smaller machine
- One GPU
- Interactive notebook
- Broad debugging access
- Short runtime

### Production

- Controlled service account
- Repeatable deployment
- Monitoring
- Autoscaling
- CI/CD
- Restricted IAM
- Budget alerts
- Evaluation and rollback

---

# 15. Real-world architecture scenarios

## Scenario 1: Image-processing startup

Requirement:

- Users upload images.
- The system removes backgrounds.
- Requests are unpredictable.
- The model needs a GPU.

Possible architecture:

```text
Client
  ↓
Cloud Storage upload
  ↓
Pub/Sub or Eventarc
  ↓
GPU inference service
  ↓
Processed image in Cloud Storage
  ↓
Notification to user
```

Choose a GPU because the image model uses CUDA and PyTorch.

## Scenario 2: Large language-model research

Requirement:

- Train a transformer using JAX.
- Dataset is stored in Cloud Storage.
- Workload can be distributed.
- Interruptions can be handled through checkpoints.

Possible architecture:

```text
Cloud Storage dataset
       ↓
TPU VM slice
       ↓
Distributed JAX training
       ↓
Checkpoints in Cloud Storage
       ↓
Model Registry
```

Choose TPU because the model and framework are TPU-compatible.

## Scenario 3: Enterprise support agent

Requirement:

- Search internal documentation.
- Query customer status.
- Create a support ticket.
- Require approval before issuing a refund.

Possible architecture:

```text
Support portal
      ↓
Agent Runtime
      ↓
Gemini model
      ↓
Retrieval tool + customer API + ticket API
      ↓
Human approval
      ↓
Refund API
```

Important controls:

- Dedicated service account
- Read-only customer-data tool
- Human approval for refunds
- Audit logging
- Tool allowlist
- Prompt-injection testing

## Scenario 4: Data analyst workflow

Requirement:

- Query BigQuery.
- Perform Python analysis.
- Produce charts.
- Share analysis with the team.

Recommended service:

```text
BigQuery notebook
```

A separate GPU VM is unnecessary.

## Scenario 5: Secure Java development team

Requirement:

- Every developer needs Java, Maven, Docker-compatible tools and `gcloud`.
- Source code should not be stored on local laptops.
- Developers must reach private GKE and Cloud SQL resources.

Recommended service:

```text
Cloud Workstations
```

The platform team creates a custom workstation image and private workstation configuration.

---

# 16. ACE exam-focused points

Remember these distinctions:

1. **GPU**
   - General accelerator
   - Broad software support
   - CUDA and graphics use cases
   - Attached to compatible Compute Engine VMs or included in accelerator-optimized machine series

2. **TPU**
   - Google-designed ASIC
   - Specialized for tensor-based ML
   - Best for compatible TensorFlow, JAX and supported ML workloads
   - Managed using Cloud TPU resources and TPU VMs

3. **CPU**
   - Best for general applications and smaller AI workloads
   - Often cheaper for low-volume inference

4. **Agent Runtime**
   - Managed hosting and execution environment for AI agents
   - Suitable for remotely invoked production agents

5. **Agent Platform Workbench**
   - Jupyter-based ML and data-science environment

6. **BigQuery notebook**
   - SQL and Python notebook integrated into BigQuery Studio
   - Best for BigQuery-centered analysis

7. **Cloud Workstations**
   - Standardized, managed developer environments
   - Best for enterprise application-development teams

8. **Cloud Shell**
   - Quick browser-based command-line environment
   - Not a substitute for a permanent heavy development machine

9. **GPU quota**
   - Must be available in addition to physical capacity

10. **Accelerator cost**
    - Stop or delete unused resources
    - Store data and checkpoints in durable services

---

# 17. Practice questions

## Question 1

A company has a PyTorch application that uses custom CUDA extensions. Which accelerator should it use?

A. CPU  
B. GPU  
C. TPU  
D. Cloud Workstations  

**Answer: B — GPU**

The application depends on CUDA, which is part of the NVIDIA GPU ecosystem.

---

## Question 2

A team is training a large JAX transformer that has been optimized for Google’s tensor accelerators. Which resource is most appropriate?

A. E2 VM  
B. Cloud Run CPU instance  
C. Cloud TPU  
D. Cloud Shell  

**Answer: C — Cloud TPU**

---

## Question 3

A company wants all developers to receive the same browser-based IDE, Java version, CLI tools and private VPC access. Which service should it choose?

A. BigQuery notebooks  
B. Cloud Workstations  
C. Cloud TPU  
D. Cloud Storage  

**Answer: B — Cloud Workstations**

---

## Question 4

An analyst wants to combine SQL queries, Python transformations and visualizations against BigQuery data. Which service is the best fit?

A. Cloud Workstations  
B. BigQuery notebooks  
C. Cloud VPN  
D. Compute Engine sole-tenant nodes  

**Answer: B — BigQuery notebooks**

---

## Question 5

A data scientist requires a managed JupyterLab environment for model experimentation and access to Google Cloud ML services. Which service is most appropriate?

A. Agent Platform Workbench  
B. Cloud DNS  
C. Cloud NAT  
D. Managed Instance Group  

**Answer: A — Agent Platform Workbench**

---

## Question 6

A production AI agent needs permission to query one BigQuery dataset. Which is the best security practice?

A. Assign Project Owner to the agent  
B. Download an administrator service-account key  
C. Use a dedicated service account with least-privilege dataset access  
D. Make the BigQuery dataset public  

**Answer: C**

---

## Question 7

A training job uses Spot accelerators and can be interrupted. What should the engineer implement?

A. Store all state only on local disk  
B. Save periodic checkpoints to durable storage  
C. Disable logging  
D. Use a larger public IP address  

**Answer: B**

---

# 18. Final combined mini-lab

## Objective

Build a complete development workflow:

1. Create a BigQuery notebook.
2. Explore a public dataset.
3. Create a managed developer workstation.
4. Create a GPU VM.
5. Verify the GPU.
6. Create a TPU VM.
7. Verify TPU devices.
8. Prototype an agent.
9. Deploy it to Agent Runtime.
10. Clean up all resources.

## Suggested workflow

```text
BigQuery Notebook
   ↓
Explore and prepare data
   ↓
Workbench or Cloud Workstation
   ↓
Write model or agent code
   ↓
GPU or TPU development
   ↓
Save artifacts to Cloud Storage
   ↓
Deploy agent to Agent Runtime
   ↓
Monitor logs and evaluate
```

## Cleanup checklist

Delete or stop:

- GPU VM
- TPU VM
- Workbench instance
- Notebook runtime
- Cloud Workstation
- Workstation configuration
- Workstation cluster
- Agent deployment
- Temporary Cloud Storage objects
- Unused disks
- Reserved IP addresses

Specialized compute resources can be expensive when left running, so cleanup should always be part of the lab rather than an optional afterthought.
