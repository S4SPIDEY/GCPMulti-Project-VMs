#!/bin/bash

# === USER OPTION PROMPT ===
echo -e "\nChoose an option:\n1. Start from scratch (Create project + VM)\n2. Only deploy VMs in existing project"
read -rp "Enter option [1 or 2]: " MODE

# === CONFIG ===
DEFAULT_ZONE="us-central1-a"
DEFAULT_IMAGE="projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2410-oracular-amd64-v20250709"
DEFAULT_MACHINE_TYPE="c2d-highmem-4"
MAX_PROJECTS=3
MAX_VMS=2

# === AUTH CHECK ===
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "."; then
  echo "Please run 'gcloud auth login' first."
  exit 1
fi

# === BILLING CHECK ===
BILLING_ACCOUNT_ID=$(gcloud beta billing accounts list --format="value(ACCOUNT_ID)" | head -n1)
if [[ -z "$BILLING_ACCOUNT_ID" ]]; then
  echo "❌ No billing account found."
  exit 1
fi

declare -a PROJECT_IDS

echo
if [[ "$MODE" == "1" ]]; then
  read -rp "How many projects to create? (max $MAX_PROJECTS): " PNUM
  ((PNUM > MAX_PROJECTS)) && PNUM=$MAX_PROJECTS
  
  for ((p=1; p<=PNUM; p++)); do
    PNAME="project$p"
    PID="${PNAME}-$(date +%s | tail -c 5)"
    gcloud projects create "$PID" --name="$PNAME"
    gcloud beta billing projects link "$PID" --billing-account="$BILLING_ACCOUNT_ID"
    gcloud services enable compute.googleapis.com --project="$PID"
    echo "✅ Created: $PID"
    PROJECT_IDS+=("$PID")
  done
else
  read -rp "Enter existing project ID: " PID
  gcloud services enable compute.googleapis.com --project="$PID"
  PROJECT_IDS=("$PID")
fi

read -rp "How many VMs per project? (max $MAX_VMS): " VNUM
((VNUM > MAX_VMS)) && VNUM=$MAX_VMS

declare -a VM_SUMMARY

for PROJ in "${PROJECT_IDS[@]}"; do
  echo -e "\n🔐 Enter SSH keys for $VNUM VM(s) in $PROJ (format: ssh-rsa AAAA... user)"
  for ((v=1; v<=VNUM; v++)); do
    read -rp "VM $v SSH key: " SSH_LINE
    SSH_USER=$(echo "$SSH_LINE" | awk '{print $NF}')
    SSH_KEY=$(echo "$SSH_LINE" | sed "s/ $SSH_USER\$//")
    VM_NAME="${SSH_USER}vm"

    gcloud compute instances create "$VM_NAME" \
      --project="$PROJ" \
      --zone="$DEFAULT_ZONE" \
      --machine-type="$DEFAULT_MACHINE_TYPE" \
      --metadata="ssh-keys=$SSH_USER:$SSH_KEY" \
      --create-disk=auto-delete=yes,boot=yes,image="$DEFAULT_IMAGE",size=70,type=pd-balanced \
      --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
      --no-service-account --no-scopes \
      --tags=http-server,https-server \
      --no-shielded-secure-boot --shielded-vtpm --no-shielded-integrity-monitoring \
      --provisioning-model=STANDARD --reservation-affinity=any

    IP=$(gcloud compute instances describe "$VM_NAME" --project="$PROJ" --zone="$DEFAULT_ZONE" \
      --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
    VM_SUMMARY+=("$PROJ | $VM_NAME | $IP | $SSH_USER")
  done

done

echo -e "\n✅ All operations completed."
echo -e "\n🧾 Project + VM Summary:"
printf "Project | VM Name | External IP | Username\n"
printf "%s\n" "${VM_SUMMARY[@]}"
