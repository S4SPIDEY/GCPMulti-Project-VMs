# 🚀 GCP Multi-Project VM Auto-Deployment Script

This script helps you automatically set up **GCP projects** and **Deploy VMs** with custom SSH keys, all from a single shell script — perfect for quick lab setup, demos, or testing environments.

---

## 📦 Features

- Create up to **3 GCP projects** in one go.
- Deploy up to **2 Ubuntu VMs per project**.
- Automatically links billing and enables the Compute API.
- Supports **custom SSH keys** per VM.
- Names VMs using SSH username (e.g., `spideyvm`).
- Summarizes all created resources at the end.

---

## 🔧 Requirements

- ✅ GCP account with billing enabled.
- ✅ `gcloud` CLI installed and configured.
- ✅ `gcloud auth login` completed before running.

---

## 🛠️ Usage

```bash
curl -O https://raw.githubusercontent.com/S4SPIDEY/GCPMulti-Project-VMs/refs/heads/main/deploy.sh && chmod +x deploy.sh && ./deploy.sh
```

You'll be prompted to choose:

```
Choose an option:
1. Start from scratch (Create project + VM)
2. Only deploy VMs in existing project
```

### 👉 Option 1: Start from Scratch

- Script creates GCP projects (max 3).
- Asks how many VMs per project (max 2).
- For each VM, paste an SSH public key in format:
  ```
  ssh-rsa AAAAB3...xyz yourusername
  ```

### 👉 Option 2: Only VM Deployment

- Use an existing project ID.
- Script ensures Compute API and billing are enabled.
- Same SSH key input & VM naming as above.

---

## 💻 VM Config

- **Zone:** `us-central1-a`
- **Machine Type:** `c2d-standard-4`
- **Image:** Ubuntu 24.10 Minimal
- **Disk:** 60GB Balanced
- **Network Tags:** `http-server`, `https-server`

---

## 📋 Output Summary

At the end, you’ll get a summary like:

```
✅ All operations completed.

🧾 Project + VM Summary:
Project       | VM Name    | External IP     | Username
------------- | ---------- | --------------- | --------
project1-xyz  | spideyvm   | 34.123.45.67    | spidey
project2-abc  | devvm      | 35.234.56.78    | dev
```

---

## 📎 Notes

- VM names are auto-generated from SSH usernames.
- Script skips service account and extra scopes for tighter control.
- Use responsibly — costs may apply for created resources!

---

## 🧹 Cleanup

To stop all VMs across all projects and save cost, you can use:

```bash
gcloud projects list --format="value(projectId)" | while read -r project; do
  gcloud compute instances list --project="$project" --format="value(name,zone)" | while read -r name zone; do
    gcloud compute instances stop "$name" --zone="$zone" --project="$project"
  done
done
```

---

## 📬 Feedback / Issues

Feel free to open an issue or pull request if you have suggestions or improvements!

---
