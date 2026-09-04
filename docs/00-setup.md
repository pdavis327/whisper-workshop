# 0. Prerequisites and setup

<p align="center">
<a href="/README.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/01-overview.md">Next</a>
</p>

> Run commands from the root of this repository unless a step says otherwise. Some steps write under `scratch/`, which Git ignores.

## Official reference

Architecture and procedures: [Deploying models](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/3.5/html-single/deploying_models/index) (OpenShift AI Self-Managed 3.5, single-model / KServe RawDeployment).

## Who does what

| Task | Facilitator | Participant |
|------|-------------|-------------|
| Enable KServe on the DataScienceCluster | yes | — |
| Confirm GPU Operator + NFD | yes | — |
| `bash scripts/setup.sh -s 0` (banner / Web Terminal) | optional | — |
| `bash scripts/setup.sh -s 1` (project `whisper-workshop`) | yes | — |
| `bash scripts/sanity_check.sh` | yes | — |
| `oc login`, clone repo | — | yes |
| Dashboard deploy, YAML, workbench notebook | — | yes |

Participants do **not** apply cluster-scoped resources (HardwareProfile in `redhat-ods-applications`, Web Terminal). Use the project the facilitator created.

## Facilitator checklist

See [Prerequisites](/docs/prerequisites.md).

- [ ] OpenShift AI Self-Managed **3.5** with KServe (single-model serving) enabled
- [ ] At least **one NVIDIA GPU with 16 GB+ VRAM** (L4, A10, L40S, A100, or similar). `whisper-large-v3` is heavier than turbo.
- [ ] A registry (Quay.io or internal) the cluster can pull OCI modelcars from
- [ ] `bash scripts/setup.sh -s 1` so `whisper-workshop` appears under AI projects
- [ ] `bash scripts/sanity_check.sh` is clean (or GPU warn is understood)
- [ ] [Value-prop slides](/docs/slides/value-prop.html) open in a **local** browser for the Topic 1 briefing (GitHub shows HTML source, not the slides)

## Participant checklist (~10 min)

- [ ] Access to the OpenShift cluster and OpenShift AI dashboard
- [ ] `oc` CLI (or the Web Terminal)
- [ ] Comfort with YAML, HTTP APIs, and multipart file uploads
- [ ] Clone this repo (below)

## Clone and prepare

- [ ] Open a `bash` terminal.

- [ ] Clone this repository and enter the directory.

```sh
git clone https://github.com/pdavis327/whisper-workshop.git

cd whisper-workshop
```

- [ ] Log in to the cluster.

```sh
oc login <openshift_api_url> -u <username> -p <password>
```

- [ ] Use the workshop project (do not create a second one if the facilitator already ran setup step 1):

```sh
oc project whisper-workshop
```

If the project is missing and you have permission:

```sh
oc new-project whisper-workshop
oc label namespace whisper-workshop opendatahub.io/dashboard=true --overwrite
```

For the remaining labs you may use your local shell, the Web Terminal, or a workbench terminal (Topic 6).

### Cloning in the OpenShift Web Terminal

Same as on a laptop: `git clone …` and `cd whisper-workshop` give you `docs/`, `configs/samples/`, and `extras/`, as long as the cluster allows outbound HTTPS to GitHub. If clone fails, use a fork on an allowed host, a zip uploaded to a workbench, or `oc cp` from your laptop.

### How to read the modules (Markdown) in a terminal

Labs are plain `.md` files under `docs/`. The Web Terminal does not render GitHub navigation; use any of these:

| Approach | How |
|----------|-----|
| Pager | `less docs/01-overview.md` (quit with `q`) |
| Print | `cat docs/00-setup.md` |
| Editor | `vi docs/03-building-the-modelcar.md` |
| Browser | Open the repo on GitHub and read online while running commands in the terminal |
| Workbench | Clone into JupyterLab and open the `.md` file in the IDE |

Links like `/docs/…` are for GitHub. In the shell, paths are relative to the repo root, for example `docs/01-overview.md`.

## Verify KServe and GPUs

- [ ] Confirm APIs exist: `oc api-resources | grep -E 'inferenceservice|servingruntime' || true`
- [ ] Optional: `oc get servingruntime -A` — templates may live in `redhat-ods-applications` until you create a project-scoped runtime.
- [ ] GPU capacity: `oc get nodes -o json | jq -r '.items[] | select(.status.allocatable["nvidia.com/gpu"] != null) | .metadata.name'`
- [ ] Open OpenShift AI from the application menu at the top right of the OpenShift console.

<p align="center">
<a href="/README.md">Prev</a>
&nbsp;&nbsp;&nbsp;
<a href="/docs/01-overview.md">Next</a>
</p>
