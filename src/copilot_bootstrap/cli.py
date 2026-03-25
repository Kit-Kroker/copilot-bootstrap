import os
import subprocess
import sys
from pathlib import Path

PACKAGE_DIR = Path(__file__).parent

COMMANDS = {
    "init": "init.sh",
    "scan": "scan.sh",
    "sync": "sync.sh",
    "next": "next.sh",
    "step": "step.sh",
    "redo": "redo.sh",
    "ask": "ask.sh",
    "validate": "validate-state.sh",
    "interview": "interview.sh",
    "build-context": "build-context.sh",
    "discover": "discover.sh",
    "discovery-status": "discovery-status.sh",
    "generate": "generate.sh",
    "generate-status": "generate-status.sh",
}


def main() -> None:
    args = sys.argv[1:]

    if not args or args[0] in ("-h", "--help"):
        print("Usage: copilot-bootstrap <command> [args]")
        print()
        print("Commands:")
        for name in COMMANDS:
            print(f"  {name}")
        print()
        print("Run 'copilot-bootstrap <command> --help' for command-specific help.")
        sys.exit(0 if args else 1)

    cmd, *rest = args

    if cmd not in COMMANDS:
        print(f"Unknown command: {cmd}", file=sys.stderr)
        print(f"Available commands: {', '.join(COMMANDS)}", file=sys.stderr)
        sys.exit(1)

    script = PACKAGE_DIR / "scripts" / COMMANDS[cmd]
    env = os.environ.copy()
    env["COPILOT_BOOTSTRAP_HOME"] = str(PACKAGE_DIR)

    result = subprocess.run(["sh", str(script), *rest], env=env)
    sys.exit(result.returncode)
