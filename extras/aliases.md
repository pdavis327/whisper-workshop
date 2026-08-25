# Optional shell aliases

Add to `~/.bashrc` or `~/.zshrc` if you want shorter commands during the workshop.

```bash
alias wis='oc get inferenceservice -n whisper-workshop'
alias wid='oc describe inferenceservice whisper-large-v3 -n whisper-workshop'
alias wpods='oc get pods -n whisper-workshop -l serving.kserve.io/inferenceservice=whisper-large-v3'
alias wlogs='oc logs -n whisper-workshop -l serving.kserve.io/inferenceservice=whisper-large-v3 -c kserve-container --tail=100'
```

Reload: `source ~/.bashrc`.
