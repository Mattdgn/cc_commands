# Save CC Commands

## Setup

```bash
git clone https://github.com/Mattdgn/cc_commands.git ~/XXX
cp ~/XXX/*.md ~/.claude/commands/
```

## Usage

```bash
claude /security-audit    # Full security audit → generates SECURITY_AUDIT.md
claude /optimize-perf     # Full perf audit → generates PERFORMANCE_AUDIT.md
claude /qa-report-and-ghac         # QA audit + writes tests + sets up CI/CD → QA_REPORT.md
```
