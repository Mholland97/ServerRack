#!/usr/bin/env python3
"""Test script to verify ServerRack installation."""

import sys
import subprocess
from pathlib import Path

def test_python_version():
    """Test Python version."""
    print("Testing Python version...", end=" ")
    version = sys.version_info
    if version.major >= 3 and version.minor >= 8:
        print(f"OK (Python {version.major}.{version.minor})")
        return True
    else:
        print(f"FAILED (Python {version.major}.{version.minor} < 3.8)")
        return False

def test_imports():
    """Test required Python packages."""
    packages = [
        ("customtkinter", "CustomTkinter"),
        ("yaml", "PyYAML"),
        ("paramiko", "Paramiko"),
        ("psutil", "psutil"),
        ("requests", "Requests"),
    ]

    all_ok = True
    for module, name in packages:
        print(f"Testing {name}...", end=" ")
        try:
            __import__(module)
            print("OK")
        except ImportError:
            print("FAILED")
            all_ok = False

    return all_ok

def test_ollama():
    """Test Ollama installation."""
    print("Testing Ollama installation...", end=" ")
    try:
        result = subprocess.run(
            ["ollama", "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            print(f"OK ({result.stdout.strip()})")
            return True
        else:
            print("FAILED (command failed)")
            return False
    except FileNotFoundError:
        print("FAILED (not installed)")
        return False
    except subprocess.TimeoutExpired:
        print("FAILED (timeout)")
        return False

def test_ollama_service():
    """Test if Ollama service is running."""
    print("Testing Ollama service...", end=" ")
    try:
        result = subprocess.run(
            ["systemctl", "is-active", "ollama"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.stdout.strip() == "active":
            print("OK (running)")
            return True
        else:
            print(f"WARNING ({result.stdout.strip()})")
            print("  Run: sudo systemctl start ollama")
            return False
    except Exception:
        print("FAILED (cannot check)")
        return False

def test_config_file():
    """Test configuration file."""
    print("Testing config.yaml...", end=" ")
    config_path = Path("config.yaml")

    if not config_path.exists():
        print("FAILED (not found)")
        return False

    try:
        import yaml
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)

        if 'nodes' in config and len(config['nodes']) > 0:
            print(f"OK ({len(config['nodes'])} nodes configured)")
            return True
        else:
            print("FAILED (no nodes configured)")
            return False

    except Exception as e:
        print(f"FAILED ({str(e)})")
        return False

def test_ssh_keys():
    """Test SSH key setup."""
    print("Testing SSH keys...", end=" ")
    ssh_key = Path.home() / ".ssh" / "id_rsa"

    if ssh_key.exists():
        print("OK")
        return True
    else:
        print("WARNING (no SSH key found)")
        print("  Run: ssh-keygen -t rsa -b 4096")
        return False

def test_temperature():
    """Test temperature monitoring."""
    print("Testing temperature monitoring...", end=" ")
    try:
        result = subprocess.run(
            ["vcgencmd", "measure_temp"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            temp = result.stdout.strip()
            print(f"OK ({temp})")
            return True
        else:
            print("FAILED")
            return False
    except FileNotFoundError:
        print("WARNING (vcgencmd not available)")
        return False
    except Exception as e:
        print(f"FAILED ({str(e)})")
        return False

def main():
    """Run all tests."""
    print("=" * 50)
    print("ServerRack Installation Test")
    print("=" * 50)
    print()

    tests = [
        ("Python Version", test_python_version),
        ("Python Packages", test_imports),
        ("Ollama", test_ollama),
        ("Ollama Service", test_ollama_service),
        ("Configuration", test_config_file),
        ("SSH Keys", test_ssh_keys),
        ("Temperature Monitoring", test_temperature),
    ]

    results = []
    for name, test_func in tests:
        try:
            result = test_func()
            results.append((name, result))
        except Exception as e:
            print(f"ERROR: {e}")
            results.append((name, False))
        print()

    print("=" * 50)
    print("Summary")
    print("=" * 50)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "PASS" if result else "FAIL"
        print(f"{name}: {status}")

    print()
    print(f"Passed: {passed}/{total}")

    if passed == total:
        print()
        print("All tests passed! You can now run:")
        print("  ./run.sh")
    else:
        print()
        print("Some tests failed. Please check the output above.")
        print("Refer to README.md or QUICKSTART.md for help.")

    return 0 if passed == total else 1


if __name__ == "__main__":
    sys.exit(main())
