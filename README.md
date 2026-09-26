# SecScan Framework 🔎

**SecScan** is a Bash-based network and service enumeration framework developed by **Youssef Tarek**.

## Features

- ANSI-colored terminal interface
- Target reachability checking
- Nmap fast port and service enumeration
- Single-target scanning
- Multiple-target file scanning
- Modular service-specific execution
- HTML assessment report generation
- `--help` and `--version` options
- Organized report output

## Project Structure

```text
secscan/
├── secscan.sh
├── modules/
│   ├── ssh.sh
│   ├── http.sh
│   └── smb.sh
├── reports/
│   ├── scan.txt
│   ├── findings.txt
│   └── summary.txt
├── README.md
└── .gitignore
```

## Requirements

Designed for Kali Linux or another Linux distribution with:

- Bash
- Nmap
- ping

Optional modules may require additional tools.

## Usage

Make the scanner executable:

```bash
chmod +x secscan.sh
```

Scan one authorized target:

```bash
./secscan.sh 192.168.1.100
```

Scan multiple targets from a file:

```bash
./secscan.sh targets.txt
```

Display help:

```bash
./secscan.sh --help
```

Display version:

```bash
./secscan.sh --version
```

## Output

Scan results are stored in the `reports/` directory. The scanner also generates an HTML report containing the Nmap output.

## Modular Architecture

Service-specific scripts are stored under `modules/`. The main scanner automatically executes executable module scripts found in that directory, allowing the framework to be extended without changing the core scanner.

## Authorization

This project is intended for educational purposes and authorized security assessments only. Scan systems and networks only when you have explicit permission.

## Author

**Youssef Tarek**  
Cybersecurity Student | Penetration Testing & Security Automation
